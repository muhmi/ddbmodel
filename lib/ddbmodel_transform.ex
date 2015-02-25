defmodule DDBModel.Transform do

  def parse_item(item) do
    Enum.map item, fn({k, v}) ->
      {String.to_atom(k), v}
    end
  end

  def from_dynamo(:json, "null"), do: nil
  def from_dynamo(:binary, v), do: v
  def from_dynamo(:atom, v), do: String.to_atom(v)
  def from_dynamo(:json, v), do: :jsx.decode(v)
  def from_dynamo(_,v), do: v

  def to_dynamo(:atom, v), do: Atom.to_string(v)
  def to_dynamo(:binary, v), do: {:b, v}
  def to_dynamo(:json, nil), do: "null"
  def to_dynamo(:json, v), do: :jsx.encode(v)
  def to_dynamo(_,v), do: v

end