defmodule LiveUi.RightRailTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.RightRail
  alias UnifiedIUR.{Element, Interaction}
  alias UnifiedIUR.Widgets.{Components, Foundational}

  test "component renders canonical rail attributes and active panel content" do
    html =
      render_component(&RightRail.render/1, %{
        id: "workspace-rail",
        side: :right,
        panels: [
          %{id: :summary, label: "Summary", content_slot: :summary_body},
          %{id: :activity, label: "Activity", badge: "2"}
        ],
        active_panel: :summary,
        collapsed?: false,
        collapsible?: true,
        density: :compact,
        width: "320px",
        panel_attrs: %{},
        collapse_attrs: %{},
        tone: nil,
        variant: nil,
        state: nil,
        class: nil,
        rest: %{},
        metadata: %{},
        panel: [
          %{
            id: :summary,
            inner_block: fn _assigns, _arg -> "Summary body" end
          }
        ]
      })

    assert html =~ ~s(id="workspace-rail")
    assert html =~ ~s(data-live-ui-widget="right-rail")
    assert html =~ ~s(data-live-ui-rail-active-panel="summary")
    assert html =~ ~s(data-live-ui-rail-density="compact")
    assert html =~ ~s(data-live-ui-rail-width="320px")
    assert html =~ "Summary body"
    refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
  end

  test "renderer dispatches right rail to native widget and preserves panel slots" do
    element =
      Components.right_rail(
        id: "renderer-rail",
        panels: [
          %{id: :summary, label: "Summary", content_slot: :summary_body},
          %{id: :activity, label: "Activity", content_slot: :activity_body}
        ],
        active_panel: :summary,
        children: [
          Element.Child.new(:summary_body, Foundational.text("Summary body", id: "summary-text")),
          Element.Child.new(
            :activity_body,
            Foundational.text("Activity body", id: "activity-text")
          )
        ]
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="right-rail")
    assert html =~ ~s(data-live-ui-widget="text")
    assert html =~ "Summary body"
    refute html =~ "Activity body"
    refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
    refute html =~ ~s(data-live-ui-component-kind="right_rail")
  end

  test "renderer derives canonical interaction attributes for panel selection and collapse" do
    element =
      Components.right_rail(
        id: "interactive-rail",
        panels: [
          %{id: :summary, label: "Summary"},
          %{id: :activity, label: "Activity", disabled?: true}
        ],
        active_panel: :summary,
        interactions: [
          Interaction.selection(
            intent: :select_panel,
            element_id: "interactive-rail",
            mapping: %{selected_value: :id}
          ),
          Interaction.change(
            intent: :toggle_rail,
            element_id: "interactive-rail",
            mapping: %{collapsed?: :collapsed?}
          )
        ]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{element: element, event_target: "#screen"})

    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-click="canonical_change_interaction")
    assert html =~ ~s(phx-target="#screen")
    assert html =~ ~s(phx-value-panel_id="summary")
    refute html =~ ~s(data-live-ui-rail-panel="activity" phx-click=)
  end

  test "is exposed through the layer shell and callout widget family" do
    metadata = LiveUi.Component.metadata(RightRail)

    assert :layer_shell_and_callout in LiveUi.Widgets.families()
    assert RightRail in LiveUi.Widgets.LayerShellAndCallout.modules()
    assert RightRail in LiveUi.Widgets.layer_shell_and_callout_modules()
    assert RightRail in LiveUi.Widgets.modules()
    assert metadata.family == :layer_shell_and_callout
    assert metadata.name == :right_rail
    assert :panel in metadata.slots
    assert metadata.events == [:selection, :change]
  end
end
