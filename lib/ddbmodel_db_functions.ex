defmodule DDBModel.DB.Functions do

  def create_table(table_name, key, write_units, read_units) do
    case DDBModel.Database.create_table(table_name, {key, :s}, key, write_units, read_units) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  def delete_table(table_name) do
    case DDBModel.Database.delete_table(table_name) do
      {:ok, _result}   -> :ok
      error           -> error
    end
  end

  def expect_not_exists(key) do
    case key do
      {hash, range} -> [expected: [{Atom.to_string(hash), false}, {Atom.to_string(range), false}]]
      hash          -> [expected: {Atom.to_string(hash), false}]
    end
  end

  def expect_exists(k, id) do
    case {k, id} do
      {{hash, range}, {hash_key, range_key}}  -> [expected: [{Atom.to_string(hash), hash_key}, {Atom.to_string(range), range_key }]]
      {hash, hash_key} when is_atom(hash)     -> [expected: {Atom.to_string(hash), hash_key }]
    end
  end

end