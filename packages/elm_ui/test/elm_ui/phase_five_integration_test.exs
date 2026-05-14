defmodule ElmUi.PhaseFiveIntegrationTest do
  use ExUnit.Case, async: true

  test "styling-heavy native screens preserve deterministic server and frontend style meaning" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_styling_screen())

    assert {:ok, first_snapshot} =
             ElmUi.Inspection.runtime_snapshot(
               runtime_state,
               %{focused_id: "style-query", editing_ids: ["style-query"]}
             )

    assert {:ok, second_snapshot} =
             ElmUi.Inspection.runtime_snapshot(
               runtime_state,
               %{focused_id: "style-query", editing_ids: ["style-query"]}
             )

    server_query = find_style_node(first_snapshot.server.style_nodes, "style-query")
    frontend_query = find_style_node(first_snapshot.frontend.style_nodes, "style-query")
    primary_action = find_style_node(first_snapshot.server.style_nodes, "primary-action")

    assert first_snapshot == second_snapshot
    assert server_query.theme == :midnight
    assert server_query.resolved_styles.border == :focus_ring
    assert primary_action.resolved_styles.background == :accent_tint
    assert "is-focused" in frontend_query.browser_style.class_tokens
    assert "is-editing" in frontend_query.browser_style.class_tokens
  end

  test "native and canonical styling examples preserve canonical styling meaning" do
    assert {:ok, native_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_styling_screen())

    assert {:ok, canonical_state} =
             ElmUi.Runtime.mount_iur_screen(
               ElmUi.Examples.canonical_styling_screen(),
               theme: :midnight
             )

    assert {:ok, report} =
             ElmUi.Continuity.compare(
               native_state,
               canonical_state,
               native_local_state: %{focused_id: "style-query", editing_ids: ["style-query"]},
               canonical_local_state: %{focused_id: "style-query", editing_ids: ["style-query"]}
             )

    assert report.continuity.validation.status == :pass
    assert report.continuity.theme_propagation_match?
    assert report.continuity.style_resolution_match?
    assert report.continuity.frontend_realization_match?
    assert "style-inspector" in report.continuity.shared_ids
  end

  test "invalid style combinations, unresolved tokens, and theme drift fail with actionable diagnostics" do
    screen =
      ElmUi.Widgets.screen("broken-styles", "Broken Styles", [
        ElmUi.Widgets.button("broken-token", "Broken",
          style_hooks: [:theme_tokens],
          theme_tokens: %{missing: [:button, :ghost]}
        ),
        ElmUi.Widgets.text("hidden-alert", "Hidden",
          visibility: :hidden,
          emphasis: :strong
        )
      ])

    assert {:ok, runtime_state} = ElmUi.Runtime.mount_native_screen(screen)

    payload = ElmUi.ServerRuntime.frontend_payload(runtime_state)
    broken_token = find_node(payload.tree, "broken-token")
    hidden_alert = find_node(payload.tree, "hidden-alert")

    assert [%{reason: :unresolved_theme_token}] = broken_token.diagnostics.style_diagnostics

    assert [
             %{
               reason: :incompatible_style_combination,
               detail: :visibility_conflicts_with_emphasis
             }
           ] = hidden_alert.diagnostics.style_diagnostics

    assert {:ok, native_state} =
             ElmUi.Runtime.mount_native_screen(ElmUi.Examples.native_styling_screen())

    assert {:ok, canonical_state} =
             ElmUi.Runtime.mount_iur_screen(ElmUi.Examples.canonical_styling_screen())

    assert {:ok, drift_report} = ElmUi.Continuity.compare(native_state, canonical_state)

    assert drift_report.continuity.validation.status == :fail
    assert :server_theme_propagation in drift_report.continuity.validation.failing_seams
    assert Enum.any?(drift_report.diagnostics, &(&1.reason == :theme_mismatch))
  end

  test "inspection surfaces and styling review artifacts stay usable without hidden runtime seams" do
    overview = ElmUi.Inspection.package_overview()
    comparison = ElmUi.Examples.styling_comparison()
    reference = ElmUi.reference()

    assert :runtime_snapshot in ElmUi.Inspection.helpers()
    assert :continuity_diagnostics in ElmUi.Tooling.workflows()
    assert ElmUi.Inspection in ElmUi.Tooling.preview_surfaces()
    assert ElmUi.Continuity in ElmUi.Tooling.preview_surfaces()
    assert :style_realization in overview.runtime.capabilities
    assert :server_style_resolution in reference.inspection.continuity_contract.seams

    assert comparison.continuity.validation.status == :pass
    assert Enum.any?(comparison.review_artifact.server.native, &(&1.id == "primary-action"))
    assert Enum.any?(comparison.review_artifact.frontend.canonical, &(&1.id == "style-query"))
  end

  defp find_node(node, id) when is_map(node) do
    if node.id == id do
      node
    else
      node.slots
      |> Enum.flat_map(& &1.children)
      |> Enum.find_value(&find_node(&1, id))
    end
  end

  defp find_node(nil, _id), do: nil

  defp find_style_node(nodes, id) do
    Enum.find(nodes, &(to_string(&1.id) == id))
  end
end
