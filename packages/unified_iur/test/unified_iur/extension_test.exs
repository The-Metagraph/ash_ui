defmodule UnifiedIUR.ExtensionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Extension

  test "exposes extension points, compatibility rules, and migration guidance" do
    assert %{
             element_types: [:widget, :layout, :layer, :style, :theme, :interaction, :composite],
             attachment_fields: [:style, :theme, :interactions, :bindings, :interaction_scope],
             child_shape_preservation: true
           } = Extension.extension_points()

    assert %{
             additive_optional_fields_allowed?: true,
             default_values_must_preserve_shape?: true,
             identity_and_type_must_remain_stable?: true
           } = Extension.compatibility_rules()

    assert %{
             deprecation_process: [:introduce_additive_shape | _],
             shape_correction_process: [:record_reason | _]
           } = Extension.migration_guidance()
  end

  test "reports the current canonical iur catalog and unified_ui mapping surface" do
    assert %{
             foundational_widgets: foundational,
             input_widgets: input,
             layout_constructs: layouts,
             layer_constructs: layers,
             canvas_constructs: canvas
           } = Extension.iur_catalog()

    assert :button in foundational
    assert :text_input in input
    assert :column in layouts
    assert :dialog in layers
    assert :canvas in canvas

    assert %{
             widgets: %{foundational: ^foundational},
             display_systems: %{layouts: ^layouts}
           } = Extension.unified_ui_family_map()
  end

  test "flags unsynchronized unified_ui and unified_iur family sets" do
    report =
      Extension.parity_report(%{
        foundational_widgets: [:text, :button],
        input_widgets: [:text_input],
        layout_constructs: [:column, :row],
        layer_constructs: [:dialog]
      })

    refute report.synchronized?
    assert report.categories.foundational_widgets.missing_in_unified_ui != []

    assert {:error, issues} =
             Extension.validate_unified_ui_parity(%{
               foundational_widgets: [:text, :button],
               input_widgets: [:text_input],
               layout_constructs: [:column, :row],
               layer_constructs: [:dialog]
             })

    assert Enum.any?(issues, &(&1.kind == :missing_in_unified_ui))
  end
end
