defmodule LiveUi.Phase4IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Jido.Signal
  alias LiveUi.Examples.{CanonicalBoundaryProfile, MixedBoundaryTransport, NativeBoundaryScreen}
  alias LiveUi.Transport.Error

  test "direct native interactions can stay local while boundary-native flows stay canonical-ready" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(NativeBoundaryScreen)

    local_example = NativeBoundaryScreen.local_event_example()

    assert {:ok, local_state, local_translation} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "rename",
               Keyword.fetch!(local_example, :payload),
               Keyword.delete(local_example, :payload)
             )

    assert local_state.assigns.name == "Ari"
    assert local_translation.signal == nil
    assert local_translation.boundary == :local

    boundary_example = NativeBoundaryScreen.boundary_event_example()

    assert {:ok, boundary_state, boundary_translation} =
             LiveUi.Runtime.dispatch_native_event(
               runtime_state,
               "rename",
               Keyword.fetch!(boundary_example, :payload),
               Keyword.delete(boundary_example, :payload)
             )

    assert boundary_state.assigns.name == "Ari"
    assert boundary_translation.boundary == :boundary
    assert %Signal{} = boundary_translation.signal
    assert boundary_translation.signal.type == "live_ui.change.rename_profile"
  end

  test "canonical boundary signals round-trip through channel transport and native runtime handling" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(NativeBoundaryScreen)
    assert {:ok, translation} = CanonicalBoundaryProfile.translation()
    assert %Signal{} = translation.signal

    assert {:ok, envelope} =
             LiveUi.Transport.Channel.outbound(
               translation.signal,
               topic: "live_ui:boundary:profile",
               channel: "profile"
             )

    assert {:ok, decoded_signal} = LiveUi.Transport.Channel.inbound(envelope)

    assert {:ok, updated_state, runtime_action} =
             LiveUi.Runtime.handle_boundary_signal(runtime_state, decoded_signal)

    assert updated_state.assigns.name == "Ari"
    assert runtime_action.family == :change
    assert runtime_action.intent == :rename_profile
    assert runtime_action.runtime_event == "rename"
    assert runtime_action.payload["name"] == "Ari"
    assert runtime_action.payload.mapping == %{name: :profile_name}
  end

  test "hooks stay bounded and canonical rendered screens share the same transport-ready runtime" do
    assert {:ok, runtime_state} = LiveUi.Runtime.mount(NativeBoundaryScreen)

    %{hook: hook, payload: payload, opts: opts} = MixedBoundaryTransport.hook_flow()

    assert {:ok, updated_state, translation} =
             LiveUi.Runtime.handle_hook_event(runtime_state, hook, payload, opts)

    assert updated_state.assigns.width == 120
    assert translation.signal == nil

    assert {:ok, canonical_runtime_state} =
             LiveUi.Runtime.mount_iur(CanonicalBoundaryProfile.element())

    html =
      render_component(LiveUi.Runtime.component(),
        id: "canonical-boundary-runtime",
        runtime_state: canonical_runtime_state
      )

    assert html =~ "data-live-ui-widget=\"form-builder\""
    assert html =~ "data-live-ui-widget=\"text-input\""
    assert html =~ "Pascal"
  end

  test "invalid boundary leakage fails with actionable diagnostics across the maintained comparison workflow" do
    assert {:ok, comparison} = MixedBoundaryTransport.compare_paths()
    assert comparison.native_local.signal == nil
    assert %Signal{} = comparison.native_boundary.signal
    assert %Signal{} = comparison.canonical_boundary.signal
    assert comparison.runtime_action.runtime_event == "rename"

    assert {:error, %Error{reason: :renderer_local_payload}} =
             LiveUi.Signals.from_native(
               family: :change,
               intent: :rename_profile,
               screen: :native_boundary,
               element_id: :profile_name,
               boundary: :boundary,
               payload: %{renderer_value: "leak"}
             )

    assert {:error, %Error{reason: :invalid_channel_envelope}} =
             LiveUi.Transport.Channel.inbound(%{kind: :unexpected})
  end
end
