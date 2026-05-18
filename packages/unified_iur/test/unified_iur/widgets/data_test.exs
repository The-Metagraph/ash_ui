defmodule UnifiedIUR.Widgets.DataTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Data

  test "builds list, table, tree, and semantic data structures with stable item semantics" do
    list =
      Data.list(
        [
          [id: :a, label: "Alpha", value: :alpha, selected?: true],
          [id: :b, label: "Beta", value: :beta]
        ],
        id: "artifact-list"
      )

    table =
      Data.table(
        [
          [id: :name, label: "Name"],
          [id: :status, label: "Status", align: :center]
        ],
        [
          [id: "row-1", cells: ["Spec", "Ready"], selected?: true],
          [id: "row-2", cells: ["Tests", "Queued"]]
        ],
        id: "artifact-table",
        dense?: true
      )

    tree =
      Data.tree_view(
        [
          [
            id: :root,
            label: "Root",
            expanded?: true,
            children: [
              [id: :child, label: "Child", selected?: true]
            ]
          ]
        ],
        id: "artifact-tree"
      )

    stat =
      Data.stat(
        id: "artifact-stat",
        title: "Artifacts shipped",
        value: "24",
        message: "Across the current release train"
      )

    key_value =
      Data.key_value("Owner", "Docs team",
        id: "owner-pair",
        description: "Maintaining semantic widget coverage"
      )

    info_list =
      Data.info_list(
        [
          [
            id: :semantic,
            title: "Semantic widgets",
            value: "In progress",
            description: "Adding badge, hero, stat, key_value, and info_list",
            icon: :sparkles,
            status: :active
          ]
        ],
        id: "semantic-list",
        ordered?: true,
        empty_state: "No semantic notes"
      )

    assert %Element{
             kind: :list,
             attributes: %{
               list: %{
                 ordered?: false,
                 selection_mode: :single,
                 items: [
                   %{id: :a, label: "Alpha", value: :alpha, selected?: true},
                   %{id: :b, label: "Beta", value: :beta}
                 ]
               }
             }
           } = list

    assert %Element{
             kind: :table,
             attributes: %{
               table: %{
                 dense?: true,
                 columns: [
                   %{id: :name, label: "Name"},
                   %{id: :status, label: "Status", align: :center}
                 ],
                 rows: [
                   %{id: "row-1", cells: ["Spec", "Ready"], selected?: true},
                   %{id: "row-2", cells: ["Tests", "Queued"]}
                 ]
               }
             }
           } = table

    assert %Element{
             kind: :tree_view,
             attributes: %{
               tree: %{
                 selection_mode: :single,
                 nodes: [
                   %{
                     id: :root,
                     label: "Root",
                     expanded?: true,
                     children: [
                       %{id: :child, label: "Child", selected?: true}
                     ]
                   }
                 ]
               }
             }
           } = tree

    # generic node without explicit kind preserves backward compat
    assert [%{id: :root, label: "Root"}] =
             get_in(tree.attributes, [:tree, :nodes])

    assert %Element{
             kind: :stat,
             attributes: %{
               stat: %{
                 title: "Artifacts shipped",
                 value: "24",
                 message: "Across the current release train"
               }
             }
           } = stat

    assert %Element{
             kind: :key_value,
             attributes: %{
               key_value: %{
                 label: "Owner",
                 value: "Docs team",
                 description: "Maintaining semantic widget coverage"
               }
             }
           } = key_value

    assert %Element{
             kind: :info_list,
             attributes: %{
               info_list: %{
                 ordered?: true,
                 empty_state: "No semantic notes",
                 items: [
                   %{
                     id: :semantic,
                     title: "Semantic widgets",
                     value: "In progress",
                     description: "Adding badge, hero, stat, key_value, and info_list",
                     icon: :sparkles,
                     status: :active
                   }
                 ]
               }
             }
           } = info_list
  end

  describe "tree_view :sub_group node kind (Wave 3.7 EX-1)" do
    test "normalizes sub_group nodes with kind, label, and expanded state" do
      tree =
        Data.tree_view(
          [
            [
              id: "group-adr",
              kind: :sub_group,
              label: "ADRs",
              expanded?: true,
              children: [
                [id: "adr-1", label: "0001-connector-boundary"]
              ]
            ]
          ],
          id: "explorer-tree"
        )

      assert %Element{kind: :tree_view} = tree
      [group] = get_in(tree.attributes, [:tree, :nodes])
      assert group.kind == :sub_group
      assert group.label == "ADRs"
      assert group.expanded? == true
      assert [%{id: "adr-1", label: "0001-connector-boundary"}] = group.children
    end

    test "normalizes sub_group without children" do
      tree =
        Data.tree_view(
          [[id: "empty-group", kind: :sub_group, label: "Specs"]],
          id: "tree-empty-group"
        )

      [group] = get_in(tree.attributes, [:tree, :nodes])
      assert group.kind == :sub_group
      assert group.label == "Specs"
      assert is_nil(group[:children])
    end

    test "sub_group children are recursively normalized" do
      tree =
        Data.tree_view(
          [
            [
              id: "outer",
              kind: :sub_group,
              label: "Outer",
              children: [
                [
                  id: "inner",
                  kind: :sub_group,
                  label: "Inner",
                  children: [[id: "leaf", label: "Leaf"]]
                ]
              ]
            ]
          ],
          id: "nested-sub-group-tree"
        )

      [outer] = get_in(tree.attributes, [:tree, :nodes])
      assert outer.kind == :sub_group
      [inner] = outer.children
      assert inner.kind == :sub_group
      [leaf] = inner.children
      assert leaf.label == "Leaf"
    end
  end

  describe "tree_view :file_leaf node kind (Wave 3.7 EX-2)" do
    test "normalizes file_leaf with explicit path, name, and glyph" do
      tree =
        Data.tree_view(
          [
            [
              id: "file-1",
              kind: :file_leaf,
              path: "lib/ariston_ui/workspace.ex",
              name: "workspace.ex",
              glyph: "elixir"
            ]
          ],
          id: "file-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.kind == :file_leaf
      assert leaf.path == "lib/ariston_ui/workspace.ex"
      assert leaf.name == "workspace.ex"
      assert leaf.glyph == "elixir"
    end

    test "file_leaf derives glyph from .ex extension when glyph not provided" do
      tree =
        Data.tree_view(
          [[id: "f1", kind: :file_leaf, path: "lib/foo.ex", name: "foo.ex"]],
          id: "glyph-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.glyph == "elixir"
    end

    test "file_leaf derives glyph from .exs extension" do
      tree =
        Data.tree_view(
          [[id: "f2", kind: :file_leaf, path: "test/foo_test.exs", name: "foo_test.exs"]],
          id: "exs-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.glyph == "elixir"
    end

    test "file_leaf derives glyph from .md extension" do
      tree =
        Data.tree_view(
          [[id: "f3", kind: :file_leaf, path: "README.md", name: "README.md"]],
          id: "md-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.glyph == "markdown"
    end

    test "file_leaf explicit glyph wins over extension-derived glyph" do
      tree =
        Data.tree_view(
          [
            [
              id: "f4",
              kind: :file_leaf,
              path: "lib/foo.ex",
              name: "foo.ex",
              glyph: "custom-icon"
            ]
          ],
          id: "override-glyph-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.glyph == "custom-icon"
    end

    test "file_leaf glyph is absent for unknown extension (maybe_put skips nil)" do
      tree =
        Data.tree_view(
          [[id: "f5", kind: :file_leaf, path: "data.bin", name: "data.bin"]],
          id: "unknown-ext-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      # maybe_put skips nil values so :glyph key is absent — use Map.get to check
      assert is_nil(Map.get(leaf, :glyph))
    end

    test "file_leaf preserves selected? state" do
      tree =
        Data.tree_view(
          [[id: "f6", kind: :file_leaf, path: "lib/x.ex", name: "x.ex", selected?: true]],
          id: "selected-leaf-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.selected? == true
    end

    test "file_leaf accepts optional meta map" do
      tree =
        Data.tree_view(
          [
            [
              id: "f7",
              kind: :file_leaf,
              path: "lib/x.ex",
              name: "x.ex",
              meta: %{lang: "elixir", lines: 120}
            ]
          ],
          id: "meta-leaf-tree"
        )

      [leaf] = get_in(tree.attributes, [:tree, :nodes])
      assert leaf.meta == %{lang: "elixir", lines: 120}
    end
  end

  describe "tree_view mixed-kind nodes" do
    test "tree with generic root containing sub_group and file_leaf children" do
      tree =
        Data.tree_view(
          [
            [
              id: "repo-root",
              label: "metagraph/",
              expanded?: true,
              children: [
                [
                  id: "specs-group",
                  kind: :sub_group,
                  label: "Specs",
                  children: [
                    [
                      id: "spec-file",
                      kind: :file_leaf,
                      path: ".spec/specs/grain.spec.md",
                      name: "grain.spec.md"
                    ]
                  ]
                ]
              ]
            ]
          ],
          id: "mixed-tree"
        )

      [root] = get_in(tree.attributes, [:tree, :nodes])
      # root has no kind (generic)
      assert is_nil(root[:kind])
      assert root.label == "metagraph/"

      [sub_group] = root.children
      assert sub_group.kind == :sub_group

      [file_leaf] = sub_group.children
      assert file_leaf.kind == :file_leaf
      assert file_leaf.glyph == "markdown"
    end
  end
end
