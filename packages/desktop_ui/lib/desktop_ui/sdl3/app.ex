defmodule DesktopUi.Sdl3.App do
  @moduledoc """
  SDL3-facing application ownership and runtime handoff helpers.
  """

  alias DesktopUi.Runtime
  alias DesktopUi.Runtime.State
  alias DesktopUi.Sdl3.{FrameEncoder, Lifecycle, PortHost, Protocol, RenderPlan, Window}
  alias UnifiedIUR.Element

  @type boot_request :: map()

  @spec callback_names() :: [Lifecycle.callback_name()]
  def callback_names, do: Lifecycle.callback_names()

  @spec lifecycle_contract() :: map()
  def lifecycle_contract do
    %{
      foundation: :sdl3,
      lifecycle: Lifecycle.contract(),
      package_application_takeover: false
    }
  end

  @spec handoff_contract() :: map()
  def handoff_contract do
    %{
      direct_native_and_canonical_share_runtime: true,
      runtime_handoff_shape: [:runtime, :windows, :frame_request, :lifecycle, :diagnostics],
      frame_backend: :sdl_renderer,
      logical_units_preserved: true
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :app_handoff_ready

  @spec boot_native_screen(map(), keyword()) :: {:ok, boot_request()} | {:error, term()}
  def boot_native_screen(screen, opts \\ []) when is_map(screen) do
    with {:ok, runtime_state} <- Runtime.mount_native_screen(screen, opts) do
      {:ok, boot_request(runtime_state, opts)}
    end
  end

  @spec boot_iur_screen(Element.t(), keyword()) :: {:ok, boot_request()} | {:error, term()}
  def boot_iur_screen(%Element{} = element, opts \\ []) do
    with {:ok, runtime_state} <- Runtime.mount_iur_screen(element, opts) do
      {:ok, boot_request(runtime_state, opts)}
    end
  end

  @spec boot_request(State.t(), keyword()) :: boot_request()
  def boot_request(%State{} = runtime_state, opts \\ []) do
    boot_request = runtime_handoff(runtime_state, opts)

    lifecycle =
      Lifecycle.scaffold()
      |> Lifecycle.begin_boot(%{
        runtime_id: boot_request.runtime.runtime_id,
        screen_id: boot_request.runtime.screen_id,
        platform_target: boot_request.runtime.platform_target
      })
      |> Lifecycle.record_callback(:app_init, :ready)
      |> Lifecycle.ready()

    %{
      foundation: :sdl3,
      binding: :sdl,
      runtime: boot_request.runtime,
      windows: boot_request.windows,
      frame_request: boot_request.frame_request,
      lifecycle: lifecycle,
      diagnostics: boot_request.diagnostics,
      validation_state: validation_state()
    }
  end

  @spec runtime_handoff(State.t(), keyword()) :: map()
  def runtime_handoff(%State{} = runtime_state, _opts \\ []) do
    {:ok, windows} = Window.registry(runtime_state)
    {:ok, render_plan} = RenderPlan.build(runtime_state)

    %{
      runtime: %{
        runtime_id: runtime_state.runtime_id,
        screen_id: runtime_state.screen_id,
        source_kind: runtime_state.source_kind,
        platform_target: runtime_state.platform_target,
        validation_state: runtime_state.validation_state,
        direct_native_and_canonical_share_runtime: true
      },
      windows: windows,
      frame_request: %{
        runtime_id: runtime_state.runtime_id,
        screen_id: runtime_state.screen_id,
        primary_window_id: windows.primary_id,
        redraw_status: runtime_state.redraw.status,
        redraw_reason: runtime_state.redraw.pending_reason || :initial_present,
        presentation: %{
          backend: :sdl_renderer,
          logical_units: :desktop_ui_layout,
          render_target: runtime_state.realization.mode,
          theme: runtime_state.realization.theme,
          render_plan: render_plan
        },
        validation_state: :render_plan_ready
      },
      diagnostics: %{
        screen_title: runtime_state.title,
        widget_count: runtime_state.screen.composition.widget_count,
        window_count: runtime_state.screen.composition.window_count,
        focus_targets: runtime_state.focus.order,
        event_loop_state: runtime_state.event_loop.routing_state,
        render_plan_validation_state: render_plan.presentation.validation_state
      }
    }
  end

  @spec launch_native_screen(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def launch_native_screen(screen, opts \\ []) when is_map(screen) do
    with {:ok, boot_request} <- boot_native_screen(screen, opts),
         {:ok, session} <- PortHost.launch_default(opts),
         {:ok, session} <- PortHost.send_message(session, boot_message(boot_request)),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)),
         {:ok, frame_ack, session} <- present_frame(session, boot_request.frame_request, opts) do
      {:ok,
       %{
         boot_request: boot_request,
         host: session,
         acknowledgement: ack,
         frame_acknowledgement: frame_ack
       }}
    end
  end

  @spec launch_iur_screen(Element.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def launch_iur_screen(%Element{} = element, opts \\ []) do
    with {:ok, boot_request} <- boot_iur_screen(element, opts),
         {:ok, session} <- PortHost.launch_default(opts),
         {:ok, session} <- PortHost.send_message(session, boot_message(boot_request)),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)),
         {:ok, frame_ack, session} <- present_frame(session, boot_request.frame_request, opts) do
      {:ok,
       %{
         boot_request: boot_request,
         host: session,
         acknowledgement: ack,
         frame_acknowledgement: frame_ack
       }}
    end
  end

  @spec present_frame(PortHost.t(), map(), keyword()) :: {:ok, map(), PortHost.t()} | {:error, term()}
  def present_frame(%PortHost{} = session, %{frame_request: frame_request}, opts) do
    present_frame(session, frame_request, opts)
  end

  def present_frame(%PortHost{} = session, %{presentation: %{render_plan: %RenderPlan{} = plan}} = frame_request, opts) do
    with {:ok, frame_payload} <- FrameEncoder.encode(plan),
         {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(
               :frame,
               :request,
               %{
                 frame: frame_payload,
                 redraw_status: frame_request.redraw_status,
                 redraw_reason: frame_request.redraw_reason,
                 primary_window_id: frame_request.primary_window_id
               },
               runtime_id: frame_payload.runtime_id,
               screen_id: frame_payload.screen_id,
               window_id: frame_request.primary_window_id,
               channel: :control
             )
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)) do
      {:ok, ack, session}
    end
  end

  @spec prepare_text_resource(PortHost.t(), String.t(), keyword()) ::
          {:ok, map(), PortHost.t()} | {:error, term()}
  def prepare_text_resource(%PortHost{} = session, content, opts \\ []) when is_binary(content) do
    payload = %{
      content: content,
      font: Keyword.get(opts, :font, "default-ui"),
      size: Keyword.get(opts, :size, 14),
      weight: Keyword.get(opts, :weight, :regular),
      resource_id: Keyword.get(opts, :resource_id)
    }

    with {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(:text, :request, payload, resource_kind: :font)
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)) do
      {:ok, ack, session}
    end
  end

  @spec prepare_image_resource(PortHost.t(), String.t(), keyword()) ::
          {:ok, map(), PortHost.t()} | {:error, term()}
  def prepare_image_resource(%PortHost{} = session, source, opts \\ []) when is_binary(source) do
    payload = %{
      source: source,
      size: Keyword.get(opts, :size, :original),
      resource_id: Keyword.get(opts, :resource_id)
    }

    with {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(:image, :request, payload, resource_kind: :image)
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)) do
      {:ok, ack, session}
    end
  end

  @spec dispatch_native_event(PortHost.t(), State.t(), keyword() | map(), keyword()) ::
          {:ok, State.t(), map(), PortHost.t()} | {:error, term()}
  def dispatch_native_event(%PortHost{} = session, %State{} = runtime_state, attrs, opts \\ [])
      when is_map(attrs) or is_list(attrs) do
    dispatch_native_events(session, runtime_state, [attrs], opts)
  end

  @spec dispatch_native_events(PortHost.t(), State.t(), [keyword() | map()], keyword()) ::
          {:ok, State.t(), map(), PortHost.t()} | {:error, term()}
  def dispatch_native_events(%PortHost{} = session, %State{} = runtime_state, events, opts)
      when is_list(events) do
    payload = %{
      events:
        Enum.map(events, fn
          event when is_map(event) -> event
          event when is_list(event) -> Enum.into(event, %{})
        end)
    }

    with {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(
               :events,
               :batch,
               payload,
               runtime_id: runtime_state.runtime_id,
               screen_id: runtime_state.screen_id,
               window_id: runtime_state.windows.primary
             )
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)),
         {:ok, next_state, route_results} <- apply_normalized_events(runtime_state, ack.payload.events) do
      {:ok, next_state, %{acknowledgement: ack, route_results: route_results}, session}
    end
  end

  @spec sync_windows(PortHost.t(), State.t(), keyword()) ::
          {:ok, map(), PortHost.t()} | {:error, term()}
  def sync_windows(%PortHost{} = session, %State{} = runtime_state, opts \\ []) do
    with {:ok, registry} <- Window.registry(runtime_state),
         {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(
               :window,
               :update,
               %{windows: registry, focus_window_id: registry.primary_id},
               runtime_id: runtime_state.runtime_id,
               screen_id: runtime_state.screen_id,
               window_id: registry.primary_id
             )
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)) do
      {:ok, ack, session}
    end
  end

  @spec shutdown_host(PortHost.t(), keyword()) :: {:ok, map(), PortHost.t()} | {:error, term()}
  def shutdown_host(%PortHost{} = session, opts \\ []) do
    with {:ok, session} <-
           PortHost.send_message(
             session,
             Protocol.new_message(:shutdown, :request, %{}, channel: :control)
           ),
         {:ok, ack, session} <- PortHost.recv_message(session, Keyword.get(opts, :timeout, 5_000)),
         {:ok, session} <- PortHost.shutdown(session) do
      {:ok, ack, session}
    end
  end

  defp boot_message(boot_request) do
    Protocol.new_message(
      :boot,
      :request,
      boot_request,
      runtime_id: boot_request.runtime.runtime_id,
      screen_id: boot_request.runtime.screen_id,
      window_id: boot_request.windows.primary_id
    )
  end

  defp apply_normalized_events(%State{} = runtime_state, events) do
    Enum.reduce_while(events, {:ok, runtime_state, []}, fn normalized, {:ok, state, route_results} ->
      case DesktopUi.Sdl3.Events.dispatch_normalized(state, normalized) do
        {:ok, next_state, route_result} ->
          {:cont, {:ok, next_state, route_results ++ [route_result]}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end
end
