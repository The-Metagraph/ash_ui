defmodule AshUI.Resource.FileTreeBrowserTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  describe "file_tree_browser authoring admission" do
    test "admits file_tree_browser as a canonical baseline widget type" do
      assert Storage.valid_widget_type?("file_tree_browser")
      assert Storage.canonical_widget_type(:file_tree_browser) == {:ok, "file_tree_browser"}

      definition = %{
        type: :file_tree_browser,
        props: %{tree_id: "workspace-tree", nodes: []}
      }

      assert Authoring.validate_element_definition!(definition) == definition
    end

    test "allows list bindings and semantic selection or toggle actions" do
      definition = %{type: :file_tree_browser, props: %{tree_id: "workspace-tree"}}

      binding = %{
        id: :visible_files,
        binding_type: :list,
        source: %{resource: "Demo.FileNode", action: "list"},
        target: "nodes"
      }

      actions = [
        %{
          id: :select_file,
          signal: :change,
          source: %{resource: "Demo.FileNode", action: "select"},
          target: "selected_path"
        },
        %{
          id: :toggle_folder,
          signal: :toggle,
          source: %{resource: "Demo.FileNode", action: "toggle"},
          target: "expanded_paths"
        }
      ]

      assert :ok = Authoring.validate_element_authority!(definition, [binding], actions)
    end
  end
end
