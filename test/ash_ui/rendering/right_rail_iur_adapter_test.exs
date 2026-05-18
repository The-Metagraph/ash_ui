defmodule AshUI.Rendering.RightRailIURAdapterTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.IURAdapter

  @moduletag :conformance

  test "maps Ash right_rail props into canonical rail attributes" do
    rail =
      IUR.new(:right_rail,
        id: "workspace-rail",
        props: %{
          panels: [
            %{id: :summary, label: "Summary", content_slot: :summary_body},
            %{id: :activity, label: "Activity", badge: %{label: "2"}}
          ],
          active_panel: :activity,
          collapsed?: false,
          collapsible?: true,
          density: :compact,
          width: :wide,
          accessibility_label: "Workspace rail"
        },
        children: [
          IUR.new(:text,
            id: "summary-body",
            props: %{text: "Summary body"},
            metadata: %{composition: %{slot: :summary_body}}
          )
        ]
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(rail)

    assert canonical.type == :widget
    assert canonical.kind == :right_rail

    assert canonical.attributes.component == %{
             family: :layer_shell_and_callout,
             kind: :right_rail
           }

    assert canonical.attributes.rail == %{
             id: "workspace-rail",
             side: :right,
             panels: [
               %{id: :summary, label: "Summary", content_slot: :summary_body},
               %{id: :activity, label: "Activity", badge: %{label: "2"}}
             ],
             active_panel: :activity,
             collapsed?: false,
             collapsible?: true,
             density: :compact,
             width: :wide
           }

    assert canonical.attributes.accessibility == %{label: "Workspace rail"}
    assert [%{slot: :summary_body, element: %{kind: :text}}] = canonical.children
    assert :ok = UnifiedIUR.Validate.element(canonical)
  end

  test "invalid Ash right_rail payloads fail through Unified IUR validation" do
    rail =
      IUR.new(:right_rail,
        id: "workspace-rail",
        props: %{
          panels: [%{id: :summary, label: "Summary"}],
          active_panel: :missing
        }
      )

    assert {:error, {:conversion_failed, errors}} = IURAdapter.to_canonical(rail)
    assert Enum.any?(errors, &(&1.code == :invalid_rail_active_panel))
  end
end
