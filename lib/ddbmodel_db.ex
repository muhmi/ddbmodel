defmodule DDBModel.DB do
  def generate(:model) do

    quote do

      import DDBModel.Transform

      def to_dynamo(record={__MODULE__,dict}) do
        res = Enum.map model_columns, fn({k,opts}) ->
          {Atom.to_string(k), to_dynamo(opts[:type], dict[k])}
        end
        Enum.filter res, fn ({k,v}) -> v != nil and v != "" end
      end
      
      def from_dynamo(dict) do
        res = Enum.map model_columns, fn({k,opts}) ->
          {k, from_dynamo(opts[:type], dict[k])}
        end
        new(res)
      end
      
      def create_table do
        case DDBModel.DynamoDB.create_table(table_name, {key, :s}, key, 1, 1) do
          {:ok, result}   -> :ok
          error           -> error
        end
      end

      def delete_table do
        case DDBModel.DynamoDB.delete_table(table_name) do
          {:ok, result}   -> :ok
          error           -> error
        end
      end
      # --------------------------------------------
      # Put
      # --------------------------------------------

      def before_put(record={__MODULE__,_dict}), do: record
      def after_put(record={__MODULE__,_dict}), do: record

      defoverridable [before_put: 1, after_put: 1]

      @doc "update record when it exists, otherwise insert"
      def put!(record={__MODULE__,_dict}) do

        record = before_put(before_save record)

        case validate(record) do
          :ok ->
            case DDBModel.DynamoDB.put_item(table_name, to_dynamo(record)) do
              {:ok, result}   -> {:ok, after_put(record)}
              error           -> error
            end
          error -> error
        end
      end


      def put!(records) when is_list records do

        records = Enum.map records, fn(record) -> before_put(before_save record) end
        validations = Enum.map records, fn(record) -> validate record end
        validations = List.flatten(Enum.filter validations, fn(v) -> v != :ok end)

        case validations do
          [] -> items = Enum.map records, fn(record) -> {table_name, [{:put, to_dynamo(record)} ]} end
                case DDBModel.DynamoDB.batch_write_item(items) do
                  {:ok, result}   -> {:ok, Enum.map( records, fn (record) -> after_put(record) end )}
                  error           -> error
                end
            _  -> {:error, Enum.map(validations, fn ({:error, err}) -> err end)}
        end
      end

      # --------------------------------------------
      # Insert
      # --------------------------------------------

      def before_insert(record={__MODULE__,_dict}), do: record
      def after_insert(record={__MODULE__,_dict}), do: record

      defoverridable [before_insert: 1, after_insert: 1]

      @doc "insert record, error when it exists"
      def insert!(record={__MODULE__,_dict}) do

        record = before_insert(before_save record)

        case validate(record) do
          :ok ->
          case DDBModel.DynamoDB.put_item(table_name, to_dynamo(record), expect_not_exists) do
            {:ok, result}   -> {:ok, after_insert(record)}
            error           -> error
          end
          error -> error
        end

      end

      # expect that the record is new
      defp expect_not_exists do
        case key do
          {hash, range} -> [expected: [{Atom.to_string(hash), false}, {Atom.to_string(range), false}]]
          hash          -> [expected: {Atom.to_string(hash), false}]
        end
      end

      # --------------------------------------------
      # Update
      # --------------------------------------------

      def before_update(record={__MODULE__,_dict}), do: record
      def after_update(record={__MODULE__,_dict}), do: record

      defoverridable [before_update: 1, after_update: 1]

      @doc "update record, error when it doesn't exist"
      def update!(record={__MODULE__,_dict}) do

        record = before_update(before_save record)

        case validate(record) do
          :ok ->
          case DDBModel.DynamoDB.put_item(table_name,to_dynamo(record), expect_exists(record)) do
            {:ok, result}   -> {:ok, after_update(record)}
            error           -> error
          end
          error -> error
        end

      end

      # expect that the record already exists
      defp expect_exists(record={__MODULE__, _dict}), do: expect_exists(key,id(record))

      defp expect_exists(k,i) do
        case {k,i} do
          {{hash, range}, {hash_key, range_key}}  -> [expected: [{Atom.to_string(hash), hash_key }, {Atom.to_string(range), range_key }]]
          {hash, hash_key} when is_atom(hash)     -> [expected: {Atom.to_string(hash), hash_key }]
        end
      end

      # --------------------------------------------
      # Delete
      # --------------------------------------------

      def before_delete(record_id), do: record_id
      def after_delete(record_id), do: record_id

      defoverridable [before_delete: 1, after_delete: 1]

      @doc "delete record"
      def delete!(record={__MODULE__,_dict}), do: delete!(id record)

      def delete!(records) when is_list records do
        record_ids = Enum.map records, fn(record) ->
          case record do
            {__MODULE__,_dict}  -> id(record)
            record_id           -> record_id
          end
        end

        Enum.each record_ids, fn(record_id) -> before_delete(record_id) end

        items = Enum.map record_ids, fn(record_id) -> {:delete, {to_string(key), record_id}} end

        case DDBModel.DynamoDB.batch_write_item({table_name, items}) do
          {:ok, result}   ->  Enum.each record_ids, fn(record_id) -> after_delete(record_id) end
                              {:ok, record_ids}
          error           ->  error
        end

      end

      def delete!(record_id) do
        before_delete(record_id)
        case DDBModel.DynamoDB.delete_item(table_name, {to_string(key), record_id}, expect_exists(key,record_id)) do
          {:ok, result}   ->  after_delete(record_id)
                              {:ok, record_id}
          error           ->  error
        end
      end


      # --------------------------------------------
      # Find by ID
      # --------------------------------------------

      # TODO: implement batch find across models

      # find a list of object by their ids
      def find(ids) when is_list(ids) do
        keys = Enum.map ids, fn(id) ->
          {to_string(key), id}
        end
        case DDBModel.DynamoDB.batch_get_item({table_name, keys}) do
          {:ok, items}     -> result = Enum.map(items, fn(item) -> from_dynamo(parse_item(item)) end )
                              result = Enum.sort result, fn(r1, r2) ->
                                (Enum.find_index ids, &(r1.id == &1))
                                  <
                                (Enum.find_index ids, &(r2.id == &1))
                               end
                              {:ok, result }
          error            -> error
        end
      end


      # find one object by id
      def find(record_id) do
        case DDBModel.DynamoDB.get_item(table_name, {to_string(key), record_id}) do
          {:ok, []}     -> :not_found
          {:ok, item}   -> {:ok, from_dynamo(parse_item(item))}
        end
      end

      # --------------------------------------------
      # Query
      # --------------------------------------------

      defp query_q({op, range_key}) when op in [:eq,:le,:lt,:ge,:gt,:begins_with], do: {range_key, op}
      defp query_q({:between, range_key1, range_key2}), do: {{range_key1, range_key2}, :between}
      defp query_q(nil), do: nil

      def query(hash_key, predicate \\ nil, limit \\ nil, offset \\ nil, forward \\ true) do

        spec = [ scan_index_forward: forward,
                 out: :record,
                 range_key_condition: query_q(predicate),
                 exclusive_start_key: offset,
                 limit: limit]

        spec = Enum.filter spec, fn({k,v}) -> v != nil and v != [] end

        case DDBModel.DynamoDB.q(table_name,hash_key,spec) do
          {:ok, {_,_,result,offset,_}} -> {:ok, offset, Enum.map( result, from_dynamo(&(&1)))}
          error                   -> error
        end
      end


      # --------------------------------------------
      # Scan
      # --------------------------------------------

      defp scan_q({k,op,v}) when op in [:in,:eq,:ne,:le,:lt,:ge,:gt,:contains,:not_contains,:begins_with], do: {k, v, op}
      defp scan_q({k, :between, {v1, v2}}), do: {k, {v1, v2}, :between}

      def scan(predicates \\ [], limit \\ nil, offset \\ nil) do

        spec = [ out: :record,
                 scan_filter: Enum.map(predicates, &scan_q(&1)),
                 exclusive_start_key: offset,
                 limit: limit]

        spec = Enum.filter spec, fn({k,v}) -> v != nil and v != [] end

        case DDBModel.DynamoDB.scan(table_name, spec) do
          {:ok, {:ddb2_scan,consumed_capacity,count,items,last_evaluated_key,scanned_count}} ->
            {:ok, count, List.flatten(items)}
          error -> error
        end

      end

    end
  end
end
