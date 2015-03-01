defmodule DDBModel.Util do   

  def unix_timestamp do
    utc = :calendar.now_to_universal_time(:erlang.now())
    greg = :calendar.datetime_to_gregorian_seconds(utc) 
    greg_1970 = :calendar.datetime_to_gregorian_seconds( {{1970,1,1},{0,0,0}} )

    greg - greg_1970
  end

  def validate(:null, false, k, nil), do: {:error, {k, Atom.to_string(k) <> " must not be null"}}
  def validate(:null, _, _, _), do: :ok
  def validate(:in_list, l, k, v) when is_list(l) do
    if Enum.any? l, &(&1 == v) do
      :ok
    else
      {:error, {k, Atom.to_string(k) <> " must be in list " <> (inspect l)}}
    end
  end
  def validate(:in_list, _, _, _), do: :ok
  def validate(:validate, f, k, v) when is_function(f) do
    case f.(v) do
      true  -> :ok
      false -> {:error, {k, Atom.to_string(k) <> " failed validation"}}
      res   -> res
    end
  end
  
  def validate(:validate, _, _, _), do: :ok

  def before_save(:uuid, nil), do: :binary.list_to_bin(:uuid.to_string :uuid.uuid4())
  def before_save(:uuid, v), do: v
  def before_save(:created_timestamp, nil), do: unix_timestamp
  def before_save(:created_timestamp, v), do: v
  def before_save(:updated_timestamp, _v), do: unix_timestamp
  def before_save(_,v), do: v

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
