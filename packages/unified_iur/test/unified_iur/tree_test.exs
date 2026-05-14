defmodule UnifiedIUR.TreeTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Tree

  test "normalizes leaf, single-child, multi-child, and optional-empty slots" do
    leaf = Element.new(:widget, :label, id: "leaf")

    single =
      Element.new(:layout, :box,
        id: "single",
        children: [%{slot: :content, element: leaf}]
      )

    multi =
      Element.new(:layout, :stack,
        id: "multi",
        children: [
          Child.new(:header, Element.new(:widget, :label, id: "header")),
          Child.empty(:footer)
        ]
      )

    assert :leaf == Element.child_shape(leaf)
    assert :single == Element.child_shape(single)
    assert :multi == Element.child_shape(multi)

    assert [%Child{slot: :content, element: %Element{id: "leaf"}}] =
             Element.children_for_slot(single, :content)

    assert [%Child{slot: :footer, element: nil}] = Element.children_for_slot(multi, :footer)
  end

  test "supports depth-first and breadth-first traversal over canonical trees" do
    left = Element.new(:widget, :label, id: "left")
    right = Element.new(:widget, :button, id: "right")

    root =
      Element.new(:layout, :stack,
        id: "root",
        children: [
          Child.new(:primary, left),
          Child.new(:secondary, right)
        ]
      )

    assert ["root", "left", "right"] == Enum.map(Tree.depth_first(root), & &1.id)
    assert ["root", "left", "right"] == Enum.map(Tree.breadth_first(root), & &1.id)
  end

  test "updates and looks up elements immutably by id and type" do
    child = Element.new(:widget, :button, id: "child", attributes: [label: "Save"])

    root =
      Element.new(:layout, :box,
        id: "root",
        children: [Child.new(:content, child)]
      )

    updated =
      Tree.update(root, "child", fn element ->
        Element.put_attribute(element, :label, "Submit")
      end)

    assert %Element{attributes: %{label: "Save"}} = Tree.find_by_id(root, "child")
    assert %Element{attributes: %{label: "Submit"}} = Tree.find_by_id(updated, "child")
    assert [%Element{id: "root"}] = Tree.find_by_type(updated, :layout)
    assert [%Element{id: "child"}] = Tree.find_by_type(updated, :widget)
  end
end
