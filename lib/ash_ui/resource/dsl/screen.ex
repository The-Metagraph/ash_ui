defmodule AshUI.Resource.DSL.Screen do
  @moduledoc """
  Resource-local DSL helpers for screen resources.
  """

  alias AshUI.Resource.DSL.Binding
  alias AshUI.Resource.DSL.Helpers
  alias AshUI.Resource.DSL.Relationship
  alias AshUI.Resources.Validations.Authoring

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      import unquote(Relationship)
      Module.register_attribute(__MODULE__, :ash_ui_screen_definition, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_screen_bindings, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_screen_actions, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_relationship_definitions, persist: true)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Builds the validated authoring definition owned by a screen resource.
  """
  defmacro ui_screen(do: block) do
    definition =
      block
      |> extract_entries(__CALLER__)
      |> Map.new()
      |> Authoring.validate_screen_definition!()

    Module.put_attribute(__CALLER__.module, :ash_ui_screen_definition, definition)
    Macro.escape(definition)
  end

  @doc """
  Builds the validated screen-scoped bindings for a screen resource.
  """
  defmacro ui_screen_bindings(do: block) do
    bindings =
      block
      |> Binding.__bindings_from_block__(__CALLER__)
      |> Enum.map(&Authoring.validate_binding_definition!(&1, scope: :screen))

    Module.put_attribute(__CALLER__.module, :ash_ui_screen_bindings, bindings)
    Macro.escape(bindings)
  end

  @doc """
  Builds validated screen-scoped interaction actions for a screen resource.
  """
  defmacro ui_screen_actions(do: block) do
    actions = extract_actions(block, __CALLER__)

    Module.put_attribute(__CALLER__.module, :ash_ui_screen_actions, actions)
    Macro.escape(actions)
  end

  @doc """
  Converts screen DSL output into plain attributes.
  """
  def to_attributes(entries) when is_map(entries), do: entries
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defmacro __before_compile__(env) do
    definition = Module.get_attribute(env.module, :ash_ui_screen_definition) || %{}
    bindings = Module.get_attribute(env.module, :ash_ui_screen_bindings) || []
    actions = Module.get_attribute(env.module, :ash_ui_screen_actions) || []
    relationships = Module.get_attribute(env.module, :ash_ui_relationship_definitions) || %{}

    Authoring.validate_screen_authority!(definition, bindings, actions)

    quote do
      def __ash_ui_resource_role__, do: :screen
      def __ash_ui_screen_definition__, do: unquote(Macro.escape(definition))
      def __ash_ui_bindings__, do: unquote(Macro.escape(bindings))
      def __ash_ui_actions__, do: unquote(Macro.escape(actions))
      def __ash_ui_relationships__, do: unquote(Macro.escape(relationships))

      def __ash_ui_authority__ do
        %{
          role: :screen,
          screen: __ash_ui_screen_definition__(),
          bindings: __ash_ui_bindings__(),
          actions: __ash_ui_actions__(),
          relationships: __ash_ui_relationships__()
        }
      end
    end
  end

  defp extract_entries(block, caller) do
    Helpers.extract_literal_entries!(
      block,
      caller,
      [:layout, :route, :metadata, :inline_fragment],
      "ui_screen"
    )
  end

  defp extract_actions(block, caller) do
    block
    |> Helpers.block_expressions()
    |> Enum.map(fn
      {:action, _meta, [id_ast, [do: action_block]]} ->
        id = Helpers.eval_literal!(id_ast, caller, :id, "screen action")

        action_block
        |> Helpers.extract_literal_entries!(
          caller,
          [
            :signal,
            :source,
            :target,
            :navigation,
            :source_context,
            :payload_mapping,
            :binding_refs,
            :summary,
            :transform,
            :metadata
          ],
          "ui_screen_action"
        )
        |> Map.new()
        |> Map.put_new(:id, id)
        |> Authoring.validate_action_definition!()

      other ->
        raise ArgumentError, "unsupported ui_screen_actions entry: #{Macro.to_string(other)}"
    end)
  end
end
