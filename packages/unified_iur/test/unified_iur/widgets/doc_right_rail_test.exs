defmodule UnifiedIUR.Widgets.DocRightRailTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Components

  describe "doc_right_rail/1 — positive cases" do
    test "builds element with required attrs and defaults" do
      element = Components.doc_right_rail(doc_id: "doc-1", on_tab_change: "tab_changed")

      assert %Element{kind: :doc_right_rail} = element

      assert element.attributes.component == %{
               family: :layer_shell_and_callout,
               kind: :doc_right_rail
             }

      assert element.attributes.rail.doc_id == "doc-1"
      assert element.attributes.rail.on_tab_change == "tab_changed"
      assert element.attributes.rail.active_tab == :sources
      assert element.attributes.rail.position == :fixed_right
      assert element.attributes.rail.collapsed? == false
      assert element.attributes.rail.width_variant == :standard
    end

    test "builds element with default three-tab strip when :tabs not supplied" do
      element = Components.doc_right_rail(doc_id: "doc-1", on_tab_change: "tab_changed")

      assert [
               %{kind: :agents, label: "Agents", count: nil},
               %{kind: :sources, label: "Sources", count: nil},
               %{kind: :history, label: "History", count: nil}
             ] = element.attributes.rail.tabs
    end

    test "accepts custom :active_tab" do
      element =
        Components.doc_right_rail(
          doc_id: "doc-abc",
          on_tab_change: "rail_tab",
          active_tab: :agents
        )

      assert element.attributes.rail.active_tab == :agents
    end

    test "accepts :collapsed? flag" do
      element =
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", collapsed?: true)

      assert element.attributes.rail.collapsed? == true
    end

    test "accepts :width_variant options" do
      for variant <- [:compact, :standard, :wide] do
        element =
          Components.doc_right_rail(
            doc_id: "d",
            on_tab_change: "t",
            width_variant: variant
          )

        assert element.attributes.rail.width_variant == variant
      end
    end

    test "accepts :position options" do
      for position <- [:fixed_right, :sticky_top, :inline] do
        element =
          Components.doc_right_rail(doc_id: "d", on_tab_change: "t", position: position)

        assert element.attributes.rail.position == position
      end
    end

    test "accepts caller-supplied :tabs list with count" do
      tabs = [
        %{kind: :agents, label: "Agents", count: 3},
        %{kind: :sources, label: "Sources", count: nil}
      ]

      element = Components.doc_right_rail(doc_id: "doc-1", on_tab_change: "t", tabs: tabs)

      assert length(element.attributes.rail.tabs) == 2
      assert hd(element.attributes.rail.tabs).count == 3
    end

    test "accepts up to 6 tabs" do
      tabs =
        Enum.map(1..6, fn i ->
          %{kind: :"tab_#{i}", label: "Tab #{i}", count: nil}
        end)

      element = Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: tabs)
      assert length(element.attributes.rail.tabs) == 6
    end

    test "is included in layer_callout_kinds" do
      assert :doc_right_rail in Components.layer_callout_kinds()
    end
  end

  describe "doc_right_rail/1 — negative cases" do
    test "raises when :doc_id is missing" do
      assert_raise ArgumentError, ~r/:doc_id/, fn ->
        Components.doc_right_rail(on_tab_change: "t")
      end
    end

    test "raises when :doc_id is an empty string" do
      assert_raise ArgumentError, ~r/:doc_id/, fn ->
        Components.doc_right_rail(doc_id: "", on_tab_change: "t")
      end
    end

    test "raises when :on_tab_change is missing" do
      assert_raise ArgumentError, ~r/:on_tab_change/, fn ->
        Components.doc_right_rail(doc_id: "d")
      end
    end

    test "raises when :active_tab is not a valid atom" do
      assert_raise ArgumentError, ~r/:active_tab/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", active_tab: :unknown)
      end
    end

    test "raises when :tabs is an empty list" do
      assert_raise ArgumentError, ~r/:tabs/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: [])
      end
    end

    test "raises when :tabs has more than 6 entries" do
      tabs = Enum.map(1..7, fn i -> %{kind: :"t#{i}", label: "T#{i}", count: nil} end)

      assert_raise ArgumentError, ~r/:tabs/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: tabs)
      end
    end

    test "raises when a :tabs entry is missing :kind" do
      tabs = [%{label: "No Kind", count: nil}]

      assert_raise ArgumentError, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: tabs)
      end
    end

    test "raises when a :tabs entry is missing :label" do
      tabs = [%{kind: :agents, count: nil}]

      assert_raise ArgumentError, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: tabs)
      end
    end

    test "raises when a :tabs entry has a negative :count" do
      tabs = [%{kind: :agents, label: "Agents", count: -1}]

      assert_raise ArgumentError, ~r/:count/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", tabs: tabs)
      end
    end

    test "raises when :position is not a valid atom" do
      assert_raise ArgumentError, ~r/:position/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", position: :floating)
      end
    end

    test "raises when :width_variant is not a valid atom" do
      assert_raise ArgumentError, ~r/:width_variant/, fn ->
        Components.doc_right_rail(doc_id: "d", on_tab_change: "t", width_variant: :extra_wide)
      end
    end
  end

  describe "catalog (IUR-side via layer_callout_kinds)" do
    test "doc_right_rail is included in layer_callout_kinds" do
      assert :doc_right_rail in Components.layer_callout_kinds()
    end

    test "doc_right_rail is included in the full kinds/0 list" do
      assert :doc_right_rail in Components.kinds()
    end
  end
end
