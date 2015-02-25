defmodule DDBModel.DB.Functions do

  def create_table(table_name, key, write_units, read_units) do
    case DDBModel.DynamoDB.create_table(table_name, {key, :s}, key, write_units, read_units) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  def delete_table(table_name) do
    case DDBModel.DynamoDB.delete_table(table_name) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

end