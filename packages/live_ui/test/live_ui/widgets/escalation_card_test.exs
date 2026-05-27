defmodule LiveUi.Widgets.EscalationCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  describe "escalation_card widget metadata" do
    test "registers as a layer_shell_and_callout widget with action events" do
      metadata = Component.metadata(LiveUi.Widgets.EscalationCard)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.EscalationCard.Component
      assert metadata.family == :layer_shell_and_callout
      assert metadata.name == :escalation_card
      assert :acknowledge in metadata.events
      assert :route_to_rail in metadata.events
    end

    test "is present in layer_shell_and_callout aggregation" do
      assert LiveUi.Widgets.EscalationCard in LiveUi.Widgets.LayerShellAndCallout.modules()

      assert LiveUi.Widgets.EscalationCard in LiveUi.Widgets.layer_shell_and_callout_modules()
    end
  end

  describe "escalation_card component rendering" do
    test "renders canonical root hooks, header, severity badge, and text" do
      html = render_component(&LiveUi.Widgets.EscalationCard.component/1, base_assigns())

      assert html =~ ~s(data-live-ui-widget="escalation-card")
      assert html =~ ~s(data-severity="p2")
      assert html =~ ~s(role="alert")
      assert html =~ ~s(aria-labelledby="escalation-card-title")
      assert html =~ "live-ui-escalation-card__header"
      assert html =~ "P2"
      assert html =~ ~s(role="status")
      assert html =~ "Escalation"
      assert html =~ "Coverage gap detected on chat surface."
      assert html =~ "@codex"
    end

    test "renders p1, p2, p3 severity variants with correct BEM modifier" do
      for severity <- [:p1, :p2, :p3] do
        html =
          render_component(
            &LiveUi.Widgets.EscalationCard.component/1,
            base_assigns(%{id: "esc-#{severity}", severity: severity})
          )

        assert html =~ ~s(data-severity="#{severity}")
        assert html =~ "live-ui-escalation-card--#{severity}"
        assert html =~ String.upcase(to_string(severity))
      end
    end

    test "renders action buttons with descriptive aria labels when unacknowledged" do
      html = render_component(&LiveUi.Widgets.EscalationCard.component/1, base_assigns())

      assert html =~ ~s(aria-label="Acknowledge p2 escalation")
      assert html =~ ~s(aria-label="Route p2 escalation to rail")
      assert html =~ ~s(phx-click="acknowledge")
      assert html =~ ~s(phx-click="route_to_rail")
      assert html =~ "live-ui-escalation-card__actions"
    end

    test "hides action buttons and shows acknowledged status when acknowledged" do
      html =
        render_component(
          &LiveUi.Widgets.EscalationCard.component/1,
          base_assigns(%{acknowledged?: true})
        )

      assert html =~ ~s(data-acknowledged="true")
      assert html =~ "live-ui-escalation-card__acknowledged"
      assert html =~ "Acknowledged"
      assert html =~ ~s(role="status")
      refute html =~ "live-ui-escalation-card__actions"
      refute html =~ ~s(aria-label="Acknowledge p2 escalation")
    end

    test "renders optional meta section with target_project_id and proposed_action" do
      html =
        render_component(
          &LiveUi.Widgets.EscalationCard.component/1,
          base_assigns(%{
            target_project_id: "ariston-ui",
            proposed_action: "Add aria-live region"
          })
        )

      assert html =~ "live-ui-escalation-card__meta"
      assert html =~ "Target project"
      assert html =~ "ariston-ui"
      assert html =~ "Proposed action"
      assert html =~ "Add aria-live region"
    end

    test "omits meta section when no optional meta fields are present" do
      html =
        render_component(
          &LiveUi.Widgets.EscalationCard.component/1,
          base_assigns(%{proposed_action: nil})
        )

      # target_project_id is still required and present — meta still renders
      assert html =~ "live-ui-escalation-card__meta"
    end
  end

  describe "renderer dispatch" do
    test "escalation_card kind is in supported_kinds" do
      assert :escalation_card in LiveUi.Renderer.supported_kinds()
    end

    test "renders through native renderer with canonical action attrs" do
      element =
        Components.escalation_card(
          id: "escalation-renderer",
          target_project_id: "ariston-ui",
          severity: :p1,
          text: "Critical coverage gap detected."
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="escalation-card")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="escalation_card")
      assert html =~ ~s(phx-value-element_id="escalation-renderer")
      assert html =~ ~s(phx-value-action="acknowledge")
      assert html =~ ~s(phx-value-action="route_to_rail")
      refute html =~ ~s(data-live-ui-component-kind="escalation_card")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end
  end

  defp base_assigns(overrides \\ %{}) do
    Map.merge(
      %{
        id: "escalation-card",
        target_project_id: "ariston-ui",
        severity: :p2,
        text: "Coverage gap detected on chat surface.",
        actor_handle: "@codex",
        acknowledged?: false
      },
      overrides
    )
  end
end
