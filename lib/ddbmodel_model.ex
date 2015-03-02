defmodule DDBModel.Model do

  def generate(:model, opts) do
    quote do

      unquote(generate_table_name(opts[:table_name]))
      unquote(generate_key(opts[:key]))

      @doc "make record and init with default values"
      def new (attributes \\ []) do
        {__MODULE__, HashDict.merge( Enum.into(model_column_defaults, HashDict.new), Enum.into(attributes, HashDict.new))}
      end

      @doc "update module from dict"
      def set(attributes,record = {__MODULE__, _dict}), do: set(attributes, nil, record)

      def set(attributes, allowed_keys, {__MODULE__, dict}) do
        attributes = case allowed_keys do
          nil -> attributes
          _   -> Enum.filter attributes, fn({k,_v}) -> Enum.any? allowed_keys, &(&1 == k) end
        end
        {__MODULE__, HashDict.merge(dict, Enum.into(attributes, HashDict.new))}
      end

      @doc "get the record id"
      def id(record = {__MODULE__, dict}) do
        case key do
          {hash, range} -> {dict[hash], dict[range]}
          k             -> dict[k]
        end
      end

    end
  end

  def generate_table_name(nil) do
    quote do
      def table_name, do: Atom.to_string(Mix.env) <> "_" <> inspect(__MODULE__)
    end
  end
  def generate_table_name(name) do
    quote do
      def table_name, do: unquote(name)
    end
  end

  def generate_key(nil) do
    quote do
      def key, do: :hash
    end
  end

  def generate_key(key) do
    quote do
      def key, do: unquote(key)
    end
  end

end