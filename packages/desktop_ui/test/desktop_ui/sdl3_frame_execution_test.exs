defmodule DesktopUi.Sdl3FrameExecutionTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.{App, PortHost, Protocol}

  test "frame requests can be encoded and acknowledged through the host presentation boundary" do
    assert {:ok, boot_request} =
             App.boot_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, host} = PortHost.launch_default()
    assert {:ok, host} =
             PortHost.send_message(
               host,
               Protocol.new_message(
                 :boot,
                 :request,
                 boot_request,
                 runtime_id: boot_request.runtime.runtime_id,
                 screen_id: boot_request.runtime.screen_id,
                 window_id: boot_request.windows.primary_id
               )
             )
    assert {:ok, _boot_ack, host} = PortHost.recv_message(host, 5_000)

    assert {:ok, frame_ack, host} = App.present_frame(host, boot_request.frame_request, timeout: 5_000)

    assert frame_ack.family == :frame
    assert frame_ack.kind == :ack
    assert frame_ack.payload.presentation.backend == :sdl_renderer
    assert frame_ack.payload.presentation.presented_frame?
    assert frame_ack.payload.presentation.draw_operation_count > 0
    assert frame_ack.payload.host.presented_frames == 1
    assert PortHost.status(host).last_message_family == :frame

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(host)
  end

  test "host-backed launches present an initial frame for canonical examples" do
    assert {:ok, launched} =
             App.launch_iur_screen(
               DesktopUi.Examples.canonical_foundational_screen(),
               platform_target: :linux
             )

    assert launched.frame_acknowledgement.payload.presentation.backend == :sdl_renderer
    assert launched.frame_acknowledgement.payload.presentation.presented_frame?
    assert launched.frame_acknowledgement.payload.presentation.logical_presentation.mode ==
             :letterbox

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(launched.host)
  end
end
