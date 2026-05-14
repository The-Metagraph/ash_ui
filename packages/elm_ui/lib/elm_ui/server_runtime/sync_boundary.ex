defmodule ElmUi.ServerRuntime.SyncBoundary do
  @moduledoc """
  Server-side synchronization boundary for Phoenix-to-Elm envelopes.
  """

  alias ElmUi.FrontendRuntime.Message
  alias ElmUi.ServerRuntime.{Error, State, ViewState}
  alias ElmUi.Transport
  alias ElmUi.Transport.Diagnostics, as: TransportDiagnostics
  alias ElmUi.Transport.Error, as: TransportError

  @spec hydration_envelope(State.t()) :: map()
  def hydration_envelope(%State{} = state) do
    Message.new(:hydrate, ViewState.to_frontend_payload(state),
      runtime_id: state.runtime_id,
      source_kind: state.source_kind
    )
  end

  @spec receive_frontend_message(State.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def receive_frontend_message(%State{} = state, payload) when is_map(payload) do
    case Message.from_payload(payload) do
      {:ok, %{kind: :event} = message} ->
        {:ok, Map.put(message, :runtime_id, state.runtime_id)}

      {:ok, %{kind: :ack} = message} ->
        {:ok, Map.put(message, :runtime_id, state.runtime_id)}

      {:ok, %{kind: kind}} ->
        {:error,
         Error.new(:unsupported_frontend_message, "Unsupported frontend message kind", %{
           kind: kind
         })}

      {:error, reason} ->
        {:error,
         Error.new(:unsupported_frontend_message, "Invalid frontend message", %{reason: reason})}
    end
  end

  def receive_frontend_message(_state, _payload) do
    {:error,
     Error.new(:unsupported_frontend_message, "Expected frontend message payload to be a map")}
  end

  @spec translation_for_message(State.t(), Message.t()) :: {:ok, map()} | {:error, Error.t()}
  def translation_for_message(%State{} = state, %{
        kind: :event,
        payload: payload,
        metadata: metadata
      })
      when is_map(payload) do
    payload =
      payload
      |> normalize_map()
      |> Map.put_new(:runtime_id, state.runtime_id)
      |> Map.put_new(:screen, state.screen_id)
      |> Map.put_new(:source_kind, state.source_kind)
      |> Map.put_new(:boundary_mode, state.boundary_mode)

    with :ok <- TransportDiagnostics.validate_frontend_payload(payload) do
      case normalize_boundary(fetch(payload, :boundary)) do
        :boundary ->
          boundary_signal = fetch(payload, :cloud_event) || fetch(payload, :signal)

          if is_nil(boundary_signal) do
            {:error,
             Error.new(
               :missing_boundary_signal,
               "Boundary frontend events must include a canonical boundary envelope"
             )}
          else
            case Transport.from_boundary_signal(boundary_signal) do
              {:ok, translation} ->
                {:ok,
                 translation
                 |> Map.update(
                   :metadata,
                   normalize_map(metadata),
                   &Map.merge(&1, normalize_map(metadata))
                 )
                 |> Map.put_new(:runtime_id, state.runtime_id)
                 |> Map.put_new(:screen, state.screen_id)}

              {:error, %TransportError{} = error} ->
                {:error,
                 Error.new(:invalid_boundary_translation, error.message, %{
                   reason: error.reason,
                   transport_details: error.details
                 })}

              {:error, reason} ->
                {:error,
                 Error.new(
                   :invalid_boundary_translation,
                   "Unable to translate boundary frontend event",
                   %{
                     reason: reason
                   }
                 )}
            end
          end

        _local ->
          case Transport.from_native_event(local_event_attrs(payload, metadata)) do
            {:ok, translation} ->
              {:ok, translation}

            {:error, %TransportError{} = error} ->
              {:error,
               Error.new(:invalid_local_event, error.message, %{
                 reason: error.reason,
                 transport_details: error.details
               })}

            {:error, reason} ->
              {:error,
               Error.new(:invalid_local_event, "Unable to translate frontend event", %{
                 reason: reason
               })}
          end
      end
    else
      {:error, %TransportError{} = error} ->
        {:error,
         Error.new(:invalid_frontend_payload, error.message, %{
           reason: error.reason,
           transport_details: error.details
         })}
    end
  end

  def translation_for_message(_state, %{kind: kind}) do
    {:error,
     Error.new(:unsupported_frontend_message, "Expected an event message at the sync boundary", %{
       kind: kind
     })}
  end

  @spec acknowledgement_envelope(State.t(), map()) :: map()
  def acknowledgement_envelope(%State{} = state, translation) when is_map(translation) do
    Message.new(
      :ack,
      %{
        runtime_id: state.runtime_id,
        screen_id: state.screen_id,
        family: translation.family,
        intent: translation.intent,
        boundary: translation.boundary,
        runtime_event: translation.runtime_event,
        event_count: length(state.event_log),
        server_authority: true,
        diagnostics: state.diagnostics,
        authoritative_screen: ViewState.authoritative_screen_payload(state)
      },
      %{
        source_kind: state.source_kind,
        boundary_mode: state.boundary_mode
      }
    )
  end

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_value), do: %{}

  defp normalize_boundary(:boundary), do: :boundary
  defp normalize_boundary("boundary"), do: :boundary
  defp normalize_boundary(_value), do: :local

  defp local_event_attrs(payload, metadata) do
    %{
      family: fetch(payload, :family),
      intent: fetch(payload, :intent),
      boundary: :local,
      runtime_event: fetch(payload, :runtime_event),
      metadata: normalize_map(metadata),
      payload: fetch(payload, :payload),
      target: fetch(payload, :target, %{}),
      widget_id:
        fetch(payload, :widget_id) || fetch(fetch(payload, :native_event, %{}), :widget_id),
      runtime_id: fetch(payload, :runtime_id),
      screen: fetch(payload, :screen),
      source_kind: fetch(payload, :source_kind),
      boundary_mode: fetch(payload, :boundary_mode)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp fetch(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp fetch(map, key, default) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || default
  end
end
