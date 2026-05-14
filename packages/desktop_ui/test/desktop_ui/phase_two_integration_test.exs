defmodule DesktopUi.PhaseTwoIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element

  test "native and canonical foundational screens converge on the same shared runtime backbone" do
    native_screen = DesktopUi.Examples.native_foundational_screen()
    canonical_screen = DesktopUi.Examples.canonical_foundational_screen()

    assert {:ok, native_state} =
             DesktopUi.Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             DesktopUi.Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    assert native_state.validation_state == :runtime_backbone_ready
    assert canonical_state.validation_state == :runtime_backbone_ready
    assert native_state.realization.validation_state == :foundational_ready
    assert canonical_state.realization.validation_state == :foundational_ready
    assert native_state.realization.mode == canonical_state.realization.mode
    assert native_state.screen.bindings.names == canonical_state.screen.bindings.names

    comparison = DesktopUi.Examples.foundational_comparison()

    assert comparison.parity.shared_runtime_backbone?
    assert comparison.parity.focus_order_match?
    assert comparison.parity.body_kind_sequence_match?
    assert comparison.parity.binding_names_match?
  end

  test "unsupported foundational widgets and invalid canonical bindings fail with deterministic diagnostics" do
    unsupported_native = %{
      id: "unsupported-native",
      title: "Unsupported Native",
      root: %DesktopUi.Widget{id: "unsupported-root", kind: :calendar, family: :content}
    }

    assert {:error, %DesktopUi.Runtime.Error{} = native_error} =
             DesktopUi.Runtime.mount_native_screen(unsupported_native, platform_target: :linux)

    assert native_error.reason == :unsupported_foundational_widget
    assert native_error.phase == :realization

    unsupported_canonical = Element.new(:widget, :calendar, id: "unsupported-calendar")

    assert {:error, %DesktopUi.Runtime.Error{} = canonical_error} =
             DesktopUi.Runtime.mount_iur_screen(unsupported_canonical, platform_target: :linux)

    assert canonical_error.reason == :unsupported_canonical_construct
    assert canonical_error.phase == :renderer_boot

    invalid_bindings =
      Element.new(:widget, :text_input,
        id: "query",
        attributes: %{binding: %{invalid: true}}
      )

    assert {:error, %DesktopUi.Runtime.Error{} = invalid_binding_error} =
             DesktopUi.Runtime.mount_iur_screen(invalid_bindings, platform_target: :linux)

    assert invalid_binding_error.reason == :invalid_canonical_bindings
    assert invalid_binding_error.phase == :renderer_boot
  end

  test "maintained examples and comparison helpers stay aligned with reference and info surfaces" do
    comparison = DesktopUi.Examples.foundational_comparison()
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert comparison.coverage.widget_families == [
             :content,
             :action,
             :input,
             :navigation,
             :layout,
             :window
           ]

    assert comparison.coverage.display_constructs == [:column, :row, :content]
    assert :native_foundational in reference.examples.native_ids
    assert :canonical_foundational in reference.examples.canonical_ids
    assert :foundational_continuity in reference.examples.comparison_ids
    assert :foundational_continuity in summary.examples.comparison_ids
    assert :native_foundational in DesktopUi.Inspection.package_overview().examples.native_ids
  end
end
