defmodule ElmUi.ExamplesTest do
  use ExUnit.Case, async: true

  test "examples catalog exposes native, canonical, and continuity artifacts" do
    assert [
             :advanced_continuity,
             :canonical_advanced,
             :canonical_foundational,
             :canonical_navigation,
             :canonical_styling,
             :canonical_transport,
             :canonical_welcome,
             :foundational_continuity,
             :mixed_transport,
             :native_advanced,
             :native_counter,
             :native_foundational,
             :native_navigation,
             :native_styling,
             :native_transport,
             :navigation_continuity,
             :styling_continuity
           ] =
             ElmUi.Examples.catalog()
             |> Enum.map(& &1.id)
             |> Enum.sort()
  end

  test "example metadata partitions native, canonical, and mixed suites with stable review artifacts" do
    assert Enum.sort(Enum.map(ElmUi.Examples.native_examples(), & &1.id)) == [
             :native_advanced,
             :native_counter,
             :native_foundational,
             :native_navigation,
             :native_styling,
             :native_transport
           ]

    assert Enum.sort(Enum.map(ElmUi.Examples.canonical_examples(), & &1.id)) == [
             :canonical_advanced,
             :canonical_foundational,
             :canonical_navigation,
             :canonical_styling,
             :canonical_transport,
             :canonical_welcome
           ]

    assert Enum.sort(Enum.map(ElmUi.Examples.mixed_examples(), & &1.id)) == [
             :advanced_continuity,
             :foundational_continuity,
             :mixed_transport,
             :navigation_continuity,
             :styling_continuity
           ]

    assert %{
             category: :native,
             workflow: :styling,
             artifact_names: artifact_names,
             parity_with: [:canonical_styling, :styling_continuity],
             traceability: %{
               package_specs: package_specs,
               runtime_obligations: runtime_obligations
             }
           } = ElmUi.Examples.metadata(:native_styling)

    assert artifact_names.preview == "elm_ui.examples.native_styling.preview"
    assert artifact_names.inspection == "elm_ui.examples.native_styling.inspection"
    assert artifact_names.export == "elm_ui.examples.native_styling.export"
    assert :native_widgets in package_specs
    assert :direct_native_reviewable in runtime_obligations
  end

  test "coverage matrix groups workflows and parity obligations deterministically" do
    assert %{
             categories: %{mixed: mixed_ids, native: native_ids, canonical: canonical_ids},
             workflows: %{styling: styling_ids},
             parity_groups: %{styling_review: styling_group}
           } = ElmUi.Examples.coverage_matrix()

    assert Enum.sort(mixed_ids) == [
             :advanced_continuity,
             :foundational_continuity,
             :mixed_transport,
             :navigation_continuity,
             :styling_continuity
           ]

    assert Enum.sort(native_ids) == [
             :native_advanced,
             :native_counter,
             :native_foundational,
             :native_navigation,
             :native_styling,
             :native_transport
           ]

    assert Enum.sort(canonical_ids) == [
             :canonical_advanced,
             :canonical_foundational,
             :canonical_navigation,
             :canonical_styling,
             :canonical_transport,
             :canonical_welcome
           ]

    assert Enum.sort(styling_ids) == [
             :canonical_styling,
             :native_styling,
             :styling_continuity
           ]

    assert Enum.sort(styling_group) == [
             :canonical_styling,
             :native_styling,
             :styling_continuity
           ]
  end

  test "native and canonical foundational examples stay aligned through the continuity artifact" do
    comparison = ElmUi.Examples.foundational_comparison()

    assert comparison.continuity.widget_kinds_match?
    assert comparison.continuity.render_tags_match?
    assert "workspace-layout" in comparison.continuity.shared_ids
    assert "query-input" in comparison.continuity.shared_ids
  end

  test "native and canonical advanced examples stay aligned through the continuity artifact" do
    comparison = ElmUi.Examples.advanced_comparison()

    assert comparison.continuity.widget_kinds_match?
    assert comparison.continuity.render_tags_match?
    assert comparison.continuity.display_kinds_match?
    assert comparison.continuity.layer_kinds_match?
    assert "advanced-operations" in comparison.continuity.shared_ids
    assert "inspect-dialog" in comparison.continuity.shared_ids
  end

  test "canonical foundational example renders through the package runtime" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(ElmUi.Examples.canonical_foundational_screen())

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert runtime_state.boundary_mode == :canonical_boundary
    assert runtime_state.screen_id == "workspace-layout"

    assert Enum.any?(model.tree.slots, fn slot ->
             Enum.any?(slot.children, &(&1.id == "workspace-header"))
           end)
  end

  test "canonical advanced example renders through the advanced package runtime" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(ElmUi.Examples.canonical_advanced_screen())

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert runtime_state.boundary_mode == :canonical_boundary
    assert runtime_state.screen_id == "advanced-operations"

    assert Enum.any?(model.tree.slots, fn slot ->
             Enum.any?(slot.children, &(&1.id == "operations-overlay"))
           end)
  end

  test "mixed transport example compares local native flow and canonical boundary flow" do
    comparison = ElmUi.Examples.mixed_transport_comparison()

    assert comparison.native.boundary == :local
    assert comparison.native.mode == :local
    assert comparison.native.frontend_scope == :local_feedback

    assert comparison.canonical.boundary == :boundary
    assert comparison.canonical.mode == :boundary
    assert comparison.canonical.frontend_scope == :pending_server_sync
    assert comparison.canonical.signal_type == "elm_ui.submit.save_workspace"

    assert comparison.continuity.same_family?
    assert comparison.continuity.same_intent?
    assert comparison.continuity.local_and_boundary_paths_diverge?
    assert comparison.continuity.server_authority_preserved?
  end

  test "navigation comparison keeps authoritative server transitions and frontend coordination aligned" do
    comparison = ElmUi.Examples.navigation_comparison()

    assert comparison.native.after_navigate.screen_id == "settings"
    assert comparison.native.after_navigate.frontend_screen_id == "settings"
    assert comparison.native.after_modal.navigation.current_modal.modal == :settings_dialog

    assert comparison.native.after_second_modal.navigation.current_modal.modal ==
             :settings_confirm_dialog

    assert Enum.map(comparison.native.after_second_modal.navigation.modals, & &1.modal) == [
             :settings_dialog,
             :settings_confirm_dialog
           ]

    assert comparison.native.after_top_close.navigation.current_modal.modal == :settings_dialog
    assert comparison.native.after_replace.screen_id == "home"

    assert comparison.canonical.after_navigate.screen_id == "settings"
    assert comparison.canonical.after_navigate.frontend_screen_id == "settings"

    assert comparison.canonical.after_second_modal.navigation.current_modal.modal ==
             :settings_confirm_dialog

    assert comparison.canonical.after_top_close.navigation.current_modal.modal == :settings_dialog
    assert comparison.canonical.after_replace.screen_id == "home"

    assert comparison.continuity.same_navigation_target?
    assert comparison.continuity.frontend_coordination?
    assert comparison.continuity.same_modal_identifier?
    assert comparison.continuity.same_second_modal_identifier?
    assert comparison.continuity.top_close_restores_previous_modal?
    assert comparison.continuity.modal_stack_reflected?
    assert comparison.continuity.same_replacement_target?
    assert comparison.continuity.host_route_externalized?
    assert comparison.continuity.server_authority_preserved?

    assert comparison.host_route_fixture.host_application.phoenix_route.path ==
             "/workspace/settings"
  end

  test "styling comparison exposes side-by-side resolved style and browser realization artifacts" do
    comparison = ElmUi.Examples.styling_comparison()

    assert comparison.continuity.validation.status == :pass
    assert comparison.continuity.theme_propagation_match?
    assert comparison.continuity.style_resolution_match?
    assert comparison.continuity.frontend_realization_match?

    assert Enum.any?(comparison.review_artifact.server.native, fn node ->
             node.id == "primary-action" and node.resolved_styles.background == :accent_tint
           end)

    assert Enum.any?(comparison.review_artifact.frontend.native, fn node ->
             node.id == "style-query" and "is-focused" in node.browser_style.class_tokens
           end)

    assert Enum.any?(comparison.review_artifact.frontend.canonical, fn node ->
             node.id == "style-query" and "is-focused" in node.browser_style.class_tokens
           end)

    assert comparison.review_artifact.continuity.shared_ids == [
             "styling-title",
             "style-query",
             "primary-action",
             "style-inspector"
           ]
  end
end
