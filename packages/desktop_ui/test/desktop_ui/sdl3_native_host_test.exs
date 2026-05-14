defmodule DesktopUi.Sdl3NativeHostTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime.State
  alias DesktopUi.Sdl3.{App, PortHost}

  test "native screens can boot through the default host and receive a running lifecycle acknowledgement" do
    assert {:ok, launched} =
             App.launch_native_screen(DesktopUi.Examples.native_foundational_screen())

    assert launched.acknowledgement.family == :boot
    assert launched.acknowledgement.kind == :ack
    assert launched.acknowledgement.payload.host.runtime_state == :running
    assert launched.acknowledgement.payload.host.backend == :sdl_renderer
    assert launched.acknowledgement.payload.lifecycle.state == :ready
    assert launched.acknowledgement.payload.windows.primary_id == "window:workspace-foundation"
    assert launched.frame_acknowledgement.family == :frame
    assert launched.frame_acknowledgement.kind == :ack
    assert launched.frame_acknowledgement.payload.presentation.presented_frame?
    assert launched.frame_acknowledgement.payload.host.presented_frames == 1
    assert PortHost.status(launched.host).liveness == :alive

    assert {:ok, shutdown_ack, _host} = App.shutdown_host(launched.host)
    assert shutdown_ack.family == :shutdown
    assert shutdown_ack.kind == :ack
  end

  test "canonical screens also boot through the same host path" do
    assert {:ok, launched} =
             App.launch_iur_screen(DesktopUi.Examples.canonical_foundational_screen())

    assert launched.boot_request.runtime.source_kind == :canonical
    assert launched.acknowledgement.payload.host.native_window_count >= 1
    assert launched.frame_acknowledgement.payload.presentation.window_count >= 1

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(launched.host)
  end

  test "host window sync acknowledges multiwindow updates without drifting from owner-window rules" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               %{
                 id: "ops-review",
                 title: "Ops Review",
                 root:
                   DesktopUi.Layer.multi_window("ops-multi-window", [
                     DesktopUi.Widgets.window("ops-primary", "Ops Primary", [
                       DesktopUi.Widgets.text("ops-title", "Operations")
                     ]),
                     DesktopUi.Widgets.window("ops-secondary", "Ops Secondary", [
                       DesktopUi.Widgets.dialog("inspect-dialog", "Inspect", [
                         DesktopUi.Widgets.text("inspect-copy", "Attached dialog")
                       ])
                     ])
                   ])
               },
               platform_target: :linux
             )

    assert %State{} = state
    assert {:ok, launched} = App.launch_native_screen(DesktopUi.Examples.native_foundational_screen())
    assert {:ok, ack, host} = App.sync_windows(launched.host, state)

    assert ack.family == :window
    assert ack.kind == :ack
    assert ack.payload.windows.continuity == :multi_window
    assert Enum.sort(ack.payload.windows.session_ids) == ["window:ops-primary", "window:ops-secondary"]
    assert PortHost.status(host).last_message_family == :window

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(host)
  end
end
