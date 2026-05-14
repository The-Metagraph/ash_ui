defmodule DesktopUi.Sdl3ResourceAndEventRoundtripTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime
  alias DesktopUi.Sdl3.App

  test "host-backed text and image preparation reports bounded cache-aware resource state" do
    assert {:ok, launched} =
             App.launch_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, text_ack, host} =
             App.prepare_text_resource(launched.host, "Workspace", font: "ui-sans", size: 16)

    assert text_ack.family == :text
    assert text_ack.kind == :ack
    refute text_ack.payload.cached?
    assert text_ack.payload.resource.validation_state == :text_resource_ready

    assert {:ok, text_cached_ack, host} =
             App.prepare_text_resource(host, "Workspace", font: "ui-sans", size: 16)

    assert text_cached_ack.payload.cached?
    assert text_cached_ack.payload.cache_size == 1

    assert {:ok, image_ack, host} =
             App.prepare_image_resource(host, "assets/logo.png", size: {64, 64})

    assert image_ack.family == :image
    assert image_ack.kind == :ack
    refute image_ack.payload.cached?
    assert image_ack.payload.resource.validation_state == :image_resource_ready

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(host)
  end

  test "host-normalized event batches round-trip into retained runtime routing and canonical boundary translation" do
    screen = DesktopUi.Examples.native_foundational_screen()

    assert {:ok, runtime_state} = Runtime.mount_native_screen(screen, platform_target: :linux)

    assert {:ok, launched} = App.launch_native_screen(screen, platform_target: :linux)

    assert {:ok, next_state, event_roundtrip, host} =
             App.dispatch_native_events(
               launched.host,
               runtime_state,
               [
                 [
                   type: :focus_changed,
                   focus_target: "save-button",
                   window_id: runtime_state.windows.primary,
                   runtime_id: runtime_state.runtime_id,
                   screen: runtime_state.screen_id,
                   platform_target: runtime_state.platform_target
                 ],
                 [
                   type: :keyboard_key_down,
                   key: "s",
                   modifiers: [:ctrl],
                   family: :command,
                   intent: :save_workspace,
                   boundary: :boundary,
                   widget_id: "save-button",
                   window_id: runtime_state.windows.primary,
                   runtime_id: runtime_state.runtime_id,
                   screen: runtime_state.screen_id,
                   platform_target: runtime_state.platform_target
                 ]
               ],
               timeout: 5_000
             )

    assert next_state.focus.current == "save-button"
    assert event_roundtrip.acknowledgement.family == :events
    assert event_roundtrip.acknowledgement.payload.batch_size == 2
    assert event_roundtrip.acknowledgement.payload.route_summary.local_runtime == 1
    assert event_roundtrip.acknowledgement.payload.route_summary.canonical_boundary == 1

    [focus_route, boundary_route] = event_roundtrip.route_results
    assert focus_route.route == :local_runtime
    assert boundary_route.route == :canonical_boundary
    assert boundary_route.translation.signal.type == "desktop_ui.command.save_workspace"

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(host)
  end
end
