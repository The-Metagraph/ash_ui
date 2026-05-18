defmodule LiveUi.DataWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for data and document widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "list widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.List)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.List.Component
      assert metadata.family == :data
      assert metadata.name == :list
    end

    test "list component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.List.component/1, %{
          id: "test-list",
          items: [
            %{id: "item-1", label: "Item 1"},
            %{id: "item-2", label: "Item 2"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end

    test "list component supports ordered mode" do
      html =
        render_component(&LiveUi.Widgets.List.component/1, %{
          id: "ordered-list",
          items: [
            %{id: "item-1", label: "First"},
            %{id: "item-2", label: "Second"}
          ],
          ordered: true
        })

      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ "<ol>"
      assert html =~ "First"
    end

    test "list component supports selection mode" do
      html =
        render_component(&LiveUi.Widgets.List.component/1, %{
          id: "selectable-list",
          items: [],
          selection_mode: "multiple"
        })

      assert html =~ ~s(data-live-ui-selection-mode="multiple")
    end
  end

  describe "table widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Table)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Table.Component
      assert metadata.family == :data
      assert metadata.name == :table
    end

    test "table component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Table.component/1, %{
          id: "test-table",
          columns: [
            %{id: "col-1", label: "Name"},
            %{id: "col-2", label: "Value"}
          ],
          rows: [
            %{id: "row-1", cells: ["Alice", "100"]},
            %{id: "row-2", cells: ["Bob", "200"]}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="table")
      assert html =~ "Name"
      assert html =~ "Value"
      assert html =~ "Alice"
      assert html =~ "Bob"
    end

    test "table component supports dense mode" do
      html =
        render_component(&LiveUi.Widgets.Table.component/1, %{
          id: "dense-table",
          columns: [],
          rows: [],
          dense: true
        })

      assert html =~ ~s(data-live-ui-dense)
    end

    test "table component supports row selection" do
      html =
        render_component(&LiveUi.Widgets.Table.component/1, %{
          id: "selectable-table",
          columns: [],
          rows: [
            %{id: "row-1", cells: ["Data"], selected: true}
          ]
        })

      assert html =~ ~s(data-selected)
    end
  end

  describe "tree_view widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.TreeView)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.TreeView.Component
      assert metadata.family == :data
      assert metadata.name == :tree_view
    end

    test "tree_view component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "test-tree",
          nodes: [
            %{id: "node-1", label: "Root"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="tree_view")
      assert html =~ "Root"
    end

    test "tree_view component supports nested nodes" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "nested-tree",
          nodes: [
            %{
              id: "parent",
              label: "Parent",
              children: [
                %{id: "child-1", label: "Child 1"},
                %{id: "child-2", label: "Child 2"}
              ]
            }
          ]
        })

      assert html =~ "Parent"
      assert html =~ "Child 1"
      assert html =~ "Child 2"
    end

    test "tree_view component supports selection mode" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "selectable-tree",
          nodes: [],
          selection_mode: "single"
        })

      assert html =~ ~s(data-live-ui-selection-mode="single")
    end

    test "tree_view component supports node expansion state" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "expandable-tree",
          nodes: [
            %{id: "expanded-node", label: "Expanded", expanded: true}
          ]
        })

      assert html =~ ~s(data-expanded)
    end

    test "tree_view :sub_group node renders with role=group and aria-label (Wave 3.7 EX-1)" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "sub-group-tree",
          nodes: [
            %{id: "group-adr", kind: :sub_group, label: "ADRs", expanded?: true}
          ]
        })

      assert html =~ ~s(data-node-kind="sub_group")
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="ADRs")
      assert html =~ "ADRs"
    end

    test "tree_view :sub_group node renders nested children" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "sub-group-nested",
          nodes: [
            %{
              id: "group-specs",
              kind: :sub_group,
              label: "Specs",
              children: [%{id: "child-spec", label: "grain.spec.md"}]
            }
          ]
        })

      assert html =~ "Specs"
      assert html =~ "grain.spec.md"
    end

    test "tree_view :file_leaf node renders with file path and glyph (Wave 3.7 EX-2)" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "file-leaf-tree",
          nodes: [
            %{
              id: "f1",
              kind: :file_leaf,
              path: "lib/foo.ex",
              name: "foo.ex",
              glyph: "elixir"
            }
          ]
        })

      assert html =~ ~s(data-node-kind="file_leaf")
      assert html =~ ~s(data-file-path="lib/foo.ex")
      assert html =~ ~s(data-glyph="elixir")
      assert html =~ ~s(aria-label="File: foo.ex")
      assert html =~ "foo.ex"
    end

    test "tree_view :file_leaf node selected state reflects data-selected" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "selected-file-tree",
          nodes: [
            %{
              id: "f2",
              kind: :file_leaf,
              path: "lib/bar.ex",
              name: "bar.ex",
              selected: true
            }
          ]
        })

      assert html =~ ~s(data-selected)
    end

    test "tree_view mixed sub_group and file_leaf in same tree" do
      html =
        render_component(&LiveUi.Widgets.TreeView.component/1, %{
          id: "mixed-tree",
          nodes: [
            %{
              id: "repo-root",
              label: "metagraph/",
              children: [
                %{
                  id: "specs-group",
                  kind: :sub_group,
                  label: "Specs",
                  children: [
                    %{
                      id: "spec-file",
                      kind: :file_leaf,
                      path: ".spec/specs/grain.spec.md",
                      name: "grain.spec.md",
                      glyph: "markdown"
                    }
                  ]
                }
              ]
            }
          ]
        })

      assert html =~ "metagraph/"
      assert html =~ ~s(data-node-kind="sub_group")
      assert html =~ ~s(role="group")
      assert html =~ "Specs"
      assert html =~ ~s(data-node-kind="file_leaf")
      assert html =~ ~s(data-glyph="markdown")
      assert html =~ "grain.spec.md"
    end
  end

  describe "markdown_viewer widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.MarkdownViewer)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.MarkdownViewer.Component
      assert metadata.family == :data
      assert metadata.name == :markdown_viewer
    end

    test "markdown_viewer component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.MarkdownViewer.component/1, %{
          id: "test-markdown",
          source: "# Heading\n\nParagraph text."
        })

      assert html =~ ~s(data-live-ui-widget-boundary="markdown_viewer")
      assert html =~ "Heading"
      assert html =~ "Paragraph text"
    end

    test "markdown_viewer renders markdown headings" do
      html =
        render_component(&LiveUi.Widgets.MarkdownViewer.component/1, %{
          id: "markdown-headings",
          source: "# H1\n## H2\n### H3"
        })

      assert html =~ "H1"
      assert html =~ "H2"
      assert html =~ "H3"
    end

    test "markdown_viewer renders markdown lists" do
      html =
        render_component(&LiveUi.Widgets.MarkdownViewer.component/1, %{
          id: "markdown-lists",
          source: "- Item 1\n- Item 2\n- Item 3"
        })

      assert html =~ "Item 1"
      assert html =~ "Item 2"
      assert html =~ "Item 3"
    end
  end

  describe "log_viewer widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.LogViewer)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.LogViewer.Component
      assert metadata.family == :data
      assert metadata.name == :log_viewer
    end

    test "log_viewer component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.LogViewer.component/1, %{
          id: "test-log",
          entries: [
            %{timestamp: "2024-01-01T12:00:00Z", level: "info", message: "Test log entry"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="log_viewer")
      assert html =~ "Test log entry"
    end

    test "log_viewer component supports multiple log levels" do
      html =
        render_component(&LiveUi.Widgets.LogViewer.component/1, %{
          id: "multi-level-log",
          entries: [
            %{timestamp: "2024-01-01T12:00:00Z", severity: "debug", message: "Debug message"},
            %{timestamp: "2024-01-01T12:00:01Z", severity: "info", message: "Info message"},
            %{timestamp: "2024-01-01T12:00:02Z", severity: "warn", message: "Warning message"},
            %{timestamp: "2024-01-01T12:00:03Z", severity: "error", message: "Error message"}
          ]
        })

      assert html =~ ~s(data-severity="debug")
      assert html =~ ~s(data-severity="info")
      assert html =~ ~s(data-severity="warn")
      assert html =~ ~s(data-severity="error")
    end

    test "log_viewer component supports wrap mode" do
      html =
        render_component(&LiveUi.Widgets.LogViewer.component/1, %{
          id: "wrapped-log",
          entries: [],
          wrap: true
        })

      assert html =~ ~s(data-live-ui-wrap)
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders for list" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.List),
          %{id: "stable-list"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.List),
          %{id: "stable-list"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:data:list:stable-list:root"
    end

    test "widget identity includes mode in key for table" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Table),
          %{id: "mode-table"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Table),
          %{id: "mode-table"},
          mode: :canonical
        )

      assert Identity.key(native_identity) == "native:data:table:mode-table:root"
      assert Identity.key(canonical_identity) == "canonical:data:table:mode-table:root"
    end
  end

  describe "event semantics preservation" do
    test "list has click and selection events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.List)

      assert :click in metadata.events
      assert :selection in metadata.events
    end

    test "table has click and selection events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Table)

      assert :click in metadata.events
      assert :selection in metadata.events
    end

    test "tree_view has click and selection events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.TreeView)

      assert :click in metadata.events
      assert :selection in metadata.events
    end
  end

  describe "bounded local state support" do
    test "data widgets support local_state_keys for bounded state" do
      list_metadata = Component.metadata(LiveUi.Widgets.List)
      table_metadata = Component.metadata(LiveUi.Widgets.Table)
      tree_view_metadata = Component.metadata(LiveUi.Widgets.TreeView)

      # Data widgets can have local_state_keys for bounded UI state
      # like selected items, expanded nodes, etc.
      assert is_list(list_metadata.local_state_keys)
      assert is_list(table_metadata.local_state_keys)
      assert is_list(tree_view_metadata.local_state_keys)
    end
  end
end
