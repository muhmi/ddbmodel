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
       put(table_name, key_spec, item, false)
    end

    def put_item(table_name, key_spec, item, _expect_not_exists) do
        put(table_name, key_spec, item, true)
    end

    def put(table_name, {id_key, id_value}, item, should_exist) do
      items = read_table(table_name) |>  Enum.filter(&match?(&1, id_key, id_value))
      IO.puts("put #{inspect id_key}=#{inspect id_value}, should_exist:#{should_exist} table: #{table_name}")
      if should_exist and Enum.find(items, &match?(&1, id_key, id_value)) == nil do
        {:error, item}
      else
        items = [item | items]
        write_table(table_name, items)
        {:ok, nil}
      end
    end

    def delete_item(table_name, {id_key, id_value}, _expect_exists) do
        IO.puts("delete_item #{inspect id_key}=#{inspect id_value} table: #{table_name}")
        items = read_table(table_name)
        items = items |> Enum.filter(&match?(&1, id_key, id_value))
        write_table(table_name, items)
        {:ok, nil}
    end

    def get_item(table_name, {id_key, id_value}) do
        items = read_table(table_name)
        IO.puts("get_item #{inspect id_key}=#{inspect id_value} table: #{table_name}")
        item = Enum.find(items, &match?(&1, id_key, id_value))
        if item != nil do
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

    def write_table(table_name, items) do
        File.write! table_file(table_name), :jsx.encode(items, [:indent])
    end

    def table_file(table_name) do
        Application.get_env(:ddbmodel, :fs_path) || Application.app_dir(:ddbmodel, "priv/#{table_name}")
    end

    def match?(item, key, value) do
        item = Enum.find(item, fn({k, v})-> k == key && v == value end)
        item != nil
    end

end


end