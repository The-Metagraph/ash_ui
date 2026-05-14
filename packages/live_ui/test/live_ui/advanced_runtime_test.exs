defmodule LiveUi.AdvancedRuntimeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule OperationsScreen do
    use LiveUi.Screen, id: :operations_screen, title: "Operations"

    @impl true
    def mount_defaults do
      %{
        entries: [%{id: "evt-1", message: "ready"}],
        nodes: [%{id: "node-a", status: :up}]
      }
    end

    @impl true
    def event_routes do
      %{"append_event" => :append_event}
    end

    @impl true
    def handle_event(:append_event, %{"message" => message}, assigns) do
      updated_entries =
        assigns.entries ++ [%{id: "evt-#{length(assigns.entries) + 1}", message: message}]

      {:ok, %{assigns | entries: updated_entries}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="operations" title={title()}>
        <LiveUi.Widgets.StreamWidget.render id="stream" entries={@entries} />
        <LiveUi.Widgets.ClusterDashboard.render id="cluster" nodes={@nodes} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  test "operational widgets update through the server-authoritative runtime" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(OperationsScreen)

    assert {:ok, runtime_state} =
             LiveUi.Runtime.handle_event(runtime_state, "append_event", %{"message" => "degraded"})

    html =
      render_component(LiveUi.Runtime.component(), id: "operations", runtime_state: runtime_state)

    assert html =~ "ready"
    assert html =~ "degraded"
    assert html =~ "data-live-ui-widget=\"stream-widget\""
  end
end
