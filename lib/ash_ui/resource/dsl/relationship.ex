defmodule AshUI.Resource.DSL.Relationship do
  @moduledoc """
  Resource-local DSL helpers for Ash relationship composition semantics.
  """

  alias AshUI.Resource.DSL.Helpers
  alias AshUI.Resources.Validations.Authoring

  @doc """
  Builds the validated composition semantics for Ash relationships owned by a
  screen or element resource.
  """
  defmacro ui_relationships(do: block) do
    relationships =
      block
      |> Helpers.block_expressions()
      |> Enum.map(fn
        {:relationship, _meta, [name_ast, [do: semantics_block]]} ->
          name = Helpers.eval_literal!(name_ast, __CALLER__, :name, "ui_relationship")

          semantics =
            semantics_block
            |> Helpers.extract_literal_entries!(
              __CALLER__,
              [:kind, :slot, :placement, :order, :repeat],
              "ui_relationship"
            )
            |> Map.new()
            |> Map.put_new(:name, name)
            |> Authoring.validate_relationship_definition!()

          {name, semantics}

        other ->
          raise ArgumentError, "unsupported ui_relationships entry: #{Macro.to_string(other)}"
      end)
      |> Map.new()

    Module.put_attribute(__CALLER__.module, :ash_ui_relationship_definitions, relationships)
    Macro.escape(relationships)
  end
end
