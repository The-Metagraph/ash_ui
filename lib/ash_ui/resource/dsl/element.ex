defmodule AshUI.Resource.DSL.Element do
  @moduledoc """
  Resource-local DSL helpers for element resources.
  """

  alias AshUI.Resource.DSL.Binding
  alias AshUI.Resource.DSL.Helpers
  alias AshUI.Resources.Validations.Authoring

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :ash_ui_element_definition, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_element_bindings, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_element_actions, persist: true)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Builds the validated DSL fragment owned by an element resource.
  """
  defmacro ui_element(do: block) do
    definition =
      block
      |> extract_entries(__CALLER__)
      |> Map.new()
      |> Authoring.validate_element_definition!()

    Module.put_attribute(__CALLER__.module, :ash_ui_element_definition, definition)
    Macro.escape(definition)
  end

  @doc """
  Builds the validated bindings owned by an element resource.
  """
  defmacro ui_bindings(do: block) do
    bindings =
      block
      |> Binding.__bindings_from_block__(__CALLER__)
      |> Enum.map(&Authoring.validate_binding_definition!(&1, scope: :element))

    Module.put_attribute(__CALLER__.module, :ash_ui_element_bindings, bindings)
    Macro.escape(bindings)
  end

  @doc """
  Builds the validated interaction actions owned by an element resource.
  """
  defmacro ui_actions(do: block) do
    actions = extract_actions(block, __CALLER__)

    Module.put_attribute(__CALLER__.module, :ash_ui_element_actions, actions)
    Macro.escape(actions)
  end

  @doc """
  Converts element DSL output into plain attributes.
  """
  def to_attributes(entries) when is_map(entries), do: entries
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defmacro __before_compile__(env) do
    definition = Module.get_attribute(env.module, :ash_ui_element_definition) || %{}
    bindings = Module.get_attribute(env.module, :ash_ui_element_bindings) || []
    actions = Module.get_attribute(env.module, :ash_ui_element_actions) || []

    Authoring.validate_element_authority!(definition, bindings, actions)

    quote do
      def __ash_ui_resource_role__, do: :element
      def __ash_ui_element_definition__, do: unquote(Macro.escape(definition))
      def __ash_ui_bindings__, do: unquote(Macro.escape(bindings))
      def __ash_ui_actions__, do: unquote(Macro.escape(actions))

      def __ash_ui_authority__ do
        %{
          role: :element,
          element: __ash_ui_element_definition__(),
          bindings: __ash_ui_bindings__(),
          actions: __ash_ui_actions__()
        }
      end
    end
  end

  defp extract_entries(block, caller) do
    Helpers.extract_literal_entries!(
      block,
      caller,
      [:type, :props, :variants, :metadata],
      "ui_element"
    )
  end

  defp extract_actions(block, caller) do
    block
    |> Helpers.block_expressions()
    |> Enum.map(fn
      {:action, _meta, [id_ast, [do: action_block]]} ->
        id = Helpers.eval_literal!(id_ast, caller, :id, "action")

        action_block
        |> Helpers.extract_literal_entries!(
          caller,
          [:signal, :source, :target, :transform, :metadata],
          "ui_action"
        )
        |> Map.new()
        |> Map.put_new(:id, id)
        |> Authoring.validate_action_definition!()

      other ->
        raise ArgumentError, "unsupported ui_actions entry: #{Macro.to_string(other)}"
    end)
  end
end
