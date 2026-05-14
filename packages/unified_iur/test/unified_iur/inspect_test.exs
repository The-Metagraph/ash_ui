defmodule UnifiedIUR.InspectTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Fixtures, Inspect}
  alias UnifiedIUR.Widgets.Foundational

  test "builds maintainer-facing fixture inspection reports" do
    assert {:ok, report} = Inspect.fixture("foundational--workspace_chrome")

    assert report.fixture_id == "foundational--workspace_chrome"
    assert report.identity == %{id: "workspace-chrome", kind: :column, type: :layout}
    assert report.tree_summary.total_elements >= 7
    assert report.classification.layout?
    assert is_binary(report.render_tree)
    assert report.diagnostics.valid?
  end

  test "renders stable tree output for nested canonical fixtures" do
    fixture = Fixtures.fixture!("display--layered_workspace")

    assert Inspect.render_tree(fixture.element) =~ "- layered-workspace [layer:overlay]"
    assert Inspect.render_tree(fixture.element) =~ "@dialog"
    assert Inspect.render_tree(fixture.element) =~ "- preferences-dialog [layer:dialog]"
  end

  test "extracts styles, themes, interactions, and extension metadata" do
    styled_element =
      Foundational.button("Save",
        id: "styled-button",
        style: [foreground: :accent, spacing: %{padding: 1}],
        theme: :workspace
      )

    styles = Inspect.styles(styled_element)
    themes = Inspect.themes(styled_element)

    assert Enum.any?(styles, &(&1.id == "styled-button"))
    assert Enum.any?(themes, &(&1.id == "styled-button"))

    assert [%{family: :command, intent: :open_file}] =
             Inspect.interactions(Fixtures.fixture!("advanced--operations_center").element)

    assert %{
             extension_points: _,
             compatibility_rules: _,
             iur_catalog: _,
             unified_ui_family_map: _
           } =
             Inspect.extension_metadata()
  end

  test "inspects canonical navigation fixtures and surfaces navigation summaries" do
    assert {:ok, report} = Inspect.navigation_fixture("screen_transition--settings_profile")

    assert report.fixture_id == "screen_transition--settings_profile"
    assert report.intent == :open_settings_screen

    assert report.navigation == %{
             action: :navigate_to,
             kind: :screen_transition,
             params: %{tab: :profile},
             screen: :settings
           }

    assert report.target == %{navigation: report.navigation}
    assert "symbolic screen identifiers" in report.semantics

    assert {:ok, stack_report} = Inspect.navigation_fixture("modal_stack--open_confirm_dialog")

    assert stack_report.navigation.modal_stack == %{
             operation: :push,
             target: :symbolic_modal,
             target_required?: true,
             named_target_allowed?: true,
             containment_required?: false,
             stack_effect: :push_modal
           }
  end
end
