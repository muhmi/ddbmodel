defmodule DDBModel.DynamoDB do

    def create_table(table_name, key_spec, key, write_units, read_units) do
      :erlcloud_ddb2.create_table(table_name, key_spec, key, write_units, read_units)
    end

    def delete_table(table_name) do
      :erlcloud_ddb2.delete_table(table_name)
    end

    def put_item(table_name, item) do
      :erlcloud_ddb2.put_item(table_name, item)
    end

    def batch_write_item(items) do
      :erlcloud_ddb2.batch_write_item(items)
    end

    def put_item(table_name, item, expect_not_exists) do
      :erlcloud_ddb2.put_item(table_name, item, expect_not_exists)
    end

    def delete_item(table_name, key_spec, expect_exists) do
      :erlcloud_ddb2.delete_item(table_name, key_spec, expect_exists)
    end

    def batch_get_item(batch) do
      :erlcloud_ddb2.batch_get_item(batch)
    end

    def get_item(table_name, key_spec) do
      :erlcloud_ddb2.get_item(table_name, key_spec)
    end

    def q(table_name, hash_key, spec) do
      :erlcloud_ddb2.q(table_name, hash_key, spec)
    end

    def scan(table_name, spec) do
      :erlcloud_ddb2.scan(table_name, spec)
    end

end