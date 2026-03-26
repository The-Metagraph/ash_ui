defmodule AshUI.Resource.DSL.Binding do
  @moduledoc """
  Resource-local DSL helpers for binding declarations.
  """

  alias AshUI.Resource.DSL.Helpers
  alias AshUI.Resources.Validations.Authoring

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Builds one validated binding declaration.
  """
  defmacro ui_binding(do: block) do
    binding =
      block
      |> extract_entries(__CALLER__)
      |> Map.new()
      |> Map.put_new(:id, infer_binding_id(block, __CALLER__))
      |> Authoring.validate_binding_definition!()

    Macro.escape(binding)
  end

  @doc """
  Builds a validated list of binding declarations.
  """
  defmacro ui_bindings(do: block) do
    bindings = __bindings_from_block__(block, __CALLER__)
    Macro.escape(bindings)
  end

  @doc """
  Converts binding declarations into plain attributes.
  """
  def to_attributes(entries) when is_map(entries), do: entries
  def to_attributes(entries) when is_list(entries), do: entries

  @doc """
  Expands a `ui_bindings` block into validated binding declarations.
  """
  def __bindings_from_block__(block, caller) do
    block
    |> Helpers.block_expressions()
    |> Enum.map(&extract_binding_entry(&1, caller))
  end

  defp extract_entries(block, caller) do
    Helpers.extract_literal_entries!(
      block,
      caller,
      [:id, :source, :target, :binding_type, :transform, :metadata],
      "ui_binding"
    )
  end

  defp extract_binding_entry({:binding, _meta, [id_ast, [do: block]]}, caller) do
    id = Helpers.eval_literal!(id_ast, caller, :id, "binding")

    block
    |> extract_entries(caller)
    |> Map.new()
    |> Map.put_new(:id, id)
    |> Authoring.validate_binding_definition!()
  end

  defp extract_binding_entry(other, _caller) do
    raise ArgumentError, "unsupported ui_bindings entry: #{Macro.to_string(other)}"
  end

  defp infer_binding_id(block, caller) do
    entries = extract_entries(block, caller)
    entry_map = Map.new(entries)
    source = Map.get(entry_map, :source, %{})

    Map.get(entry_map, :target) ||
      Map.get(source, :field) ||
      Map.get(source, "field") ||
      Map.get(source, :relationship) ||
      Map.get(source, "relationship") ||
      Map.get(source, :action) ||
      Map.get(source, "action") ||
      :binding
  end
end
