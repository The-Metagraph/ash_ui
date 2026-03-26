defmodule AshUI.Resource.DSL.Helpers do
  @moduledoc false

  @spec block_expressions(Macro.t() | nil) :: [Macro.t()]
  def block_expressions({:__block__, _meta, expressions}), do: expressions
  def block_expressions(nil), do: []
  def block_expressions(expression), do: [expression]

  @spec extract_literal_entries!(Macro.t(), Macro.Env.t(), [atom()], String.t()) :: keyword()
  def extract_literal_entries!(block, caller, allowed_names, context) do
    block
    |> block_expressions()
    |> Enum.map(fn expression ->
      case expression do
        {name, _meta, [value_ast]} ->
          if name in allowed_names do
            {name, eval_literal!(value_ast, caller, name, context)}
          else
            raise ArgumentError, "unsupported #{context} entry: #{Macro.to_string(expression)}"
          end

        other ->
          raise ArgumentError, "unsupported #{context} entry: #{Macro.to_string(other)}"
      end
    end)
  end

  @spec eval_literal!(Macro.t(), Macro.Env.t(), atom(), String.t()) :: term()
  def eval_literal!(ast, caller, key, context) do
    try do
      {value, _binding} = Code.eval_quoted(ast, [], caller)
      value
    rescue
      _error ->
        raise ArgumentError,
              "#{context} #{key} must use a compile-time literal, got: #{Macro.to_string(ast)}"
    end
  end
end
