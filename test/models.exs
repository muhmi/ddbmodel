
defmodule TestDefaultTableName do
  use DDBModel
end

defmodule TestCustomTableName do
  use DDBModel, table_name: "test_Custom"
end

defmodule TestDefaultKey do
  use DDBModel
end

defmodule TestCustomKey do
  use DDBModel, key: :a_key
end

defmodule TestRecordID do
  use DDBModel, key: {:hash, :range}
  
  defcolumn :hash
  defcolumn :range
end

defmodule TestRangeKey do
  use DDBModel, key: {:a_hash_key, :a_range_key}
end

defmodule TestDefColumn do
  use DDBModel
  
  defcolumn :uuid
end

defmodule TestBinaryData do
  use DDBModel, key: :data_id
  defcolumn :data_id
  defcolumn :data, type: :binary
end

defmodule TestDefColumnDefault do
  use DDBModel
  
  defcolumn :first_name, default: "Markus"
end

defmodule TestMassAssignment do
  use DDBModel
  
  defcolumn :first_name
  defcolumn :last_name
  defcolumn :password
end

defmodule TestValidate do
  use DDBModel
  
  defcolumn :first_name, default: "John"
  defcolumn :last_name, default: "Doe"
  defcolumn :status, default: :A, null: :false
  defcolumn :membership, default: :free, in_list: [:free, :paid]

end

defmodule TestCustomValidate do
  use DDBModel
  
  def validate(record) do
    _ = super(record)
    {:error, [{:error, {:something, "Something's not right" }}]}
  end
end


defmodule TestModelHashKey do
  use DDBModel, key: :uuid
  with_timestamps
  
  defcolumn :uuid, type: :uuid
    
end

defmodule TestModels do
  defp tables do
    [
      TestDefaultTableName,
      TestCustomTableName,
      TestDefaultKey,
      TestCustomKey,
      TestDefColumn,
      TestDefColumnDefault,
      TestMassAssignment,
      TestValidate,
      TestCustomValidate,
      TestModelHashKey,
      TestBinaryData
    ]
  end

  def prepare do
    Enum.map tables, fn (model) -> model.create_table() end
  end

  def teardown do
    Enum.map tables, fn (model) -> model.delete_table() end
  end
end
