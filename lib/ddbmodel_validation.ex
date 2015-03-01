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

      def validates?(record={__MODULE__, dict}), do: validate(record) == :ok

      def before_save(record={__MODULE__, dict}) do
        res = Enum.map model_columns, fn({k,opts}) ->
          {k, before_save(opts[:type], dict[k])}
        end
        new(res)
      end
      defoverridable [before_save: 1]

    end
  end

end