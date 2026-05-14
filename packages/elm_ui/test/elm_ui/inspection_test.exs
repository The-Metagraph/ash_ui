defmodule ElmUi.InspectionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element

  test "package inspection overview summarizes widget, style, theme, and renderer coverage" do
    overview = ElmUi.Inspection.package_overview()

    assert :content in overview.widgets.families
    assert :typography in overview.style.primitives
    assert :theme_token_references in overview.style.responsibilities
    assert :default in overview.theme.catalog
    assert :text in overview.renderer.supported_kinds
    assert :style_realization in overview.runtime.capabilities
  end

  test "runtime inspection exposes server resolved style state and frontend realization state" do
    screen =
      ElmUi.Widgets.screen(
        "inspection-surface",
        "Inspection Surface",
        [
          ElmUi.Widgets.button("save-button", "Save",
            variant: :primary,
            style_hooks: [:theme_tokens],
            theme_tokens: %{button: [:button, :primary]}
          )
        ],
        theme: :midnight
      )

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)

    assert {:ok, snapshot} =
             ElmUi.Inspection.runtime_snapshot(state, %{focused_id: "save-button"})

    assert snapshot.runtime.theme == :midnight

    assert Enum.any?(snapshot.server.style_nodes, fn node ->
             node.id == "save-button" and node.resolved_styles.background == :accent_tint
           end)

    assert Enum.any?(snapshot.frontend.style_nodes, fn node ->
             node.id == "save-button" and "theme-midnight" in node.browser_style.class_tokens
           end)

    assert snapshot.frontend.focused_ids == ["save-button"]
  end

  test "continuity diagnostics stay quiet for aligned inputs and actionable for drift" do
    assert {:ok, native_foundational_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_foundational_screen())

    assert {:ok, canonical_foundational_state} =
             ElmUi.Runtime.mount_iur_screen(ElmUi.Examples.canonical_foundational_screen())

    assert {:ok, passing_report} =
             ElmUi.Continuity.compare(native_foundational_state, canonical_foundational_state)

    assert passing_report.continuity.validation.status == :pass
    assert passing_report.diagnostics == []

    native_drift_screen =
      ElmUi.Widgets.screen(
        "style-continuity",
        "Style Continuity",
        [
          ElmUi.Widgets.button("save-button", "Save",
            variant: :primary,
            style_hooks: [:theme_tokens],
            theme_tokens: %{button: [:button, :primary]}
          )
        ],
        theme: :midnight
      )

    canonical_drift_element =
      Element.new(:layout, :column,
        id: "style-continuity",
        children: [
          Element.new(:widget, :button,
            id: "save-button",
            attributes: %{label: "Save"}
          )
        ]
      )

    assert {:ok, native_drift_state} = ElmUi.Runtime.mount_native_screen(native_drift_screen)
    assert {:ok, canonical_drift_state} = ElmUi.Runtime.mount_iur_screen(canonical_drift_element)

    assert {:ok, failing_report} =
             ElmUi.Continuity.compare(native_drift_state, canonical_drift_state)

    assert failing_report.continuity.validation.status == :fail
    refute failing_report.continuity.theme_propagation_match?
    refute failing_report.continuity.style_resolution_match?

    assert Enum.any?(failing_report.diagnostics, &(&1.reason == :theme_mismatch))
    assert Enum.any?(failing_report.diagnostics, &(&1.reason == :resolved_style_mismatch))

    assert Enum.any?(failing_report.continuity.validation.actionable_output, fn diagnostic ->
             diagnostic.seam == :server_style_resolution
           end)
  end
end
