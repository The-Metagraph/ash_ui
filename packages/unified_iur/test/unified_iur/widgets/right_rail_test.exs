defmodule UnifiedIUR.Widgets.RightRailTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Interaction, Validate}
  alias UnifiedIUR.Widgets.Components

  test "right_rail constructor emits canonical layer shell component metadata" do
    rail =
      Components.right_rail(
        id: "rail",
        panels: [
          %{id: :summary, label: "Summary", content_slot: :summary_body},
          %{id: :activity, label: "Activity", disabled?: true, empty_state: "No activity"}
        ],
        active_panel: :summary,
        collapsed?: true,
        collapsible?: true,
        interactions: [
          Interaction.selection(
            intent: :select_panel,
            element_id: "rail",
            selection: :summary,
            mapping: %{panel_id: :id}
          ),
          Interaction.change(
            intent: :toggle_rail,
            element_id: "rail",
            value: true,
            mapping: %{collapsed?: :collapsed?}
          )
        ]
      )

    assert %Element{type: :widget, kind: :right_rail} = rail
    assert rail.attributes.component == %{family: :layer_shell_and_callout, kind: :right_rail}

    assert rail.attributes.rail == %{
             id: "rail",
             side: :right,
             panels: [
               %{id: :summary, label: "Summary", content_slot: :summary_body},
               %{id: :activity, label: "Activity", disabled?: true, empty_state: "No activity"}
             ],
             active_panel: :summary,
             collapsed?: true,
             collapsible?: true
           }

    assert :ok = Validate.element(rail)
  end

  test "validation rejects missing panels and active panel drift" do
    missing_panels = Components.right_rail(id: "rail", panels: [], active_panel: :summary)

    drift =
      Components.right_rail(
        id: "rail",
        panels: [%{id: :summary, label: "Summary"}],
        active_panel: :activity
      )

    assert {:error, missing_errors} = Validate.element(missing_panels)
    assert Enum.any?(missing_errors, &(&1.code == :invalid_rail_panel))

    assert {:error, [drift_error]} = Validate.element(drift)
    assert drift_error.code == :invalid_rail_active_panel
  end

  test "validation rejects renderer event strings in rail panels or interactions" do
    panel_event =
      Element.new(:widget, :right_rail,
        attributes: %{
          component: %{family: :layer_shell_and_callout, kind: :right_rail},
          rail: %{
            id: "rail",
            side: :right,
            panels: [%{"phx-click" => "select", id: :summary, label: "Summary"}],
            active_panel: :summary,
            collapsed?: false,
            collapsible?: true
          }
        }
      )

    event_string =
      Element.new(:widget, :right_rail,
        attributes: %{
          component: %{family: :layer_shell_and_callout, kind: :right_rail},
          rail: %{
            id: "rail",
            side: :right,
            panels: [%{id: :summary, label: "Summary"}],
            active_panel: :summary,
            collapsed?: false,
            collapsible?: true
          },
          interactions: ["select-summary"]
        }
      )

    assert {:error, [panel_error]} = Validate.element(panel_event)
    assert panel_error.code == :invalid_rail_panel

    assert {:error, errors} = Validate.element(event_string)
    assert Enum.any?(errors, &(&1.code == :invalid_interaction_attachment))
    assert Enum.any?(errors, &(&1.code == :invalid_rail_interaction))
  end
end
