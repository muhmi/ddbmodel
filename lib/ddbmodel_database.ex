defmodule DDBModel.Database do

    def create_table(table_name, key_spec, key, write_units, read_units) do
        database_backend.create_table(table_name, key_spec, key, write_units, read_units)
    end
    
    def delete_table(table_name) do
        database_backend.delete_table(table_name)
    end
    
    def put_item(table_name, key_spec, item) do
        database_backend.put_item(table_name, key_spec, item)
    end
    
    def put_item(table_name, key_spec, item, expect_not_exists) do
        database_backend.put_item(table_name, key_spec, item, expect_not_exists)
    end
    
    def delete_item(table_name, key_spec, expect_exists) do
        database_backend.delete_item(table_name, key_spec, expect_exists)
    end

    def get_item(table_name, key_spec) do
        database_backend.get_item(table_name, key_spec)
    end

    def database_backend do
        Application.get_env(:ddbmodel, :backend) || DDBModel.Database.AWS
    end

    defmodule AWS do 

      def create_table(table_name, key_spec, key, write_units, read_units) do
          :erlcloud_ddb2.create_table(table_name, key_spec, key, write_units, read_units)
      end

      def delete_table(table_name) do
          :erlcloud_ddb2.delete_table(table_name)
      end

      def put_item(table_name, _key, item) do
          :erlcloud_ddb2.put_item(table_name, item)
      end

      def put_item(table_name, _key, item, expect_not_exists) do
          :erlcloud_ddb2.put_item(table_name, item, expect_not_exists)
      end

      def delete_item(table_name, key_spec, expect_exists) do
          :erlcloud_ddb2.delete_item(table_name, key_spec, expect_exists)
      end

      def get_item(table_name, key_spec) do
          :erlcloud_ddb2.get_item(table_name, key_spec)
      end

  end

  defmodule FS do 

    def create_table(_table_name, _key_spec, _key, _write_units, _read_units), do: {:ok, nil}
    def delete_table(_table_name), do: {:ok, nil}

    def put_item(table_name, key_spec, item) do
       put_or_replace(table_name, key_spec, item)
    end

    def put_item(table_name, key_spec, item, [expected: {_id, false}] = _expect_not_to_exist) do
        put_new(table_name, key_spec, item)
    end

    def put_item(table_name, {key, val}, item, [expected: _id] = expect) when is_atom(key), do: put_item(table_name, {Atom.to_string(key), val}, item, expect)
    def put_item(table_name, key_spec, item, [expected: _id] = _expect_to_exist) do
        case get_item(table_name, key_spec) do
          {:ok, []} -> {:error, :does_not_exist}
          {:ok, _} -> put_or_replace(table_name, key_spec, item) 
        end
    end

    def put_new(table_name, {key, val}, item) when is_atom(key), do: put_new(table_name, {Atom.to_string(key), val}, item)
    def put_new(table_name, key_spec, item) do
      case get_item(table_name, key_spec) do
        {:ok, []} -> put_or_replace(table_name, key_spec, item)
        {:ok, _} -> {:error, :already_exists}
      end
    end

    def put_or_replace(table_name, {id_key, id_value}, item) do
      items = read_table(table_name) |>  Enum.filter(&match?(&1, id_key, id_value))
      item = item |> Enum.map(fn({k, v}) -> {k, encode_binaries(v)} end)
      items = [item | items]
      write_table(table_name, items)
      {:ok, item}
    end

    def delete_item(table_name, {id_key, id_value}, _expect_exists) do
        items = read_table(table_name)
        item = Enum.find(items, &match?(&1, id_key, id_value))
        items = items |> Enum.filter(&no_match?(&1, id_key, id_value))
        write_table(table_name, items)
        if item != nil do
          {:ok, nil}
        else
          {:error, :does_not_exist}
        end
    end

    def get_item(table_name, {id_key, id_value}) do
        items = read_table(table_name)
        item = Enum.find(items, &match?(&1, id_key, id_value))
        if item != nil do
            item = item |> Enum.map(fn({k, v}) -> {k, decode_binaries(v)} end)
            {:ok, item}
        else
            {:ok, []}
        end
    end

    def read_table(table_name) do
        table_path = table_file(table_name)
        if File.exists?(table_path) do
            table_path |> File.read! |> :jsx.decode
        else
            []
        end
    end

    def decode_binaries("_bin_hack_" <> v = _msg), do: Base.decode64!(v)
    def decode_binaries(v), do: v

    def encode_binaries({:b, v}), do: "_bin_hack_" <> Base.encode64(v)
    def encode_binaries(v), do: v

    def write_table(table_name, items) do
        File.write! table_file(table_name), :jsx.encode(items, [:indent])
    end

    def table_file(table_name) do
        table_dir = Application.get_env(:ddbmodel, :fs_path) || Application.app_dir(:ddbmodel, "priv")
        "#{table_dir}/#{table_name}"
    end

    def no_match?(item, key, value), do: not match?(item, key, value)

    def match?(item, key, value) do
        item = Enum.find(item, fn({k, v})-> k == key && v == value end)
        item != nil
    end

end


end