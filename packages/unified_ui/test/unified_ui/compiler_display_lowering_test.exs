defmodule UnifiedUi.CompilerDisplayLoweringTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Tree
  alias UnifiedUi.Compiler

  defmodule DisplayWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:display_workspace)
      title("Display Workspace")
      authored_ref([:tests, :display_workspace])
    end

    composition do
      root(:display_workspace_root)
      mode(:screen)

      box :scroll_content do
        text :scroll_copy do
          value("Scrollable details")
        end
      end

      box :secondary_panel do
        text :secondary_copy do
          value("Secondary panel")
        end
      end

      viewport :primary_viewport do
        content_ref(:scroll_content)
        width(72)
        height(16)
        offset({0, 6})
      end

      scroll_bar :primary_scroll do
        target_ref(:primary_viewport)
        position(6)
        viewport_size(16)
        content_size(96)
      end

      split_pane :workspace_split do
        primary_ref(:scroll_content)
        secondary_ref(:secondary_panel)
        ratio(0.4)
      end
    end
  end

  test "lowers display references into canonical child slots and viewport references" do
    iur = Compiler.iur!(DisplayWorkspace)

    viewport = Tree.find_by_id(iur, :primary_viewport)
    scroll_bar = Tree.find_by_id(iur, :primary_scroll)
    split_pane = Tree.find_by_id(iur, :workspace_split)

    assert Enum.map(viewport.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [{:content, :scroll_content, :box}]

    assert get_in(scroll_bar.attributes, [:scroll_bar, :viewport_ref]) == :primary_viewport

    assert Enum.map(split_pane.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [
             {:primary, :scroll_content, :box},
             {:secondary, :secondary_panel, :box}
           ]
  end
end
