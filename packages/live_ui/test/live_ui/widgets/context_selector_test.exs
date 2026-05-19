defmodule LiveUi.Widgets.ContextSelectorTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.ContextSelector

  @groups [
    %{
      id: "workspace",
      label: "Workspace",
      items: [
        %{value: "all", label: "All workspaces"},
        %{value: "active", label: "Active workspace", disabled?: true}
      ]
    }
  ]

  test "widget metadata has the navigation family and selection events" do
    metadata = LiveUi.Component.metadata(ContextSelector)

    assert metadata.family == :navigation
    assert metadata.name == :context_selector
    assert :selection in metadata.events
    assert :change in metadata.events
    assert metadata.mountable?
  end

  test "is exposed through the navigation widget family" do
    assert ContextSelector in LiveUi.Widgets.navigation_modules()
    assert ContextSelector in LiveUi.Widgets.modules()
  end

  test "renders a closed trigger without the listbox panel" do
    html =
      render_component(&ContextSelector.component/1, %{
        id: "workspace-context",
        selector_id: "workspace-context",
        groups: @groups,
        selected_values: [],
        open?: false
      })

    assert html =~ ~s(data-live-ui-widget="context-selector")
    assert html =~ ~s(data-selector-id="workspace-context")
    assert html =~ ~s(aria-haspopup="listbox")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ "Select context..."
    refute html =~ ~s(role="listbox")
  end

  test "renders grouped options with selection, multi-select, and item attrs" do
    html =
      render_component(&ContextSelector.component/1, %{
        id: "workspace-context",
        selector_id: "workspace-context",
        groups: [
          %{
            id: "workspace",
            label: "Workspace",
            items: [
              %{
                value: "all",
                label: "All workspaces",
                attrs: %{"phx-click" => "canonical_interaction"}
              },
              %{value: "active", label: "Active workspace"}
            ]
          }
        ],
        selected_values: ["all"],
        max_selections: :unlimited,
        open?: true
      })

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-multiselectable="true")
    assert html =~ ~s(role="group")
    assert html =~ "Workspace"
    assert html =~ "All workspaces"
    assert html =~ ~s(data-context-value="all")
    assert html =~ ~s(aria-selected="true")
    assert html =~ "is-selected"
    assert html =~ ~s(phx-click="canonical_interaction")
  end
end
