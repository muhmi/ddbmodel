Code.require_file "../test_helper.exs", __ENV__.file

defmodule DDBModelTest do
  use ExUnit.Case

  setup do
    :ssl.start()
    :erlcloud.start()
    :ok
  end

  test "default table name" do
    assert TestDefaultTableName.table_name == "test_TestDefaultTableName"
  end

  test "custom table name" do
    assert TestCustomTableName.table_name == "test_Custom"
  end

  test "default key" do
    assert TestDefaultKey.key == :hash
  end

  test "custom key" do
    assert TestCustomKey.key == :a_key
  end

  test "range key" do
    assert TestRangeKey.key == {:a_hash_key, :a_range_key}
  end

  test "record id" do
    x = TestRecordID.new hash: "abc", range: "def"
    assert x.id == {"abc", "def"}
  end

  test "def column" do
    x = TestDefColumn.new uuid: "7342C9D3-ED28-4E60-A9BD-CDE60EB69BEC"
    assert x.uuid == "7342C9D3-ED28-4E60-A9BD-CDE60EB69BEC"
    x = x.uuid("D0F126F4-90C1-4855-B73F-99E8E9A8D151")
    assert x.uuid == "D0F126F4-90C1-4855-B73F-99E8E9A8D151"
  end

  test "column default" do
    x = TestDefColumnDefault.new
    assert x.first_name == "Markus"
    x = x.first_name "Niko"
    assert x.first_name == "Niko"
  end

  test "mass assignment" do
    x = TestMassAssignment.new
    x = x.set first_name: "Dale", last_name: "Cooper", password: "black_lodge123"
    assert x.first_name == "Dale" and x.last_name == "Cooper" and x.password == "black_lodge123"
    x = x.set [first_name: "_", last_name: "_", password: "pwned"], [:first_name, :last_name]
    assert x.first_name == "_" and x.last_name == "_" and x.password == "black_lodge123"
  end

  test "validate by function" do
    x = TestValidate.new first_name: "Joe", last_name: "Schmoe"
    assert x.validate != :ok
    x = x.set first_name: "John", last_name: "Doe"
    assert x.validate == :ok
  end

  test "validate not null" do
    x = TestValidate.new
    assert x.validate == :ok
    x = x.set status: nil
    assert x.validate != :ok
  end

  test "validate in_list" do
    x = TestValidate.new
    assert x.validate == :ok
    x = x.set membership: :none
    assert x.validate != :ok
    x = x.set membership: :paid
    assert x.validate == :ok
    x = x.set membership: :chiken
    assert x.validate != :ok

    x = x.set membership: "paid"
    assert x.validate != :ok
  end

  test "binary data" do
    bin_data = :erlang.term_to_binary(self)
    item = TestBinaryData.new data: bin_data, data_id: "lol"
    {res, item} = item.insert!
    assert res == :ok
    {res, item} = TestBinaryData.find(item.data_id)
    assert item.data == bin_data
    pid = :erlang.binary_to_term(item.data)
    assert res == :ok
    assert pid == self
    {:ok, _item} = item.delete!
  end

  test "custom validation" do
    x = TestCustomValidate.new
    assert x.validate != :ok
  end

  test "before save uuid type" do
    x = TestModelHashKey.new
    x = x.before_save
    assert x.uuid != nil
  end

  test "automatic timestamp" do
    x1 = TestModelHashKey.new
    x1 = x1.before_save
    assert x1.created_at != nil and x1.updated_at != nil
    :timer.sleep(1100)
    x2 = x1.before_save
    assert x1.updated_at != x2.updated_at and x1.created_at == x2.created_at
  end

  test "put!" do
    x = TestModelHashKey.new
    {status, _} = x.put!
    assert status == :ok
  end

  test "insert!" do
    {status, x} = TestModelHashKey.new.insert!

    assert status == :ok
    {status, _} = x.insert!

    assert status != :ok
  end

  test "update!" do
    {status, _} = TestModelHashKey.new.update!

    assert status != :ok
    {_, x} = TestModelHashKey.new.insert!
    {status, _} = x.update!

    assert status == :ok
  end

  test "delete!" do
    {:ok, x} = TestModelHashKey.new.insert!
    {status, _} = x.delete!
    assert status == :ok
    {status, _} = x.delete!
    assert status != :ok
  end

  test "find" do
    {:ok, x1} = TestModelHashKey.new.insert!

    {result, x2} = TestModelHashKey.find(x1.uuid)

    assert result == :ok and x1 == x2
  end

end
