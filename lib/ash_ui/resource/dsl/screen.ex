defmodule AshUI.Resource.DSL.Screen do
  @moduledoc """
  Resource-local DSL helpers for screen resources.
  """

  alias AshUI.Resource.DSL.Binding
  alias AshUI.Resource.DSL.Helpers
  alias AshUI.Resources.Validations.Authoring

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :ash_ui_screen_definition, persist: true)
      Module.register_attribute(__MODULE__, :ash_ui_screen_bindings, persist: true)
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
  Converts screen DSL output into plain attributes.
  """
  def to_attributes(entries) when is_map(entries), do: entries
  def to_attributes(entries) when is_list(entries), do: Map.new(entries)

  defmacro __before_compile__(env) do
    definition = Module.get_attribute(env.module, :ash_ui_screen_definition) || %{}
    bindings = Module.get_attribute(env.module, :ash_ui_screen_bindings) || []

    Authoring.validate_screen_authority!(definition, bindings)

    quote do
      def __ash_ui_resource_role__, do: :screen
      def __ash_ui_screen_definition__, do: unquote(Macro.escape(definition))
      def __ash_ui_bindings__, do: unquote(Macro.escape(bindings))

      def __ash_ui_authority__ do
        %{
          role: :screen,
          screen: __ash_ui_screen_definition__(),
          bindings: __ash_ui_bindings__()
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
end
