defmodule ElmUi.FakeWidget do
  defstruct [:id]
end

defmodule UnifiedIUR.CoreInvariantTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Core.Invariant
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Tree

  test "accepts canonical element trees" do
    tree =
      Element.new(:layout, :stack,
        id: "root",
        children: [Child.new(:content, Element.new(:widget, :button, id: "child"))]
      )

    assert tree == Invariant.assert_canonical_element!(tree)
    assert Invariant.canonical_element?(tree)
  end

  test "rejects runtime-library-native structs in canonical core values" do
    tree =
      Element.new(:widget, :button,
        id: "button",
        attributes: %{runtime_widget: %ElmUi.FakeWidget{id: "native"}}
      )

    assert_raise ArgumentError,
                 "runtime-library-native structs are not allowed in canonical core values",
                 fn ->
                   Invariant.assert_canonical_element!(tree)
                 end
  end

  test "detects unexpected tree-shape changes while preserving original values" do
    original =
      Element.new(:layout, :box,
        id: "root",
        children: [Child.new(:content, Element.new(:widget, :label, id: "child"))]
      )

    stable =
      Tree.map(original, fn element ->
        Element.put_attribute(element, :seen, true)
      end)

    changed_shape =
      Element.put_children(original, [
        Child.new(:header, Element.new(:widget, :label, id: "child")),
        Child.empty(:footer)
      ])

    assert :ok = Invariant.assert_shape_stable!(original, stable)

    assert_raise ArgumentError, "canonical tree shape changed unexpectedly", fn ->
      Invariant.assert_shape_stable!(original, changed_shape)
    end

    assert %{seen: true} = Tree.find_by_id(stable, "child").attributes
    assert %{} == Tree.find_by_id(original, "child").attributes
  end
end
