defmodule AshUI.DSL.Element do
  @moduledoc """
  Compile-time helper DSL for element configuration.
  """

  alias AshUI.DSL.Storage

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Declares element-level attributes with compile-time validation.
  """
  defmacro ui_element(do: block) do
    block
    |> extract_entries(__CALLER__)
    |> validate_entries!()
    |> Macro.escape()
  end

  defmacro type(value), do: {:type, [], [value]}
  defmacro props(value), do: {:props, [], [value]}
  defmacro variants(value), do: {:variants, [], [value]}

  @doc """
  Converts DSL output into resource attributes.
  """
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defp extract_entries({:__block__, _meta, expressions}, caller) do
    Enum.map(expressions, &extract_entry(&1, caller))
  end

  defp extract_entries(expression, caller), do: [extract_entry(expression, caller)]

  defp extract_entry({name, _meta, [value_ast]}, caller)
       when name in [:type, :props, :variants] do
    {name, eval_literal!(value_ast, caller, name)}
  end

  defp extract_entry(other, _caller) do
    raise ArgumentError, "unsupported ui_element entry: #{Macro.to_string(other)}"
  end

  defp validate_entries!(entries) do
    Enum.each(entries, fn
      {:type, value} ->
        type =
          case value do
            atom when is_atom(atom) -> Atom.to_string(atom)
            binary when is_binary(binary) -> binary
            other -> other
          end

        if not (is_binary(type) and Storage.valid_widget_type?(type)) do
          raise ArgumentError,
                "ui_element type must be a known widget type, got: #{inspect(value)}"
        end

      {:props, value} when is_map(value) ->
        :ok

      {:props, value} ->
        raise ArgumentError, "ui_element props must be a map, got: #{inspect(value)}"

      {:variants, value} when is_list(value) ->
        if Enum.all?(value, &(is_atom(&1) or is_binary(&1))) do
          :ok
        else
          raise ArgumentError,
                "ui_element variants must be a list of atoms or strings, got: #{inspect(value)}"
        end
    end)

    entries
  end

  defp eval_literal!(ast, caller, key) do
    try do
      {value, _binding} = Code.eval_quoted(ast, [], caller)
      value
    rescue
      _error ->
        reraise ArgumentError,
                [
                  message:
                    "ui_element #{key} must use a compile-time literal, got: #{Macro.to_string(ast)}"
                ],
                __STACKTRACE__
    end
  end
end
