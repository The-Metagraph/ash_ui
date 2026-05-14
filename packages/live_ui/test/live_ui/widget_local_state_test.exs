defmodule LiveUi.WidgetLocalStateTest do
  use ExUnit.Case, async: true
  use Phoenix.Component

  alias LiveUi.Runtime.State
  alias LiveUi.Widget.Identity
  alias LiveUi.Component.Metadata

  describe "widget_local_state/2" do
    test "returns empty map when no state exists for widget" do
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}

      assert State.widget_local_state(state, "native:content:text:test-id:root") == %{}
    end

    test "returns stored state for widget identity key" do
      widget_key = "native:content:text:test-id:root"
      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{widget_key => %{count: 5}}
      }

      assert State.widget_local_state(state, widget_key) == %{count: 5}
    end

    test "returns stored state for widget identity struct" do
      identity = %Identity{
        id: "test-id--root",
        component_module: TestWidget.Component,
        widget_module: TestWidget,
        family: :content,
        name: :text,
        path: [],
        mode: :native
      }

      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{Identity.key(identity) => %{count: 5}}
      }

      assert State.widget_local_state(state, identity) == %{count: 5}
    end
  end

  describe "put_widget_local_state/3" do
    test "stores widget-local state by key" do
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}
      widget_key = "native:content:text:test-id:root"

      updated_state = State.put_widget_local_state(state, widget_key, %{count: 1})

      assert updated_state.widget_local_state[widget_key] == %{count: 1}
    end

    test "replaces existing widget-local state" do
      widget_key = "native:content:text:test-id:root"
      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{widget_key => %{count: 1}}
      }

      updated_state = State.put_widget_local_state(state, widget_key, %{count: 10})

      assert updated_state.widget_local_state[widget_key] == %{count: 10}
    end

    test "stores state for widget identity struct" do
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}
      identity = %Identity{
        id: "test-id--root",
        component_module: TestWidget.Component,
        widget_module: TestWidget,
        family: :content,
        name: :text,
        path: [],
        mode: :native
      }

      updated_state = State.put_widget_local_state(state, identity, %{active: true})

      assert updated_state.widget_local_state[Identity.key(identity)] == %{active: true}
    end
  end

  describe "update_widget_local_state/3" do
    test "updates widget-local state with a function" do
      widget_key = "native:content:button:counter:root"
      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{widget_key => %{count: 0}}
      }

      updated_state = State.update_widget_local_state(state, widget_key, fn state ->
        Map.update(state, :count, 0, &(&1 + 1))
      end)

      assert updated_state.widget_local_state[widget_key] == %{count: 1}
    end

    test "creates empty state when none exists" do
      widget_key = "native:content:button:new:root"
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}

      updated_state = State.update_widget_local_state(state, widget_key, fn state ->
        Map.put(state, :initialized, true)
      end)

      assert updated_state.widget_local_state[widget_key] == %{initialized: true}
    end

    test "works with widget identity struct" do
      identity = %Identity{
        id: "toggle--root",
        component_module: TestWidget.Component,
        widget_module: TestWidget,
        family: :input,
        name: :toggle,
        path: [],
        mode: :native
      }

      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{Identity.key(identity) => %{checked: false}}
      }

      updated_state = State.update_widget_local_state(state, identity, fn state ->
        Map.update(state, :checked, false, &(!&1))
      end)

      assert updated_state.widget_local_state[Identity.key(identity)] == %{checked: true}
    end
  end

  describe "delete_widget_local_state/2" do
    test "removes widget-local state by key" do
      widget_key = "native:content:text:temp:root"
      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{widget_key => %{value: 1}}
      }

      updated_state = State.delete_widget_local_state(state, widget_key)

      assert Map.has_key?(updated_state.widget_local_state, widget_key) == false
    end

    test "works with widget identity struct" do
      identity = %Identity{
        id: "removed--root",
        component_module: TestWidget.Component,
        widget_module: TestWidget,
        family: :content,
        name: :text,
        path: [],
        mode: :native
      }

      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{Identity.key(identity) => %{data: "test"}}
      }

      updated_state = State.delete_widget_local_state(state, identity)

      assert Map.has_key?(updated_state.widget_local_state, Identity.key(identity)) == false
    end
  end

  describe "handle_widget_event/2" do
    test "handles widget event and updates local state" do
      widget_key = "native:content:button:counter:root"
      state = %State{
        screen: TestScreen,
        assigns: %{},
        mode: :native,
        event_routes: %{},
        bridge_hooks: [],
        widget_local_state: %{widget_key => %{count: 0}}
      }

      # Use the wrapper module, not the Component submodule
      # handle_widget_event/3 is defined in the wrapper module
      params = %{
        "widget_component" => "Elixir.LiveUi.WidgetLocalStateTest.CounterWidget",
        "widget_key" => widget_key,
        "widget_event" => "increment"
      }

      assert {:ok, updated_state} = State.handle_widget_event(state, params)
      assert updated_state.widget_local_state[widget_key] == %{count: 1}
    end

    test "returns error for invalid payload" do
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}

      assert {:error, _reason} = State.handle_widget_event(state, %{})
      assert {:error, _reason} = State.handle_widget_event(state, %{"widget_key" => "test"})
    end

    test "returns error for non-existent widget component" do
      state = %State{screen: TestScreen, assigns: %{}, mode: :native, event_routes: %{}, bridge_hooks: []}

      params = %{
        "widget_component" => "Elixir.NonExistent.Widget",
        "widget_key" => "test",
        "widget_event" => "event"
      }

      assert {:error, _reason} = State.handle_widget_event(state, params)
    end
  end

  # Test helpers

  defmodule TestScreen do
    def id, do: :test_screen
    def mount_defaults, do: %{}
    def event_routes, do: %{}
    def bridge_hooks, do: []
    def handle_event(_event, _payload, _assigns), do: {:ok, %{}}
    def render(_assigns), do: {:ok, %{}}
  end

  defmodule TestWidget do
    use LiveUi.Widget,
      wrapper: __MODULE__,
      family: :content,
      name: :text,
      assigns: [],
      events: [],
      local_state_keys: []
  end

  defmodule CounterWidget do
    use LiveUi.Widget,
      wrapper: __MODULE__,
      family: :content,
      name: :counter,
      assigns: [:label],
      events: [:click],
      local_state_keys: [:count]

    @impl true
    def mount_defaults, do: %{count: 0}

    @impl true
    def event_routes, do: %{"increment" => :increment}

    @impl true
    def handle_widget_event(:increment, _payload, local_state) do
      {:ok, Map.update(local_state, :count, 0, &(&1 + 1))}
    end
  end
end
