defmodule DesktopUi.Sdl3.Events do
  @moduledoc """
  SDL3-native event normalization and runtime dispatch helpers.
  """

  alias DesktopUi.Runtime
  alias DesktopUi.Runtime.{Error, State}

  @event_types [
    :drag_begin,
    :focus_changed,
    :keyboard_key_down,
    :pointer_button,
    :pointer_hover,
    :wheel_scrolled,
    :window_activated
  ]

  @spec event_types() :: [atom()]
  def event_types, do: @event_types

  @spec contract() :: map()
  def contract do
    %{
      foundation: :sdl3,
      event_types: event_types(),
      normalized_input_families: [:keyboard, :pointer, :focus, :window],
      richer_pointer_inputs: [:hover, :wheel, :drag_begin],
      multiwindow_routing: :window_registry_required
    }
  end

  @spec normalize(keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def normalize(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_map(attrs)

    with {:ok, event_type} <- resolve_event_type(attrs) do
      {:ok, normalized_event(attrs, event_type)}
    end
  end

  def normalize(value) do
    {:error, Error.new(:unsupported_sdl3_event_payload, %{payload: value}, :sdl3_events)}
  end

  @spec normalize_batch([keyword() | map()]) :: {:ok, [map()]} | {:error, Error.t()}
  def normalize_batch(events) when is_list(events) do
    Enum.reduce_while(events, {:ok, []}, fn attrs, {:ok, acc} ->
      case normalize(attrs) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
  end

  def normalize_batch(value) do
    {:error, Error.new(:unsupported_sdl3_event_payload, %{payload: value}, :sdl3_events)}
  end

  @spec dispatch(State.t(), keyword() | map()) :: {:ok, State.t(), map()} | {:error, Error.t()}
  def dispatch(%State{} = runtime_state, attrs) when is_map(attrs) or is_list(attrs) do
    with {:ok, normalized} <- normalize(attrs),
         {:ok, next_state, route_result} <- dispatch_normalized(runtime_state, normalized) do
      {:ok, next_state, route_result}
    end
  end

  def dispatch(%State{} = _runtime_state, value) do
    {:error, Error.new(:unsupported_sdl3_event_payload, %{payload: value}, :sdl3_events)}
  end

  @spec dispatch_normalized(State.t(), map()) :: {:ok, State.t(), map()} | {:error, Error.t()}
  def dispatch_normalized(%State{} = runtime_state, normalized) when is_map(normalized) do
    with :ok <- validate_window_route(runtime_state, normalized),
         :ok <- validate_focus_transition(runtime_state, normalized),
         {:ok, next_state, route_result} <- Runtime.dispatch_native_event(runtime_state, normalized) do
      {:ok, next_state, Map.put(route_result, :normalized_event, normalized)}
    end
  end

  @spec diagnostics(keyword() | map()) :: map()
  def diagnostics(attrs) when is_map(attrs) or is_list(attrs) do
    case normalize(attrs) do
      {:ok, normalized} ->
        %{
          status: :ok,
          contract: contract(),
          normalized: normalized
        }

      {:error, %Error{} = error} ->
        %{
          status: :error,
          contract: contract(),
          error: error
        }
    end
  end

  defp normalized_event(attrs, :keyboard_key_down) do
    %{
      input_family: :keyboard,
      family: Map.get(attrs, :family, :change),
      key: Map.get(attrs, :key),
      text: Map.get(attrs, :text),
      modifiers: List.wrap(Map.get(attrs, :modifiers, [])),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.get(attrs, :payload, %{}),
      runtime_event: Map.get(attrs, :runtime_event, "keyboard:key_down"),
      intent: Map.get(attrs, :intent, :keyboard_input),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :pointer_button) do
    %{
      input_family: :pointer,
      family: Map.get(attrs, :family, :click),
      pointer_action: Map.get(attrs, :pointer_action, :click),
      button: Map.get(attrs, :button, :left),
      pointer: normalize_map(Map.get(attrs, :pointer, %{})),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.get(attrs, :payload, %{}),
      runtime_event: Map.get(attrs, :runtime_event, "pointer:button"),
      intent: Map.get(attrs, :intent, :pointer_button),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :wheel_scrolled) do
    %{
      input_family: :pointer,
      family: Map.get(attrs, :family, :navigation),
      pointer_action: :scroll,
      button: nil,
      pointer: normalize_map(Map.get(attrs, :pointer, %{})),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload:
        Map.merge(%{wheel: %{x: Map.get(attrs, :delta_x, 0), y: Map.get(attrs, :delta_y, 0)}}, Map.get(attrs, :payload, %{})),
      runtime_event: Map.get(attrs, :runtime_event, "pointer:wheel"),
      intent: Map.get(attrs, :intent, :scroll_viewport),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :pointer_hover) do
    %{
      input_family: :pointer,
      family: Map.get(attrs, :family, :navigation),
      pointer_action: :move,
      button: nil,
      pointer: normalize_map(Map.get(attrs, :pointer, %{})),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.merge(%{hover: true}, Map.get(attrs, :payload, %{})),
      runtime_event: Map.get(attrs, :runtime_event, "pointer:hover"),
      intent: Map.get(attrs, :intent, :hover_widget),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :drag_begin) do
    %{
      input_family: :pointer,
      family: Map.get(attrs, :family, :selection),
      pointer_action: :select,
      button: Map.get(attrs, :button, :left),
      pointer: normalize_map(Map.get(attrs, :pointer, %{})),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.merge(%{drag: :begin}, Map.get(attrs, :payload, %{})),
      runtime_event: Map.get(attrs, :runtime_event, "pointer:drag_begin"),
      intent: Map.get(attrs, :intent, :begin_drag),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :focus_changed) do
    focus_target = Map.get(attrs, :focus_target)

    %{
      input_family: :focus,
      family: :focus,
      focus_target: focus_target,
      focused: Map.get(attrs, :focused, true),
      widget_id: Map.get(attrs, :widget_id, focus_target),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.get(attrs, :payload, %{}),
      runtime_event: Map.get(attrs, :runtime_event, "focus:changed"),
      intent: Map.get(attrs, :intent, :focus_widget),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp normalized_event(attrs, :window_activated) do
    %{
      input_family: :window,
      family: Map.get(attrs, :family, :navigation),
      window_action: Map.get(attrs, :window_action, :activate),
      widget_id: Map.get(attrs, :widget_id),
      window_id: Map.get(attrs, :window_id),
      runtime_id: Map.get(attrs, :runtime_id),
      screen: Map.get(attrs, :screen),
      platform_target: Map.get(attrs, :platform_target, :linux),
      source_kind: Map.get(attrs, :source_kind, :native),
      payload: Map.get(attrs, :payload, %{}),
      runtime_event: Map.get(attrs, :runtime_event, "window:activated"),
      intent: Map.get(attrs, :intent, :activate_window),
      boundary: Map.get(attrs, :boundary, :local)
    }
  end

  defp resolve_event_type(attrs) do
    case Map.get(attrs, :type) do
      event_type when event_type in @event_types ->
        {:ok, event_type}

      event_type when is_binary(event_type) ->
        atom = String.to_atom(event_type)

        if atom in @event_types do
          {:ok, atom}
        else
          {:error, Error.new(:unsupported_sdl3_event_type, %{event_type: event_type}, :sdl3_events)}
        end

      event_type ->
        {:error, Error.new(:unsupported_sdl3_event_type, %{event_type: event_type}, :sdl3_events)}
    end
  end

  defp validate_window_route(%State{} = runtime_state, normalized) do
    case Map.get(normalized, :window_id) do
      nil ->
        :ok

      window_id ->
        if Map.has_key?(runtime_state.windows.registry, window_id) do
          :ok
        else
          {:error,
           Error.new(
             :mismatched_window_local_event_routing,
             %{window_id: window_id, known_window_ids: Map.keys(runtime_state.windows.registry)},
             :sdl3_events
           )}
        end
    end
  end

  defp validate_focus_transition(%State{} = runtime_state, %{input_family: :focus} = normalized) do
    focus_target = Map.get(normalized, :focus_target) || Map.get(normalized, :widget_id)

    if is_nil(focus_target) or focus_target in runtime_state.focus.order do
      :ok
    else
      {:error,
       Error.new(
         :invalid_focus_transition,
         %{focus_target: focus_target, known_focus_targets: runtime_state.focus.order},
         :sdl3_events
       )}
    end
  end

  defp validate_focus_transition(%State{} = _runtime_state, _normalized), do: :ok

  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)

  defp normalize_map(attrs) when is_list(attrs) do
    attrs
    |> Enum.map(fn
      {key, value} -> {key, value}
      [key, value] -> {key, value}
    end)
    |> Enum.into(%{})
  end
end
