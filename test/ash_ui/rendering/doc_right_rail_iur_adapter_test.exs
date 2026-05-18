defmodule AshUI.Rendering.DocRightRailIURAdapterTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.IURAdapter

  @moduletag :conformance

  test "maps Ash doc_right_rail props into canonical rail attributes" do
    rail =
      IUR.new(:doc_right_rail,
        id: "doc-rail-test",
        props: %{
          doc_id: "doc-abc-123",
          on_tab_change: "tab_changed",
          active_tab: :agents,
          collapsed?: false,
          width_variant: :standard,
          position: :fixed_right,
          tabs: [
            %{kind: :agents, label: "Agents", count: 3},
            %{kind: :sources, label: "Sources", count: nil},
            %{kind: :history, label: "History", count: nil}
          ]
        }
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(rail)

    assert canonical.type == :widget
    assert canonical.kind == :doc_right_rail

    assert canonical.attributes.component == %{
             family: :layer_shell_and_callout,
             kind: :doc_right_rail
           }

    assert canonical.attributes.rail.doc_id == "doc-abc-123"
    assert canonical.attributes.rail.active_tab == :agents
    assert canonical.attributes.rail.on_tab_change == "tab_changed"
    assert canonical.attributes.rail.collapsed? == false
    assert canonical.attributes.rail.width_variant == :standard
    assert canonical.attributes.rail.position == :fixed_right
    assert length(canonical.attributes.rail.tabs) == 3
  end

  test "doc_right_rail defaults active_tab to :sources when not provided" do
    rail =
      IUR.new(:doc_right_rail,
        id: "doc-rail-defaults",
        props: %{
          doc_id: "doc-defaults",
          on_tab_change: "tab_changed"
        }
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(rail)
    assert canonical.attributes.rail.active_tab == :sources
  end

  test "doc_right_rail defaults collapsed? to false" do
    rail =
      IUR.new(:doc_right_rail,
        id: "doc-rail-collapse",
        props: %{
          doc_id: "doc-collapse",
          on_tab_change: "tab_changed"
        }
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(rail)
    assert canonical.attributes.rail.collapsed? == false
  end

  test "doc_right_rail preserves accessibility label" do
    rail =
      IUR.new(:doc_right_rail,
        id: "doc-rail-a11y",
        props: %{
          doc_id: "doc-a11y",
          on_tab_change: "tab_changed",
          accessibility_label: "Document companion panel"
        }
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(rail)
    assert canonical.attributes.accessibility.label == "Document companion panel"
  end
end
