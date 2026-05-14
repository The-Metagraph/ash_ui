defmodule DesktopUi.PhaseSevenIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias DesktopUi.Runtime
  alias DesktopUi.Runtime.Error
  alias DesktopUi.Sdl3.App

  test "maintained native and canonical examples boot through the host path and present an initial frame" do
    assert {:ok, native_launch} =
             App.launch_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, canonical_launch} =
             App.launch_iur_screen(
               DesktopUi.Examples.canonical_foundational_screen(),
               platform_target: :linux
             )

    assert native_launch.acknowledgement.payload.host.runtime_state == :running
    assert native_launch.frame_acknowledgement.payload.presentation.presented_frame?

    assert native_launch.frame_acknowledgement.payload.presentation.logical_presentation.units ==
             :logical

    assert native_launch.frame_acknowledgement.payload.host.presented_frames == 1

    assert canonical_launch.boot_request.runtime.source_kind == :canonical
    assert canonical_launch.frame_acknowledgement.payload.presentation.backend == :sdl_renderer
    assert canonical_launch.frame_acknowledgement.payload.presentation.window_count >= 1

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(native_launch.host)
    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(canonical_launch.host)
  end

  test "resource preparation and event round-trips preserve runtime semantics across the host boundary" do
    screen = DesktopUi.Examples.native_foundational_screen()

    assert {:ok, runtime_state} = Runtime.mount_native_screen(screen, platform_target: :linux)
    assert {:ok, launched} = App.launch_native_screen(screen, platform_target: :linux)

    assert {:ok, text_ack, host} =
             App.prepare_text_resource(launched.host, "Workspace", font: "ui-sans", size: 16)

    assert {:ok, image_ack, host} =
             App.prepare_image_resource(host, "assets/logo.png", size: {64, 64})

    assert {:ok, next_state, event_roundtrip, host} =
             App.dispatch_native_events(
               host,
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

    assert text_ack.payload.resource.validation_state == :text_resource_ready
    assert image_ack.payload.resource.validation_state == :image_resource_ready
    assert next_state.focus.current == "save-button"
    assert event_roundtrip.acknowledgement.payload.route_summary.canonical_boundary == 1
    assert Enum.any?(event_roundtrip.route_results, &(&1.route == :canonical_boundary))
    assert Enum.any?(event_roundtrip.route_results, &(&1.route == :local_runtime))

    assert {:ok, _shutdown_ack, _host} = App.shutdown_host(host)
  end

  test "tooling and diagnostics distinguish host-backed execution from still-placeholder rendering" do
    run_output =
      capture_io(fn ->
        Mix.Task.reenable("app.start")
        Mix.Task.reenable("desktop_ui.run")
        Mix.Tasks.DesktopUi.Run.run(["native_foundational", "--format", "summary"])
      end)

    validate_output =
      capture_io(fn ->
        Mix.Task.reenable("app.start")
        Mix.Task.reenable("desktop_ui.validate")
        Mix.Tasks.DesktopUi.Validate.run(["--format", "summary"])
      end)

    assert run_output =~ "DesktopUi run summary"
    assert run_output =~ "backend:"
    assert run_output =~ "presented frame?: true"
    assert run_output =~ "renderer completeness:"
    assert run_output =~ "interactive visible execution?:"
    assert validate_output =~ "host execution surface passing?: true"
    assert DesktopUi.Validate.host_execution_surface().status == :pass
    assert DesktopUi.Info.sdl3_summary().renderer_completeness == :widget_complete_interactive
    refute DesktopUi.Sdl3.Renderer.contract().placeholder_draw_operations_allowed

    assert {:error, %Error{reason: :invalid_sdl3_protocol_magic}} =
             DesktopUi.Sdl3.Protocol.next_message("BADF000000")
  end
end
