defmodule LiveUi.Widgets.FileTreeBrowserTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.FileTreeBrowser

  @nodes [
    %{
      id: "lib",
      type: :folder,
      path: "lib",
      expanded?: true,
      children: [
        %{
          id: "lib/app.ex",
          type: :file_leaf,
          path: "lib/app.ex",
          language: "elixir",
          line_count: 42,
          select_attrs: %{"phx-click" => "canonical_interaction"}
        }
      ]
    }
  ]

  test "widget metadata has the navigation family and canonical events" do
    metadata = LiveUi.Component.metadata(FileTreeBrowser)

    assert metadata.family == :navigation
    assert metadata.name == :file_tree_browser
    assert :selection in metadata.events
    assert :change in metadata.events
    assert metadata.mountable?
  end

  test "is exposed through the navigation widget family" do
    assert FileTreeBrowser in LiveUi.Widgets.navigation_modules()
    assert FileTreeBrowser in LiveUi.Widgets.modules()
  end

  test "renders folders, files, selected state, and caller-supplied canonical attrs" do
    html =
      render_component(&FileTreeBrowser.component/1, %{
        id: "workspace-files",
        tree_id: "workspace-tree",
        root_label: "Workspace files",
        nodes: @nodes,
        selected_path: "lib/app.ex"
      })

    assert html =~ ~s(data-live-ui-widget="file-tree-browser")
    assert html =~ ~s(data-tree-id="workspace-tree")
    assert html =~ ~s(role="tree")
    assert html =~ ~s(aria-label="Workspace files")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ "lib/"
    assert html =~ "app.ex"
    assert html =~ "elixir"
    assert html =~ "42 lines"
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(phx-click="canonical_interaction")
  end
end
