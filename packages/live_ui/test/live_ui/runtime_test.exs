defmodule LiveUi.RuntimeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule CounterScreen do
    use LiveUi.Screen, id: :counter_screen, title: "Counter"

    @impl true
    def mount_defaults do
      %{count: 0}
    end

    @impl true
    def event_routes do
      %{"increment" => :increment}
    end

    @impl true
    def bridge_hooks do
      [:resize_observer]
    end

    @impl true
    def handle_event(:increment, %{"step" => step}, assigns) do
      {:ok, %{assigns | count: assigns.count + step}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="counter-screen" title={title()}>
        <LiveUi.Widgets.Text.render id="count" content={Integer.to_string(@count)} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  defmodule InvalidScreen do
    def id, do: :invalid
  end

  test "runtime mounts a screen with server-authoritative defaults" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(CounterScreen, assigns: %{count: 2})

    assert runtime_state.assigns.count == 2
    assert runtime_state.assigns.current_screen_id == :counter_screen
    assert runtime_state.assigns.navigation_history == []
    assert runtime_state.event_routes == %{"increment" => :increment}
    assert runtime_state.bridge_hooks == [:resize_observer]
  end

  test "runtime handles native events through screen callbacks" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(CounterScreen)

    assert {:ok, updated_state} =
             LiveUi.Runtime.handle_event(runtime_state, "increment", %{"step" => 3})

    assert updated_state.assigns.count == 3
  end

  test "runtime renders mounted screens through the shared live component" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(CounterScreen)

    html =
      render_component(LiveUi.Runtime.component(), id: "counter", runtime_state: runtime_state)

    assert html =~ "Counter"
    assert html =~ ">0<"
  end

  test "runtime live component routes native screen events through the mounted screen" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(CounterScreen)

    socket =
      %Phoenix.LiveView.Socket{}
      |> Phoenix.Component.assign(:runtime_state, runtime_state)

    assert {:noreply, updated_socket} =
             LiveUi.Runtime.ScreenComponent.handle_event("increment", %{"step" => 2}, socket)

    assert updated_socket.assigns.runtime_state.assigns.count == 2
    assert updated_socket.assigns.runtime_event_error == nil
  end

  test "runtime returns deterministic diagnostics for invalid screens and routes" do
    assert {:error, %LiveUi.Runtime.Error{reason: :invalid_screen_module}} =
             LiveUi.Runtime.mount(InvalidScreen)

    assert {:ok, runtime_state} = LiveUi.Runtime.mount(CounterScreen)

    assert {:error, %LiveUi.Runtime.Error{reason: :invalid_event_route}} =
             LiveUi.Runtime.handle_event(runtime_state, "decrement", %{})
  end
end
