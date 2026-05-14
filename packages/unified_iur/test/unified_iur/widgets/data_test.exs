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
end
