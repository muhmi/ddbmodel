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

      @doc "update record when it exists, otherwise insert"
      def put!(record={__MODULE__,_dict}) do

        record = before_save record

        case validate(record) do
          :ok ->
            case DDBModel.Database.put_item(table_name, {key, id(record)}, to_dynamo(record)) do
              {:ok, result}   -> {:ok, record}
              error           -> error
            end
          error -> error
        end
      end

      # --------------------------------------------
      # Insert
      # --------------------------------------------

      @doc "insert record, error when it exists"
      def insert!(record={__MODULE__,_dict}) do

        record = before_save record

        case validate(record) do
          :ok ->
          case DDBModel.Database.put_item(table_name, {key, id(record)}, to_dynamo(record), expect_not_exists) do
            {:ok, _}   -> {:ok, record}
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

      @doc "update record, error when it doesn't exist"
      def update!(record={__MODULE__,_dict}) do

        record = before_save record

        case validate(record) do
          :ok ->
          case DDBModel.Database.put_item(table_name, {key, id(record)}, to_dynamo(record), expect_exists(record)) do
            {:ok, result}   -> {:ok, record}
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

      @doc "delete record"
      def delete!(record={__MODULE__,_dict}), do: delete!(id record)

      def delete!(record_id) do
        case DDBModel.Database.delete_item(table_name, {to_string(key), record_id}, expect_exists(key,record_id)) do
          {:ok, _result}   -> {:ok, record_id}
          error           ->  error
        end
      end

      # --------------------------------------------
      # Find by ID
      # --------------------------------------------

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
