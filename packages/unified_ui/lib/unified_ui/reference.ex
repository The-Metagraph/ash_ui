defmodule UnifiedUi.Reference do
  @moduledoc """
  Package-facing reference helpers for the authored `UnifiedUi` DSL.
  """

  alias UnifiedUi.Dsl.{Entities, Identity, Placement, SectionRegistry}
  alias UnifiedUi.Examples
  alias UnifiedUi.Signal
  alias UnifiedUi.Theme
  alias UnifiedUi.WidgetComponents

  @spec supported_sections() :: [atom()]
  def supported_sections do
    SectionRegistry.section_names()
  end

  @spec dsl_sections() :: %{
          atom() => %{fields: [atom()], purpose: String.t(), top_level?: boolean()}
        }
  def dsl_sections do
    SectionRegistry.sections()
    |> Map.new(fn section ->
      {section.name,
       %{
         fields: Keyword.keys(section.schema),
         purpose: normalize_description(section.describe),
         top_level?: section.top_level?
       }}
    end)
  end

  @spec section_purposes() :: %{atom() => String.t()}
  def section_purposes do
    dsl_sections()
    |> Map.new(fn {name, metadata} -> {name, metadata.purpose} end)
  end

  @spec extension_points() :: %{atom() => [atom()]}
  def extension_points do
    SectionRegistry.extension_points()
  end

  @spec construct_families() :: %{atom() => [atom()]}
  def construct_families do
    Entities.construct_families()
  end

  @spec compiled_construct_families() :: map()
  def compiled_construct_families do
    %{
      element_types: UnifiedIUR.Reference.construct_families(),
      widgets: compiled_widget_families(),
      display: compiled_display_system_families(),
      signals: compiled_signal_families()
    }
  end

  @spec compiled_widget_families() :: %{atom() => [atom()]}
  def compiled_widget_families do
    %{
      foundational: UnifiedIUR.Widgets.foundational_kinds(),
      input: UnifiedIUR.Widgets.input_kinds(),
      navigation: UnifiedIUR.Widgets.navigation_kinds(),
      data: UnifiedIUR.Widgets.data_view_kinds(),
      feedback: UnifiedIUR.Widgets.feedback_kinds(),
      advanced: UnifiedIUR.Widgets.advanced_kinds(),
      forms: UnifiedIUR.Forms.kinds(),
      container: [:box]
    }
  end

  @spec widget_component_families() :: %{WidgetComponents.family() => [atom()]}
  def widget_component_families do
    WidgetComponents.component_families()
  end

  @spec widget_component_catalog() :: [WidgetComponents.component()]
  def widget_component_catalog do
    WidgetComponents.catalog()
  end

  @spec widget_component_aliases() :: %{atom() => atom()}
  def widget_component_aliases do
    WidgetComponents.aliases()
  end

  @spec compiled_display_system_families() :: %{atom() => [atom()]}
  def compiled_display_system_families do
    %{
      layout: UnifiedIUR.Layout.kinds(),
      layer: UnifiedIUR.Layer.kinds(),
      viewport: UnifiedIUR.Viewport.kinds(),
      canvas: UnifiedIUR.Canvas.kinds()
    }
  end

  @spec identity_rules() :: map()
  def identity_rules do
    %{
      required_sections: Identity.required_sections(),
      reserved_ids: Identity.reserved_ids(),
      traceability_fields: Identity.traceability_fields(),
      identifier_fields: Identity.identifier_fields()
    }
  end

  @spec placement_rules() :: map()
  def placement_rules do
    %{
      boundaries: Placement.section_boundaries(),
      rules: Placement.placement_rules()
    }
  end

  @spec example_catalog() :: [map()]
  def example_catalog do
    Examples.catalog()
  end

  @spec theme_catalog(module()) :: [map()]
  def theme_catalog(module) when is_atom(module) do
    module
    |> Theme.themes()
    |> Enum.map(&Theme.summary/1)
  end

  @spec style_attribute_families() :: %{atom() => [atom()]}
  def style_attribute_families do
    UnifiedUi.Style.attribute_families()
  end

  @spec semantic_style_roles() :: [atom()]
  def semantic_style_roles do
    UnifiedUi.Style.semantic_roles()
  end

  @spec style_component_states() :: [atom()]
  def style_component_states do
    UnifiedUi.Style.component_states()
  end

  @spec signal_families() :: [Signal.family()]
  def signal_families do
    Signal.families()
  end

  @spec navigation_actions() :: [Signal.navigation_transition_action()]
  def navigation_actions do
    Signal.navigation_actions()
  end

  @spec navigation_contract() :: %{
          transition_fields: [atom()],
          local_navigation_fields: [atom()],
          modal_stack: %{Signal.navigation_transition_action() => Signal.modal_stack_semantics()},
          actions: %{Signal.navigation_transition_action() => Signal.navigation_action_contract()}
        }
  def navigation_contract do
    %{
      transition_fields: Signal.navigation_transition_fields(),
      local_navigation_fields: Signal.local_navigation_fields(),
      modal_stack: Signal.navigation_modal_stack_semantics(),
      actions: Signal.navigation_action_contracts()
    }
  end

  @spec compiled_signal_families() :: [UnifiedIUR.Interaction.family()]
  def compiled_signal_families do
    UnifiedIUR.Interaction.families()
  end

  defp normalize_description(description) do
    description
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end
end
