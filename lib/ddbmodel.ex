defmodule DDBModel do
  
  defmacro __using__(opts) do
    setup(opts)
  end

  defmacro __before_compile__(_env) do
    quote do
      def model_columns, do: @model_columns
      def model_column_defaults, do: Enum.map(@model_columns, fn ({key, attr}) -> {key, attr[:default]} end)
    end
  end
  
  defp setup(opts) do
    quote do
      Module.register_attribute __MODULE__, :model_columns, accumulate: true, persist: true
      unquote(DDBModel.Model.generate(:model, opts))
      unquote(DDBModel.Validation.generate(:model))
      unquote(DDBModel.DB.generate(:model))
      
      import DDBModel

      @before_compile unquote(__MODULE__)
    end
  end
  
  @doc "define a column"
  defmacro defcolumn(name, opts \\ []), do: DDBModel.Columns.generate(:column, name, opts)
  
  defmacro with_timestamps do
    quote do
      defcolumn :created_at, type: :created_timestamp
      defcolumn :updated_at, type: :updated_timestamp
      
    end
  end
  
end
