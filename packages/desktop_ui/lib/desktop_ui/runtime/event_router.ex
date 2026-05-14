defmodule DesktopUi.Runtime.EventRouter do
  @moduledoc """
  Deterministic routing between local desktop handling and canonical boundary
  translation.
  """

  alias DesktopUi.Runtime.{Error, State}

  @type route :: :local_runtime | :canonical_boundary

  @spec route(State.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def route(%State{} = state, translation) when is_map(translation) do
    with :ok <- validate_translation(translation) do
      {:ok,
       %{
         route: route_for(translation),
         runtime_id: state.runtime_id,
         screen_id: state.screen_id,
         family: translation.family,
         input_family: Map.get(translation, :input_family),
         runtime_event: translation.runtime_event,
         boundary: translation.boundary,
         local_handling: Map.get(translation, :local_handling),
         translation: translation
       }}
    end
  end

  def route(_state, _translation) do
    {:error, Error.new(:invalid_event_route, %{reason: :invalid_translation}, :event_routing)}
  end

  defp validate_translation(%{boundary: :boundary, signal: nil}) do
    {:error,
     Error.new(:missing_boundary_signal, %{reason: :boundary_signal_required}, :event_routing)}
  end

  defp validate_translation(%{family: family, boundary: boundary, runtime_event: runtime_event}) do
    if family in DesktopUi.Transport.families() and boundary in [:local, :boundary] and
         is_binary(runtime_event) and runtime_event != "" do
      :ok
    else
      {:error,
       Error.new(
         :invalid_event_route,
         %{family: family, boundary: boundary, runtime_event: runtime_event},
         :event_routing
       )}
    end
  end

  defp validate_translation(translation) do
    {:error, Error.new(:invalid_event_route, %{translation: translation}, :event_routing)}
  end

  defp route_for(%{boundary: :boundary}), do: :canonical_boundary
  defp route_for(_translation), do: :local_runtime
end
