defmodule DesktopUi.Sdl3HostTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime.Error
  alias DesktopUi.Sdl3.{PortHost, Protocol}

  test "protocol frames and decodes control, frame, and resource messages deterministically" do
    frame_message =
      Protocol.new_message(
        :frame,
        :request,
        %{
          frame_request: %{runtime_id: "desktop-ui:workspace", window_count: 1},
          draw_operations: [%{widget_id: "workspace-window", draw_kind: :window_chrome}]
        },
        correlation_id: "boot-1",
        runtime_id: "desktop-ui:workspace",
        screen_id: "workspace",
        window_id: "window:workspace",
        channel: :control
      )

    assert {:ok, encoded} = Protocol.frame(frame_message)
    assert {:ok, decoded, ""} = Protocol.next_message(encoded)

    assert decoded.family == :frame
    assert decoded.kind == :request
    assert decoded.correlation_id == "boot-1"
    assert decoded.meta.runtime_id == "desktop-ui:workspace"
    assert hd(decoded.payload.draw_operations).widget_id == "workspace-window"

    resource_message =
      Protocol.new_message(
        :text,
        :request,
        %{content: "Workspace", font: "default-ui", size: 14},
        resource_kind: :font
      )

    assert {:ok, resource_frame} = Protocol.frame(resource_message)
    assert {:ok, resource_decoded, ""} = Protocol.next_message(resource_frame)
    assert resource_decoded.family == :text
    assert resource_decoded.meta.resource_kind == :font
  end

  test "protocol reports truncated frames and unsupported families deterministically" do
    message = Protocol.new_message(:boot, :request, %{runtime: %{id: "desktop-ui:workspace"}})
    assert {:ok, encoded} = Protocol.frame(message)

    assert :more = Protocol.next_message(binary_part(encoded, 0, byte_size(encoded) - 2))

    assert {:error, %Error{reason: :unsupported_sdl3_message_family}} =
             Protocol.frame(%{
               id: "dui-msg-invalid",
               family: :unknown,
               kind: :request,
               protocol: %{name: :desktop_ui_sdl3_host, version: 1},
               payload: %{},
               diagnostics: %{},
               meta: %{}
             })
  end

  test "port host launch specs and status expose transport, liveness, and protocol compatibility" do
    cat = System.find_executable("cat")
    assert is_binary(cat)

    spec = PortHost.launch_spec(executable: cat, args: [], protocol_version: 1)

    assert spec.transport == :port
    assert spec.protocol_version == 1

    assert {:ok, session} = PortHost.launch(executable: cat)
    status = PortHost.status(session)

    assert session.backend == :custom
    assert status.transport == :port
    assert status.backend == :custom
    assert status.protocol_version == 1
    assert status.version_compatible?
    assert status.liveness == :alive
    assert status.state == :running

    assert {:ok, session} = PortHost.shutdown(session)
    assert session.state == :stopped
  end

  test "port host can round-trip framed messages through a port transport" do
    cat = System.find_executable("cat")
    assert is_binary(cat)
    assert {:ok, session} = PortHost.launch(executable: cat)

    message =
      Protocol.new_message(
        :diagnostics,
        :report,
        %{status: :ok, presented_frames: 1},
        correlation_id: "frame-1",
        channel: :control
      )

    assert {:ok, session} = PortHost.send_message(session, message)
    assert {:ok, echoed, session} = PortHost.recv_message(session, 1_000)

    assert echoed.family == :diagnostics
    assert echoed.kind == :report
    assert echoed.correlation_id == "frame-1"
    assert echoed.payload.presented_frames == 1
    assert PortHost.status(session).messages_received == 1

    assert {:ok, _session} = PortHost.shutdown(session)
  end

  test "default launch spec falls back to elixir host until compiled host is probe-ready" do
    fallback_spec =
      PortHost.default_launch_spec(
        backend: :auto,
        capabilities: %{
          build: %{executable_present?: true, launch_ready?: false},
          libraries: %{},
          toolchains: %{}
        }
      )

    assert fallback_spec.backend == :elixir_host
    assert fallback_spec.requested_backend == :auto
    assert fallback_spec.launch_ready?

    compiled_spec =
      PortHost.default_launch_spec(
        backend: :auto,
        capabilities: %{
          build: %{executable_present?: true, launch_ready?: true},
          libraries: %{},
          toolchains: %{}
        }
      )

    assert compiled_spec.backend == :compiled_sdl3_host
    assert compiled_spec.requested_backend == :auto
    assert compiled_spec.launch_ready?
  end
end
