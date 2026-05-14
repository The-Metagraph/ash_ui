defmodule DesktopUi.PhaseThreeIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element

  test "advanced native and canonical desktop flows share the layered runtime model" do
    native_screen = DesktopUi.Examples.native_advanced_operations_screen()
    canonical_screen = DesktopUi.Examples.canonical_advanced_operations_screen()

    assert {:ok, native_state} =
             DesktopUi.Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             DesktopUi.Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    assert native_state.validation_state == :runtime_backbone_ready
    assert canonical_state.validation_state == :runtime_backbone_ready
    assert native_state.realization.validation_state == :advanced_ready
    assert canonical_state.realization.validation_state == :advanced_ready
    assert native_state.realization.mode == canonical_state.realization.mode

    assert Enum.any?(native_state.realization.layers, &(&1.role == :overlay))
    assert Enum.any?(canonical_state.realization.layers, &(&1.role == :overlay))
    assert Enum.any?(native_state.realization.viewport_regions, &(&1.kind == :viewport))
    assert Enum.any?(canonical_state.realization.viewport_regions, &(&1.kind == :viewport))
    assert native_state.windows.continuity == :multi_window
    assert canonical_state.windows.continuity == :multi_window

    assert Enum.sort(native_state.realization.window_ids) ==
             Enum.sort(canonical_state.realization.window_ids)
  end

  test "unsupported advanced constructs and invalid layered state fail deterministically" do
    broken_native = %{
      id: "broken-advanced",
      title: "Broken Advanced",
      root:
        DesktopUi.Widgets.window("broken-window", "Broken", [
          DesktopUi.Layer.overlay(
            "broken-overlay",
            DesktopUi.Widgets.text("broken-copy", "Broken"),
            []
          )
        ])
    }

    assert {:error, %DesktopUi.Runtime.Error{} = native_error} =
             DesktopUi.Runtime.mount_native_screen(broken_native, platform_target: :linux)

    assert native_error.reason == :invalid_layering_state
    assert native_error.phase == :realization

    unsupported_canonical = Element.new(:layer, :sheet, id: "unsupported-sheet")

    assert {:error, %DesktopUi.Runtime.Error{} = canonical_error} =
             DesktopUi.Runtime.mount_iur_screen(unsupported_canonical, platform_target: :linux)

    assert canonical_error.reason == :unsupported_canonical_construct
    assert canonical_error.phase == :renderer_boot
    assert canonical_error.details.id == "unsupported-sheet"
  end

  test "advanced examples and target semantics keep bounded platform variation visible" do
    comparison = DesktopUi.Examples.advanced_comparison()
    semantics = DesktopUi.Examples.target_semantics()
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert comparison.id == :advanced_continuity
    assert comparison.parity.shared_runtime_backbone?
    assert comparison.parity.advanced_ready_match?
    assert comparison.parity.layer_count_match?
    assert comparison.parity.viewport_count_match?
    assert comparison.parity.window_registry_match?

    assert Map.keys(semantics) |> Enum.sort() == DesktopUi.Platform.targets() |> Enum.sort()
    assert semantics.windows.shared_categories == semantics.linux.shared_categories
    assert semantics.windows.bounded_fallbacks == semantics.linux.bounded_fallbacks
    assert :file_open in semantics.windows.capabilities
    refute :file_open in semantics.linux.capabilities

    assert :native_advanced_operations in reference.examples.native_ids
    assert :canonical_advanced_operations in reference.examples.canonical_ids
    assert :advanced_continuity in reference.examples.comparison_ids
    assert :advanced_continuity in summary.examples.comparison_ids
    assert :advanced_display_realization in reference.runtime.capabilities
    assert :multi_window in summary.layer.kinds
    assert DesktopUi.Inspection.package_overview().layer.kinds == DesktopUi.Layer.kinds()
  end
end
