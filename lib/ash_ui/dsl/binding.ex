defmodule AshUI.DSL.Binding do
  @moduledoc """
  Compile-time helper DSL for binding configuration.
  """

  @allowed_binding_types [:value, :list, :action]

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Declares binding-level attributes with compile-time validation.
  """
  defmacro ui_binding(do: block) do
    block
    |> extract_entries(__CALLER__)
    |> validate_entries!()
    |> Macro.escape()
  end

  defmacro source(value), do: {:source, [], [value]}
  defmacro target(value), do: {:target, [], [value]}
  defmacro binding_type(value), do: {:binding_type, [], [value]}
  defmacro transform(value), do: {:transform, [], [value]}

  @doc """
  Converts DSL output into resource attributes.
  """
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defp extract_entries({:__block__, _meta, expressions}, caller) do
    Enum.map(expressions, &extract_entry(&1, caller))
  end

  defp extract_entries(expression, caller), do: [extract_entry(expression, caller)]

  defp extract_entry({name, _meta, [value_ast]}, caller)
       when name in [:source, :target, :binding_type, :transform] do
    {name, eval_literal!(value_ast, caller, name)}
  end

  defp extract_entry(other, _caller) do
    raise ArgumentError, "unsupported ui_binding entry: #{Macro.to_string(other)}"
  end

  defp validate_entries!(entries) do
    Enum.each(entries, fn
      {:source, value} when is_map(value) or is_binary(value) or is_atom(value) ->
        :ok

      {:source, value} ->
        raise ArgumentError,
              "ui_binding source must be a map, string, or atom, got: #{inspect(value)}"

      {:target, value} when is_binary(value) and value != "" ->
        :ok

      {:target, value} ->
        raise ArgumentError,
              "ui_binding target must be a non-empty string, got: #{inspect(value)}"

      {:binding_type, value} when value in @allowed_binding_types ->
        :ok

      {:binding_type, value} ->
        raise ArgumentError,
              "ui_binding binding_type must be one of #{inspect(@allowed_binding_types)}, got: #{inspect(value)}"

      {:transform, value} when is_map(value) ->
        :ok

      {:transform, value} ->
        raise ArgumentError, "ui_binding transform must be a map, got: #{inspect(value)}"
    end)

    entries
  end

  defp eval_literal!(ast, caller, key) do
    {value, _binding} = Code.eval_quoted(ast, [], caller)
    value
  rescue
    _error ->
      reraise ArgumentError,
              [
                message:
                  "ui_binding #{key} must use a compile-time literal, got: #{Macro.to_string(ast)}"
              ],
              __STACKTRACE__
  end
end
