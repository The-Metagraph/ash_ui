defmodule AshUI.DSL.Screen do
  @moduledoc """
  Compile-time helper DSL for screen configuration.

  The helpers in this module are intentionally lightweight and return
  keyword-backed attributes that can be merged into persisted screen data.
  """

  @allowed_layouts [:default, :bare, :modal, :panel, :row, :column, :grid, :stack]

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Declares screen-level attributes with compile-time validation.
  """
  defmacro ui_screen(do: block) do
    block
    |> extract_entries(__CALLER__)
    |> normalize_entries()
    |> validate_entries!()
    |> Macro.escape()
  end

  defmacro layout(value), do: {:layout, [], [value]}
  defmacro route(value), do: {:route, [], [value]}
  defmacro metadata(value), do: {:metadata, [], [value]}

  @doc """
  Converts DSL output into resource attributes.
  """
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defp extract_entries({:__block__, _meta, expressions}, caller) do
    Enum.map(expressions, &extract_entry(&1, caller))
  end

  defp extract_entries(expression, caller), do: [extract_entry(expression, caller)]

  defp extract_entry({name, _meta, [value_ast]}, caller)
       when name in [:layout, :route, :metadata] do
    {name, eval_literal!(value_ast, caller, name)}
  end

  defp extract_entry(other, _caller) do
    raise ArgumentError, "unsupported ui_screen entry: #{Macro.to_string(other)}"
  end

  defp normalize_entries(entries), do: entries

  defp validate_entries!(entries) do
    Enum.each(entries, fn
      {:layout, value} when is_atom(value) and value in @allowed_layouts ->
        :ok

      {:layout, value} ->
        raise ArgumentError,
              "ui_screen layout must be one of #{inspect(@allowed_layouts)}, got: #{inspect(value)}"

      {:route, value} when is_binary(value) and value != "" ->
        :ok

      {:route, value} ->
        raise ArgumentError, "ui_screen route must be a non-empty string, got: #{inspect(value)}"

      {:metadata, value} when is_map(value) ->
        :ok

      {:metadata, value} ->
        raise ArgumentError, "ui_screen metadata must be a map, got: #{inspect(value)}"
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
                  "ui_screen #{key} must use a compile-time literal, got: #{Macro.to_string(ast)}"
              ],
              __STACKTRACE__
  end
end
