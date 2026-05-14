defmodule DesktopUi.FakeWidget do
  defstruct [:id]
end

defmodule UnifiedIUR.Phase1IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Core.Invariant
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Reference
  alias UnifiedIUR.Tree

  test "phase 1 core tree scenarios preserve identity, metadata, child shape, and immutable transforms" do
    save_button =
      Element.new(:widget, :button,
        id: "save-button",
        metadata: [description: "Primary action", annotations: [intent: "save"], tags: [:primary]],
        attributes: [label: "Save"]
      )

    cancel_button =
      Element.new(:widget, :button,
        id: "cancel-button",
        metadata: [description: "Cancel action"],
        attributes: [label: "Cancel"]
      )

    form =
      Element.new(:composite, :form,
        id: "settings-form",
        metadata: [description: "Settings editor", annotations: [source: "phase-1"]],
        children: [
          Child.new(
            :actions,
            Element.new(:layout, :stack,
              id: "action-stack",
              children: [
                Child.new(:primary, save_button),
                Child.new(:secondary, cancel_button),
                Child.empty(:footer)
              ]
            )
          )
        ]
      )

    root =
      Element.new(:layout, :box,
        id: "root-shell",
        metadata: [description: "Root shell", tags: [:screen]],
        children: [Child.new(:content, form)]
      )

    assert ["root-shell", "settings-form", "action-stack", "save-button", "cancel-button"] ==
             Enum.map(Tree.depth_first(root), & &1.id)

    assert :single == Element.child_shape(root)
    assert :single == Element.child_shape(form)
    assert :multi == Element.child_shape(Tree.find_by_id(root, "action-stack"))

    assert %Element{
             type: :widget,
             metadata: %{description: "Primary action", annotations: %{intent: "save"}}
           } = Tree.find_by_id(root, "save-button")

    updated =
      Tree.update(root, "save-button", fn element ->
        Element.put_attribute(element, :label, "Save changes")
      end)

    assert %{label: "Save"} = Tree.find_by_id(root, "save-button").attributes
    assert %{label: "Save changes"} = Tree.find_by_id(updated, "save-button").attributes
    assert :ok = Invariant.assert_shape_stable!(root, updated)

    assert %{total_elements: 5, type_histogram: %{layout: 2, composite: 1, widget: 2}} =
             Reference.summarize_tree(updated)
  end

  test "phase 1 package purity and reference scenarios work without runtime infrastructure" do
    assert Application.load(:unified_iur) in [:ok, {:error, {:already_loaded, :unified_iur}}]
    assert Application.spec(:unified_iur, :mod) in [nil, []]

    assert {:ok, UnifiedIUR.Core} = UnifiedIUR.module_for(:core)
    assert {:ok, UnifiedIUR.Reference} = UnifiedIUR.module_for(:reference)

    assert [:widget, :layout, :layer, :style, :theme, :interaction, :composite] ==
             Reference.construct_families()

    assert %{
             identity_fields: [:id, :type, :kind],
             metadata_fields: [:authored_ref, :description, :annotations, :tags, :extra]
           } = Reference.identity_metadata_shape()

    assert %{
             child_shapes: [:leaf, :single, :multi],
             child_wrapper: UnifiedIUR.Element.Child
           } = Reference.tree_shape_conventions()
  end

  test "phase 1 purity invariants reject runtime-library-native structs from canonical trees" do
    invalid_tree =
      Element.new(:layout, :box,
        id: "root",
        children: [
          Child.new(
            :content,
            Element.new(:widget, :button,
              id: "button",
              attributes: %{native: %DesktopUi.FakeWidget{id: "native-button"}}
            )
          )
        ]
      )

    assert_raise ArgumentError,
                 "runtime-library-native structs are not allowed in canonical core values",
                 fn ->
                   Invariant.assert_canonical_element!(invalid_tree)
                 end
  end
end
