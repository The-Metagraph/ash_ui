defmodule UnifiedIUR.Widgets.FileTreeBrowserTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Navigation

  describe "file_tree_browser/1" do
    test "builds a baseline navigation element with semantic tree attributes" do
      element =
        Navigation.file_tree_browser(
          id: "workspace-files",
          tree_id: "workspace-tree",
          root_label: "Workspace files",
          selected_path: "lib/app.ex",
          default_expanded?: false,
          selection_intent: :select_file,
          toggle_intent: :toggle_folder,
          nodes: [
            %{
              id: "lib",
              type: :folder,
              expanded?: true,
              children: [
                %{
                  id: "lib/app.ex",
                  type: :file_leaf,
                  language: "elixir",
                  line_count: 42
                }
              ]
            }
          ]
        )

      assert %Element{type: :widget, kind: :file_tree_browser} = element
      assert element.id == "workspace-files"

      assert element.attributes.file_tree == %{
               tree_id: "workspace-tree",
               root_label: "Workspace files",
               selected_path: "lib/app.ex",
               default_expanded?: false,
               selection_intent: :select_file,
               toggle_intent: :toggle_folder,
               nodes: [
                 %{
                   id: "lib",
                   type: :folder,
                   name: "lib",
                   path: "lib",
                   expanded?: true,
                   children: [
                     %{
                       id: "lib/app.ex",
                       type: :file_leaf,
                       name: "app.ex",
                       path: "lib/app.ex",
                       language: "elixir",
                       line_count: 42
                     }
                   ]
                 }
               ]
             }

      refute Map.has_key?(element.attributes, :component)
    end

    test "derives identity and accepts file aliases" do
      element =
        Navigation.file_tree_browser(
          tree_id: :files,
          nodes: [%{path: "README.md", type: :file, kind: "markdown", lines: 8}]
        )

      assert element.id == "files"

      assert get_in(element.attributes, [:file_tree, :nodes]) == [
               %{
                 id: "README.md",
                 type: :file_leaf,
                 name: "README.md",
                 path: "README.md",
                 file_kind: "markdown",
                 line_count: 8
               }
             ]
    end

    test "raises for malformed identity and node shape" do
      assert_raise ArgumentError, ~r/tree_id/, fn ->
        Navigation.file_tree_browser(nodes: [])
      end

      assert_raise ArgumentError, ~r/:selected_path/, fn ->
        Navigation.file_tree_browser(tree_id: "files", selected_path: :readme)
      end

      assert_raise ArgumentError, ~r/:nodes must be a list/, fn ->
        Navigation.file_tree_browser(tree_id: "files", nodes: %{path: "README.md"})
      end

      assert_raise ArgumentError, ~r/node type/, fn ->
        Navigation.file_tree_browser(
          tree_id: "files",
          nodes: [%{path: "README.md", type: :asset}]
        )
      end

      assert_raise ArgumentError, ~r/:line_count/, fn ->
        Navigation.file_tree_browser(
          tree_id: "files",
          nodes: [%{path: "README.md", type: :file_leaf, line_count: -1}]
        )
      end
    end
  end
end
