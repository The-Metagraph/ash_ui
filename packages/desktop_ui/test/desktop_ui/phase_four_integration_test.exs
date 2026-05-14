defmodule DesktopUi.PhaseFourIntegrationTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime

  test "boundary-crossing interactions emit and consume canonical signals with cloud event semantics" do
    native_screen = DesktopUi.Examples.native_transport_review()
    canonical_screen = DesktopUi.Examples.canonical_transport_review()

    assert {:ok, native_state} =
             Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    assert {:ok, native_boundary_state, native_route} =
             Runtime.dispatch_native_event(native_state,
               input_family: :shortcut,
               shortcut: "ctrl-r",
               widget_id: "refresh-command",
               intent: :refresh_workspace
             )

    assert native_route.route == :canonical_boundary
    assert native_route.family == :command
    assert native_route.translation.signal.type == "desktop_ui.command.refresh_workspace"
    assert native_route.translation.cloud_event.specversion == "1.0.2"

    assert native_route.translation.cloud_event.subject ==
             "native/transport-review/refresh-command"

    assert native_boundary_state.event_loop.boundary_events == 1

    assert {:ok, inbound_state, inbound_route} =
             Runtime.handle_boundary_signal(
               native_boundary_state,
               native_route.translation.signal
             )

    assert inbound_route.route == :canonical_boundary
    assert inbound_route.family == :command
    assert inbound_route.input_family == :shortcut
    assert inbound_state.event_loop.boundary_events == 2

    assert {:ok, canonical_boundary_state, canonical_route} =
             Runtime.dispatch_widget_interaction(
               canonical_state,
               "refresh-command",
               :command,
               intent: :refresh_workspace,
               runtime_event: "shortcut:refresh_workspace",
               payload: %{command: :refresh}
             )

    assert canonical_route.route == :canonical_boundary
    assert canonical_route.family == native_route.family
    assert canonical_route.translation.signal.type == native_route.translation.signal.type
    assert canonical_boundary_state.event_loop.boundary_events == 1
  end

  test "invalid canonical event payloads and leaked platform envelopes fail deterministically" do
    native_screen = DesktopUi.Examples.native_transport_review()
    canonical_screen = DesktopUi.Examples.canonical_transport_review()

    assert {:ok, native_state} =
             Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    assert {:error, %DesktopUi.Transport.Error{reason: :invalid_payload_mapping}} =
             Runtime.dispatch_widget_interaction(
               canonical_state,
               "refresh-command",
               :command,
               intent: :refresh_workspace,
               payload: "not-a-map"
             )

    assert {:error, %DesktopUi.Transport.Error{reason: :leaked_platform_detail}} =
             Runtime.dispatch_native_event(native_state,
               input_family: :keyboard,
               key: "enter",
               widget_id: "command-input",
               intent: :submit_query,
               sdl_event: %{scancode: 40}
             )
  end

  test "local native handling and normalized input profiles stay bounded inside the shared runtime" do
    native_screen = DesktopUi.Examples.native_transport_review()

    assert {:ok, native_state} =
             Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, focused_state, local_route} =
             Runtime.dispatch_native_event(native_state,
               input_family: :focus,
               boundary: :local,
               focus_target: "scope-menu",
               widget_id: "scope-menu",
               intent: :focus_scope_menu
             )

    assert local_route.route == :local_runtime
    assert local_route.family == :focus
    assert local_route.translation.signal == nil
    assert focused_state.focus.current == "scope-menu"
    assert focused_state.event_loop.local_events == 1

    transport = DesktopUi.Examples.transport_comparison()
    normalized = DesktopUi.Examples.normalized_input_comparison()
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert transport.parity.local_focus_stays_local?
    assert transport.parity.boundary_routes_match?
    assert transport.parity.boundary_signal_types_match?
    assert transport.parity.normalized_input_family_match?

    assert normalized.parity.shortcut_family_match?
    assert normalized.parity.window_events_stay_local?
    assert normalized.parity.local_boundary_split_visible?
    assert normalized.parity.platform_variation_bounded?

    assert :native_transport_review in reference.examples.native_ids
    assert :canonical_transport_review in reference.examples.canonical_ids
    assert :transport_flow_review in reference.examples.comparison_ids
    assert :normalized_input_profiles in reference.examples.comparison_ids
    assert :canonical_boundary in reference.transport.modes
    assert reference.inspection.transport_contract.no_platform_leakage_guarantee
    assert summary.transport.validation_state == :transport_diagnostics_ready
  end
end
