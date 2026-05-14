defmodule LiveUi.Phase3IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Canvas, Container, Element, Layer, Layout, Viewport}
  alias UnifiedIUR.Widgets.{Advanced, Foundational}

  defmodule OperationsDashboardScreen do
    use LiveUi.Screen, id: :operations_dashboard, title: "Operations Dashboard"

    @impl true
    def mount_defaults do
      %{
        entries: [%{id: "evt-1", message: "ready", severity: :info}],
        processes: [%{id: "proc-1", pid: "#PID<0.10.0>", state: :running}],
        nodes: [%{id: "node-a", status: :up}],
        summary: %{healthy: 1}
      }
    end

    @impl true
    def event_routes do
      %{
        "append_event" => :append_event,
        "degrade_node" => :degrade_node
      }
    end

    @impl true
    def handle_event(:append_event, %{"message" => message}, assigns) do
      next_id = "evt-#{length(assigns.entries) + 1}"
      entries = assigns.entries ++ [%{id: next_id, message: message, severity: :warning}]
      {:ok, %{assigns | entries: entries}}
    end

    @impl true
    def handle_event(:degrade_node, _payload, assigns) do
      nodes = [%{id: "node-a", status: :degraded}]
      {:ok, %{assigns | nodes: nodes, summary: %{healthy: 0, degraded: 1}}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="ops-dashboard" title={title()}>
        <LiveUi.Layout.Column.render id="ops-column">
          <LiveUi.Widgets.StreamWidget.render id="stream" entries={@entries} />
          <LiveUi.Widgets.ProcessMonitor.render id="processes" processes={@processes} />
          <LiveUi.Widgets.ClusterDashboard.render id="cluster" nodes={@nodes} summary={@summary} />
        </LiveUi.Layout.Column.render>
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  defmodule OverlayDisplayScreen do
    use LiveUi.Screen, id: :overlay_display, title: "Overlay Display"

    @impl true
    def mount_defaults do
      %{
        dialog_open: true,
        toast_open: false,
        toast_message: "Saved",
        operations: [%{kind: :text, position: %{x: 2, y: 3}, text: "Canvas"}]
      }
    end

    @impl true
    def bridge_hooks do
      LiveUi.Display.browser_bridge_hooks()
    end

    @impl true
    def event_routes do
      %{
        "dismiss_dialog" => :dismiss_dialog,
        "show_toast" => :show_toast,
        "move_canvas" => :move_canvas
      }
    end

    @impl true
    def handle_event(:dismiss_dialog, _payload, assigns) do
      {:ok, %{assigns | dialog_open: false}}
    end

    @impl true
    def handle_event(:show_toast, %{"message" => message}, assigns) do
      {:ok, %{assigns | toast_open: true, toast_message: message}}
    end

    @impl true
    def handle_event(:move_canvas, %{"x" => x, "y" => y}, assigns) do
      operations = [%{kind: :text, position: %{x: x, y: y}, text: "Canvas"}]
      {:ok, %{assigns | operations: operations}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="overlay-display" title={title()}>
        <LiveUi.Widgets.OverlaySurface.render id="workspace-overlay" mode="stacked" background_fill="scrim">
          <:base>
            <LiveUi.Widgets.SplitPane.render id="workspace-split" ratio={0.4} sync_scroll="workspace">
              <:primary>
                <LiveUi.Widgets.Viewport.render id="workspace-viewport" offset_y={10} sync_group="workspace">
                  <LiveUi.Widgets.Text.render id="viewport-copy" content="Details" />
                </LiveUi.Widgets.Viewport.render>
              </:primary>
              <:secondary>
                <LiveUi.Widgets.Canvas.render id="workspace-canvas" operations={@operations} width={80} height={24} />
              </:secondary>
            </LiveUi.Widgets.SplitPane.render>
            <LiveUi.Widgets.ScrollBar.render id="workspace-scroll" viewport_ref="workspace-viewport" position_end={0.4} />
          </:base>
          <:overlay>
            <LiveUi.Widgets.Dialog.render id="settings-dialog" title="Settings" open={@dialog_open}>
              Settings body
            </LiveUi.Widgets.Dialog.render>
          </:overlay>
          <:overlay>
            <LiveUi.Widgets.Toast.render id="save-toast" open={@toast_open} severity="success">
              <%= @toast_message %>
            </LiveUi.Widgets.Toast.render>
          </:overlay>
        </LiveUi.Widgets.OverlaySurface.render>
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  test "advanced dashboard widgets render and update through the server-authoritative runtime" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(OperationsDashboardScreen)

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "append_event", %{"message" => "degraded"})

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "degrade_node", %{})

    html =
      render_component(LiveUi.Runtime.component(),
        id: "ops-runtime",
        runtime_state: runtime_state
      )

    assert html =~ "data-live-ui-widget=\"stream-widget\""
    assert html =~ "data-live-ui-widget=\"process-monitor\""
    assert html =~ "data-live-ui-widget=\"cluster-dashboard\""
    assert html =~ "degraded"
  end

  test "overlay-driven display flows preserve visibility, layering, and positioned canvas semantics" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(OverlayDisplayScreen)

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "dismiss_dialog", %{})

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "show_toast", %{
               "message" => "Saved changes"
             })

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "move_canvas", %{"x" => 9, "y" => 11})

    html =
      render_component(LiveUi.Runtime.component(),
        id: "overlay-runtime",
        runtime_state: runtime_state
      )

    assert html =~ "data-live-ui-widget=\"overlay-surface\""
    assert html =~ "data-live-ui-widget=\"split-pane\""
    assert html =~ "data-live-ui-widget=\"viewport\""
    assert html =~ "data-live-ui-widget=\"scroll-bar\""
    assert html =~ "data-live-ui-widget=\"canvas\""
    refute html =~ "id=\"settings-dialog\" data-live-ui-widget=\"dialog\" data-live-ui-open"
    assert html =~ "id=\"save-toast\" data-live-ui-widget=\"toast\" data-live-ui-open"
    assert html =~ "Saved changes"
    assert html =~ "data-live-ui-canvas-x=\"9\""
    assert html =~ "data-live-ui-canvas-y=\"11\""
  end

  test "advanced canonical screens reuse native display and overlay widgets through the shared renderer" do
    base =
      Viewport.split_pane(
        Viewport.region(
          Container.box([{:content, Foundational.text("Navigation")}], id: "nav-box"),
          id: "nav-viewport",
          offset: %{x: 0, y: 8}
        ),
        Viewport.region(
          Layout.column([
            Advanced.stream_widget(
              [
                %{id: "evt-1", message: "ready", severity: :info}
              ],
              id: "event-stream"
            ),
            Canvas.line_chart(
              [
                %{id: :cpu, label: "CPU", values: [10, 20, 30]}
              ],
              id: "cpu-chart"
            )
          ]),
          id: "detail-viewport"
        ),
        id: "workspace-split",
        ratio: 0.4
      )

    layered =
      Layer.overlay(
        base,
        [
          {:modal,
           Layer.dialog(
             Container.content([{:content, Foundational.text("Edit settings")}],
               id: "dialog-content"
             ),
             id: "settings-dialog",
             title: "Settings"
           )},
          {:popup,
           Layer.context_menu(
             [
               %{id: "copy", label: "Copy"}
             ],
             id: "row-menu",
             anchor: %{target_id: "nav-box", x: 12, y: 8}
           )}
        ],
        id: "workspace-overlay",
        background_fill: :scrim
      )

    assert {:ok, runtime_state} = LiveUi.Runtime.mount_iur(layered)

    html =
      render_component(LiveUi.Runtime.component(),
        id: "canonical-advanced",
        runtime_state: runtime_state
      )

    assert html =~ "data-live-ui-widget=\"overlay-surface\""
    assert html =~ "data-live-ui-widget=\"split-pane\""
    assert html =~ "data-live-ui-widget=\"viewport\""
    assert html =~ "data-live-ui-widget=\"stream-widget\""
    assert html =~ "data-live-ui-widget=\"line-chart\""
    assert html =~ "data-live-ui-widget=\"dialog\""
    assert html =~ "data-live-ui-widget=\"context-menu\""
  end

  test "invalid advanced canonical inputs fail with actionable diagnostics" do
    invalid_overlay =
      Element.new(:layer, :overlay,
        id: "broken-overlay",
        attributes: %{overlay: %{mode: :stacked}},
        children: []
      )

    assert {:ok, runtime_state} = LiveUi.Runtime.mount_iur(invalid_overlay)

    html =
      render_component(LiveUi.Runtime.component(),
        id: "invalid-canonical",
        runtime_state: runtime_state
      )

    assert html =~ "data-live-ui-diagnostic=\"missing_slot\""
    assert html =~ "overlay_surface requires a base slot"
  end
end
