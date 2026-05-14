defmodule DesktopUi.Sdl3.NativeHost do
  @moduledoc """
  Executable SDL3-host skeleton that owns callback lifecycle and native-window
  state behind the framed host protocol.
  """

  alias DesktopUi.Sdl3.{Events, Images, Lifecycle, Protocol, Renderer, Text}

  # Port-backed stdio reads block until the requested byte count is satisfied.
  # Read one byte at a time so framed host messages can be processed as soon as
  # a complete frame is available.
  @chunk_size 1

  @spec contract() :: map()
  def contract do
    %{
      lifecycle_model: :callback_oriented,
      host_runtime: :external_process,
      first_backend: :sdl_renderer,
      native_window_state: :host_owned,
      placeholder_windows_allowed: true
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :native_host_skeleton_ready

  @spec main() :: no_return()
  def main do
    :io.setopts(:standard_io, encoding: :latin1)

    state = %{
      lifecycle: Lifecycle.scaffold(),
      runtime: nil,
      windows: %{primary_id: nil, sessions: [], continuity: :single_window},
      platform_target: nil,
      presented_frames: 0,
      last_frame: nil,
      last_event_batch: nil,
      text_resources: %{},
      image_resources: %{}
    }

    loop(state, <<>>)
  end

  defp loop(state, buffer) do
    case Protocol.next_message(buffer) do
      {:ok, message, rest} ->
        {next_state, responses, halt?} = handle_message(state, message)
        Enum.each(responses, &write_message/1)

        if halt? do
          :erlang.halt(0)
        else
          loop(next_state, rest)
        end

      :more ->
        case IO.binread(:stdio, @chunk_size) do
          :eof ->
            :erlang.halt(0)

          {:error, reason} ->
            write_message(
              Protocol.error_envelope(:native_host_read_failed, %{reason: inspect(reason)})
            )

            :erlang.halt(1)

          chunk when is_binary(chunk) ->
            loop(state, buffer <> chunk)
        end

      {:error, error} ->
        write_message(
          Protocol.error_envelope(error.reason, error.details, diagnostics: %{phase: error.phase})
        )

        :erlang.halt(1)
    end
  end

  defp handle_message(state, %{family: :boot, kind: :request} = message) do
    payload = message.payload
    runtime = payload[:runtime] || %{}
    windows = payload[:windows] || %{}

    lifecycle =
      Lifecycle.scaffold()
      |> Lifecycle.begin_boot(%{
        runtime_id: runtime[:runtime_id],
        screen_id: runtime[:screen_id],
        platform_target: runtime[:platform_target]
      })
      |> Lifecycle.record_callback(:app_init, :ready)
      |> Lifecycle.record_callback(:app_event, :ready)
      |> Lifecycle.record_callback(:app_iterate, :ready)
      |> Lifecycle.ready()

    next_state = %{
      state
      | lifecycle: lifecycle,
        runtime: runtime,
        windows: normalize_windows(windows),
        platform_target: runtime[:platform_target]
    }

    response =
      Protocol.new_message(
        :boot,
        :ack,
        %{
          lifecycle: Lifecycle.diagnostics(lifecycle),
          host: %{
            backend: :sdl_renderer,
            runtime_state: :running,
            native_window_count: length(next_state.windows.sessions),
            validation_state: validation_state()
          },
          windows: %{
            primary_id: next_state.windows.primary_id,
            continuity: next_state.windows.continuity,
            session_ids: Enum.map(next_state.windows.sessions, & &1.id)
          }
        },
        correlation_id: message.id,
        runtime_id: runtime[:runtime_id],
        screen_id: runtime[:screen_id]
      )

    {next_state, [response], false}
  end

  defp handle_message(state, %{family: :window, kind: :update} = message) do
    windows = normalize_windows(message.payload[:windows] || %{})
    focus_window_id = message.payload[:focus_window_id] || windows.primary_id

    response =
      Protocol.new_message(
        :window,
        :ack,
        %{
          windows: %{
            primary_id: windows.primary_id,
            focus_window_id: focus_window_id,
            continuity: windows.continuity,
            session_ids: Enum.map(windows.sessions, & &1.id)
          }
        },
        correlation_id: message.id,
        runtime_id: get_in(state, [:runtime, :runtime_id]),
        screen_id: get_in(state, [:runtime, :screen_id]),
        window_id: focus_window_id
      )

    {%{state | windows: windows}, [response], false}
  end

  defp handle_message(state, %{family: :frame, kind: :request} = message) do
    frame = message.payload[:frame] || %{}
    redraw_status = message.payload[:redraw_status] || :requested

    {:ok, presentation} =
      Renderer.present_payload(
        frame,
        redraw_status: redraw_status,
        platform_target: state.platform_target
      )

    next_state = %{
      state
      | presented_frames: state.presented_frames + 1,
        last_frame: %{
          runtime_id: frame[:runtime_id],
          screen_id: frame[:screen_id],
          window_count: length(frame[:windows] || []),
          draw_operation_count: presentation.draw_operation_count,
          validation_state: presentation.validation_state
        }
    }

    response =
      Protocol.new_message(
        :frame,
        :ack,
        %{
          presentation: presentation,
          host: %{
            backend: :sdl_renderer,
            presented_frames: next_state.presented_frames,
            last_frame: next_state.last_frame
          }
        },
        correlation_id: message.id,
        runtime_id: frame[:runtime_id] || get_in(state, [:runtime, :runtime_id]),
        screen_id: frame[:screen_id] || get_in(state, [:runtime, :screen_id]),
        window_id: message.meta[:window_id] || state.windows.primary_id
      )

    {next_state, [response], false}
  end

  defp handle_message(state, %{family: :text, kind: :request} = message) do
    content = message.payload[:content] || ""
    text_opts = text_opts(message.payload)
    cache_key = Text.cache_key(content, text_opts)
    cached? = Map.has_key?(state.text_resources, cache_key)

    with {:ok, resource} <- Text.prepare(content, text_opts) do
      prepared_resource =
        resource
        |> Map.put(:resource_id, message.payload[:resource_id] || cache_key)
        |> Map.put(:cache_key, cache_key)

      next_state = put_in(state.text_resources[cache_key], prepared_resource)

      response =
        Protocol.new_message(
          :text,
          :ack,
          %{
            resource: prepared_resource,
            cached?: cached?,
            cache_size: map_size(next_state.text_resources)
          },
          correlation_id: message.id,
          runtime_id: get_in(state, [:runtime, :runtime_id]),
          screen_id: get_in(state, [:runtime, :screen_id]),
          resource_kind: :font
        )

      {next_state, [response], false}
    else
      {:error, details} ->
        response =
          Protocol.error_envelope(
            :text_resource_prepare_failed,
            %{details: details},
            correlation_id: message.id,
            runtime_id: get_in(state, [:runtime, :runtime_id]),
            screen_id: get_in(state, [:runtime, :screen_id]),
            resource_kind: :font
          )

        {state, [response], false}
    end
  end

  defp handle_message(state, %{family: :image, kind: :request} = message) do
    source = message.payload[:source] || ""
    image_opts = image_opts(message.payload)
    cache_key = Images.cache_key(source, image_opts)
    cached? = Map.has_key?(state.image_resources, cache_key)

    with {:ok, resource} <- Images.prepare(source, image_opts) do
      prepared_resource =
        resource
        |> Map.put(:resource_id, message.payload[:resource_id] || cache_key)
        |> Map.put(:cache_key, cache_key)

      next_state = put_in(state.image_resources[cache_key], prepared_resource)

      response =
        Protocol.new_message(
          :image,
          :ack,
          %{
            resource: prepared_resource,
            cached?: cached?,
            cache_size: map_size(next_state.image_resources)
          },
          correlation_id: message.id,
          runtime_id: get_in(state, [:runtime, :runtime_id]),
          screen_id: get_in(state, [:runtime, :screen_id]),
          resource_kind: :image
        )

      {next_state, [response], false}
    else
      {:error, details} ->
        response =
          Protocol.error_envelope(
            :image_resource_prepare_failed,
            %{details: details},
            correlation_id: message.id,
            runtime_id: get_in(state, [:runtime, :runtime_id]),
            screen_id: get_in(state, [:runtime, :screen_id]),
            resource_kind: :image
          )

        {state, [response], false}
    end
  end

  defp handle_message(state, %{family: :events, kind: :batch} = message) do
    events = List.wrap(message.payload[:events] || [])

    case Events.normalize_batch(events) do
      {:ok, normalized_events} ->
        route_summary =
          normalized_events
          |> Enum.map(fn event -> if event.boundary == :boundary, do: :canonical_boundary, else: :local_runtime end)
          |> Enum.frequencies()

        next_state = %{state | last_event_batch: normalized_events}

        response =
          Protocol.new_message(
            :events,
            :ack,
            %{
              events: normalized_events,
              route_summary: route_summary,
              batch_size: length(normalized_events)
            },
            correlation_id: message.id,
            runtime_id: get_in(state, [:runtime, :runtime_id]),
            screen_id: get_in(state, [:runtime, :screen_id]),
            window_id: message.meta[:window_id]
          )

        {next_state, [response], false}

      {:error, error} ->
        response =
          Protocol.error_envelope(
            :native_event_batch_failed,
            %{reason: error.reason, details: error.details},
            correlation_id: message.id,
            runtime_id: get_in(state, [:runtime, :runtime_id]),
            screen_id: get_in(state, [:runtime, :screen_id]),
            window_id: message.meta[:window_id]
          )

        {state, [response], false}
    end
  end

  defp handle_message(state, %{family: :shutdown, kind: :request} = message) do
    lifecycle =
      state.lifecycle
      |> Lifecycle.begin_shutdown()
      |> Lifecycle.record_callback(:app_quit, :ready)

    response =
      Protocol.new_message(
        :shutdown,
        :ack,
        %{
          lifecycle: Lifecycle.diagnostics(lifecycle),
          host: %{runtime_state: :stopped}
        },
        correlation_id: message.id,
        runtime_id: get_in(state, [:runtime, :runtime_id]),
        screen_id: get_in(state, [:runtime, :screen_id])
      )

    {%{state | lifecycle: lifecycle}, [response], true}
  end

  defp handle_message(state, %{family: :diagnostics} = message) do
    response =
      Protocol.new_message(
        :diagnostics,
        :ack,
        %{
          lifecycle: Lifecycle.diagnostics(state.lifecycle),
          windows: state.windows,
          platform_target: state.platform_target,
          presented_frames: state.presented_frames,
          last_frame: state.last_frame,
          last_event_batch: state.last_event_batch,
          text_resources: Map.keys(state.text_resources),
          image_resources: Map.keys(state.image_resources)
        },
        correlation_id: message.id,
        runtime_id: get_in(state, [:runtime, :runtime_id]),
        screen_id: get_in(state, [:runtime, :screen_id])
      )

    {state, [response], false}
  end

  defp handle_message(state, message) do
    response =
      Protocol.error_envelope(
        :unsupported_native_host_message,
        %{family: message.family, kind: message.kind},
        correlation_id: message.id,
        runtime_id: get_in(state, [:runtime, :runtime_id]),
        screen_id: get_in(state, [:runtime, :screen_id])
      )

    {state, [response], false}
  end

  defp normalize_windows(windows) do
    %{
      primary_id: windows[:primary_id],
      continuity: windows[:continuity] || :single_window,
      sessions:
        windows
        |> Map.get(:sessions, [])
        |> Enum.map(fn session ->
          %{
            id: session[:id],
            title: session[:title],
            role: session[:role],
            native_window?: session[:native_window?],
            window_identity: session[:window_identity],
            focus_order: session[:focus_order] || [],
            platform_target: session[:platform_target],
            owned_widget_ids: session[:owned_widget_ids] || [],
            owned_layer_ids: session[:owned_layer_ids] || []
          }
        end)
    }
  end

  defp write_message(message) do
    {:ok, frame} = Protocol.frame(message)
    IO.binwrite(:stdio, frame)
  end

  defp text_opts(payload) do
    [font: payload[:font], size: payload[:size], weight: payload[:weight]]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp image_opts(payload) do
    [size: payload[:size]]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end
end
