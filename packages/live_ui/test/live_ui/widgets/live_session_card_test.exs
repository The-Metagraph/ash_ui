defmodule LiveUi.Widgets.LiveSessionCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  @session_id "550e8400-e29b-41d4-a716-446655440000"
  @started_at ~U[2026-05-27 15:00:00Z]

  describe "live_session_card widget metadata" do
    test "registers as a workflow_progress_and_status widget with control events" do
      metadata = Component.metadata(LiveUi.Widgets.LiveSessionCard)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.LiveSessionCard.Component
      assert metadata.family == :workflow_progress_and_status
      assert metadata.name == :live_session_card
      assert :pin_toggled in metadata.events
      assert :interrupted in metadata.events
      assert :expanded_recent in metadata.events
    end

    test "is present in workflow progress aggregation" do
      assert LiveUi.Widgets.LiveSessionCard in LiveUi.Widgets.WorkflowProgressAndStatus.modules()

      assert LiveUi.Widgets.LiveSessionCard in LiveUi.Widgets.workflow_progress_and_status_modules()
    end
  end

  describe "live_session_card component rendering" do
    test "renders the canonical root hooks, status badge, meters, and actions" do
      html =
        render_component(
          &LiveUi.Widgets.LiveSessionCard.component/1,
          base_assigns()
        )

      assert html =~ ~s(data-live-ui-widget="live-session-card")
      assert html =~ ~s(data-session-id="#{@session_id}")
      assert html =~ ~s(data-status-version="7")
      assert html =~ ~s(data-pinned="false")
      assert html =~ "live-ui-live-session-card--running"
      assert html =~ "@opus"
      assert html =~ "RUNNING"
      assert html =~ ~s(data-meter="tools")
      assert html =~ ~s(data-meter="edits")
      assert html =~ ~s(data-meter="tokens")
      assert html =~ "Pin"
      assert html =~ "Interrupt"
    end

    test "renders live region and recent activity list with accessibility labels" do
      html =
        render_component(
          &LiveUi.Widgets.LiveSessionCard.component/1,
          base_assigns(
            now_streaming: "Writing adapter tests.",
            recent_events: [
              %{kind: :assistant_text, body: "Checking renderer."},
              %{kind: :tool_call, body: "mix test"}
            ]
          )
        )

      assert html =~ ~s(aria-live="polite")
      assert html =~ "Writing adapter tests."
      assert html =~ ~s(aria-label="Recent activity for @opus")
      assert html =~ "assistant text"
      assert html =~ "Checking renderer."
      assert html =~ "tool call"
      assert html =~ "mix test"
    end

    test "caps rendered recent events at five" do
      recent_events =
        for index <- 1..6 do
          %{kind: :assistant_text, body: "event #{index}"}
        end

      html =
        render_component(
          &LiveUi.Widgets.LiveSessionCard.component/1,
          base_assigns(recent_events: recent_events)
        )

      assert html =~ "event 5"
      refute html =~ "event 6"
    end

    test "renders pinned state and fallback event attrs" do
      html =
        render_component(
          &LiveUi.Widgets.LiveSessionCard.component/1,
          base_assigns(pinned?: true)
        )

      assert html =~ ~s(data-pinned="true")
      assert html =~ "is-pinned"
      assert html =~ ~s(aria-pressed="true")
      assert html =~ ~s(aria-label="Unpin @opus running session")
      assert html =~ ~s(phx-click="pin_toggled")
      assert html =~ ~s(phx-click="interrupted")
      assert html =~ ~s(phx-click="expanded_recent")
    end
  end

  describe "renderer dispatch" do
    test "live_session_card kind is in supported_kinds" do
      assert :live_session_card in LiveUi.Renderer.supported_kinds()
    end

    test "renders via dedicated renderer clause with canonical command attrs" do
      element = Components.live_session_card(base_iur_opts())

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="live-session-card")
      assert html =~ ~s(id="live_session:#{@session_id}:7")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="live_session_card")
      assert html =~ ~s(phx-value-command="pin_toggled")
      assert html =~ ~s(phx-value-command="interrupted")
      assert html =~ ~s(phx-value-command="expanded_recent")
      refute html =~ ~s(data-live-ui-component-kind="live_session_card")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end
  end

  defp base_assigns(overrides \\ []) do
    Map.merge(
      %{
        id: "live_session:#{@session_id}:7",
        session_id: @session_id,
        actor_handle: "@opus",
        status: :running,
        status_version: 7,
        tools_count: 3,
        edits_count: 2,
        tokens_consumed: 12_345,
        started_at: @started_at,
        current_task_title: "Implement live session card",
        current_step: "renderer",
        recent_events: [],
        pinned?: false
      },
      Map.new(overrides)
    )
  end

  defp base_iur_opts(overrides \\ []) do
    Keyword.merge(
      [
        session_id: @session_id,
        actor_handle: "@opus",
        status: :running,
        status_version: 7,
        tools_count: 3,
        edits_count: 2,
        tokens_consumed: 12_345,
        started_at: @started_at,
        now_streaming: "Writing renderer tests.",
        recent_events: [%{kind: :assistant_text, body: "Working."}]
      ],
      overrides
    )
  end
end
