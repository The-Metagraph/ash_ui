defmodule LiveUi.RuntimeTransportTest do
  use ExUnit.Case, async: true

  alias Jido.Signal

  defmodule BoundaryScreen do
    use LiveUi.Screen, id: :boundary_screen, title: "Boundary"

    @impl true
    def mount_defaults do
      %{name: "Pascal", width: 0}
    end

    @impl true
    def event_routes do
      %{
        "rename" => :rename,
        "resize_observer" => :resize_observer
      }
    end

    @impl true
    def bridge_hooks do
      [:resize_observer]
    end

    @impl true
    def handle_event(:rename, %{"name" => name}, assigns) do
      {:ok, %{assigns | name: name}}
    end

    @impl true
    def handle_event(:resize_observer, %{width: width}, assigns) do
      {:ok, %{assigns | width: width}}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div><%= @name %> / <%= @width %></div>
      """
    end
  end

  test "runtime dispatches native boundary events through one server-authoritative flow" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(BoundaryScreen)

    assert {:ok, updated_state, translation} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "rename",
               %{"name" => "Ari"},
               family: :change,
               intent: :rename_profile,
               boundary: :boundary,
               element_id: :profile_name,
               widget: :text_input
             )

    assert updated_state.assigns.name == "Ari"
    assert translation.boundary == :boundary
    assert %Signal{} = translation.signal
    assert translation.signal.type == "live_ui.change.rename_profile"
  end

  test "runtime handles boundary signals and channel envelopes through the same routing model" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(BoundaryScreen)

    {:ok, signal} =
      Jido.Signal.new(
        "live_ui.change.rename_profile",
        %{"name" => "Morgan"},
        source: "/live_ui/canonical/screen/profile",
        extensions: %{
          live_ui_family: :change,
          live_ui_intent: :rename_profile,
          live_ui_source: :canonical,
          live_ui_runtime_event: "rename",
          live_ui_source_context: %{screen: :boundary_screen},
          live_ui_target: %{binding: :profile},
          live_ui_metadata: %{boundary: :boundary}
        }
      )

    assert {:ok, envelope} =
             LiveUi.Runtime.channel_envelope(signal, topic: "live_ui:profile", channel: "profile")

    assert {:ok, state_from_channel, decoded_action} =
             LiveUi.Runtime.handle_channel_envelope(runtime_state, envelope)

    assert state_from_channel.assigns.name == "Morgan"
    assert decoded_action.runtime_event == "rename"
  end

  test "browser hook payloads stay bounded and subordinate to runtime routing" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(BoundaryScreen)

    assert {:ok, updated_state, translation} =
             LiveUi.Runtime.handle_hook_event(
               runtime_state,
               :resize_observer,
               %{"width" => 120, "height" => 80},
               event: "resize_observer",
               family: :change,
               intent: :measure_viewport
             )

    assert updated_state.assigns.width == 120
    assert translation.signal == nil
  end
end
