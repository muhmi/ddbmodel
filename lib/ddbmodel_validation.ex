defmodule DDBModel.Validation do
  
  def generate(:model) do
    quote do

      import DDBModel.Util
      
      def validate(record={__MODULE__, dict}) do
        res = Enum.map model_columns, fn({k,opts}) ->
          Enum.map [:null, :validate, :in_list], fn(opt) ->
            validate(opt, opts[opt], k, dict[k])
          end
        end
        
        case Enum.filter (List.flatten res), &(&1 != :ok) do
          []    -> :ok
          error -> error
        end
      end
      
      defoverridable [validate: 1]
      
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
      
      def validates?(record={__MODULE__, dict}), do: validate(record) == :ok
      
      
      def before_save(record={__MODULE__, dict}) do
        res = Enum.map model_columns, fn({k,opts}) ->
          {k, before_save(opts[:type], dict[k])}
        end
        new(res)
      end
      
      defoverridable [before_save: 1]
     
      
      
      def before_save(:uuid, v) do
        if v == nil do
          :binary.list_to_bin(:uuid.to_string :uuid.uuid4())
        else
          v
        end
      end
      
      def before_save(:created_timestamp, v) do
        if v == nil do
          unix_timestamp
        else
          v
        end
      end
      
      def before_save(:updated_timestamp, v), do: unix_timestamp
      
      def before_save(_,v), do: v
      
    end
  end
  
  
end