defmodule DDBModel.DB do
  def generate(:model) do

    quote do

      import DDBModel.Transform
      import DDBModel.DB.Functions

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

      def create_table, do: create_table(table_name, key, 1, 1)
      def delete_table, do: delete_table(table_name)
  
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
            case DDBModel.Database.put_item(table_name, to_dynamo(record)) do
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
                case DDBModel.Database.batch_write_item(items) do
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
          case DDBModel.Database.put_item(table_name, to_dynamo(record), expect_not_exists) do
            {:ok, result}   -> {:ok, after_insert(record)}
            error           -> error
          end
          error -> error
        end

      end

      # expect that the record is new
      defp expect_not_exists, do: expect_not_exists(key)

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
          case DDBModel.Database.put_item(table_name,to_dynamo(record), expect_exists(record)) do
            {:ok, result}   -> {:ok, after_update(record)}
            error           -> error
          end
          error -> error
        end

      end

      # expect that the record already exists
      defp expect_exists(record={__MODULE__, _dict}), do: expect_exists(key, id(record))

      

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

        case DDBModel.Database.batch_write_item({table_name, items}) do
          {:ok, result}   ->  Enum.each record_ids, fn(record_id) -> after_delete(record_id) end
                              {:ok, record_ids}
          error           ->  error
        end

      end

      def delete!(record_id) do
        before_delete(record_id)
        case DDBModel.Database.delete_item(table_name, {to_string(key), record_id}, expect_exists(key,record_id)) do
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
        case DDBModel.Database.batch_get_item({table_name, keys}) do
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
        case DDBModel.Database.get_item(table_name, {to_string(key), record_id}) do
          {:ok, []}     -> :not_found
          {:ok, item}   -> {:ok, from_dynamo(parse_item(item))}
        end
      end

    end
  end
end
