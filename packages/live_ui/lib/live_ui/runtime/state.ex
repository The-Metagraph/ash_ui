defmodule LiveUi.Runtime.State do
  @moduledoc """
  Server-authoritative runtime state for mounted `live_ui` screens.

  Widget-local state is bounded to specific widget component instances and
  remains subordinate to server-authoritative screen or application state.
  """

  alias LiveUi.Runtime.{BrowserBridge, Error, Navigation}
  alias LiveUi.Widget.Identity

  @enforce_keys [:screen, :assigns, :mode, :event_routes, :bridge_hooks]
  defstruct [
    :screen,
    :assigns,
    :mode,
    :event_routes,
    :bridge_hooks,
    navigation: %{},
    widget_local_state: %{}
  ]

  @type mode :: :native | :canonical

  @type widget_local_state :: %{optional(Identity.key()) => map()}

  @type t :: %__MODULE__{
          screen: module(),
          assigns: map(),
          mode: mode(),
          event_routes: %{optional(String.t()) => atom()},
          bridge_hooks: [atom()],
          navigation: Navigation.t(),
          widget_local_state: widget_local_state()
        }

  @spec mount(module(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def mount(screen, opts \\ []) do
    with :ok <- validate_screen(screen),
         {:ok, defaults} <- normalize_defaults(screen, screen.mount_defaults()) do
      initial_assigns = Keyword.get(opts, :assigns, %{})

      {:ok,
       %__MODULE__{
         screen: screen,
         assigns: Map.merge(defaults, initial_assigns),
         mode: Keyword.get(opts, :mode, :native),
         event_routes: screen.event_routes(),
         bridge_hooks: BrowserBridge.normalize_hooks(screen.bridge_hooks()),
         navigation:
           Navigation.initialize(
             screen,
             Map.merge(defaults, initial_assigns),
             Keyword.get(opts, :mode, :native),
             opts
           )
       }
       |> sync_navigation_assigns()}
    end
  end

  @spec handle_event(t(), String.t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def handle_event(%__MODULE__{} = state, event, payload)
      when is_binary(event) and is_map(payload) do
    case Map.fetch(state.event_routes, event) do
      {:ok, route} ->
        apply_event(state, route, payload)

      :error ->
        {:error, Error.invalid_event_route(state.screen, event)}
    end
  end

  @spec handle_runtime_action(t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def handle_runtime_action(%__MODULE__{} = state, runtime_action) when is_map(runtime_action) do
    if Navigation.transition?(runtime_action) do
      Navigation.apply_transition(state, runtime_action)
    else
      handle_event(state, runtime_action.runtime_event, runtime_action.payload)
    end
  end

  @spec screen_id(t()) :: atom() | String.t() | nil
  def screen_id(%__MODULE__{navigation: navigation, screen: screen}) do
    Navigation.screen_id(navigation) || screen.id()
  end

  @spec screen_title(t()) :: String.t() | nil
  def screen_title(%__MODULE__{navigation: navigation, screen: screen}) do
    Navigation.screen_title(navigation) || screen.title()
  end

  @spec sync_navigation_assigns(t()) :: t()
  def sync_navigation_assigns(%__MODULE__{} = state) do
    navigation_assigns = Navigation.assign_overlays(state.navigation)

    %{
      state
      | assigns: Map.merge(Navigation.strip_managed_assigns(state.assigns), navigation_assigns)
    }
  end

  defp apply_event(%__MODULE__{} = state, route, payload) do
    case state.screen.handle_event(route, payload, state.assigns) do
      {:ok, updated_assigns} when is_map(updated_assigns) ->
        {:ok, %{state | assigns: updated_assigns} |> sync_navigation_assigns()}

      {:error, reason} ->
        {:error, Error.invalid_event_result(state.screen, route, {:error, reason})}

      other ->
        {:error, Error.invalid_event_result(state.screen, route, other)}
    end
  end

  defp validate_screen(screen) when is_atom(screen) do
    if Code.ensure_loaded?(screen) and function_exported?(screen, :id, 0) and
         function_exported?(screen, :mount_defaults, 0) and function_exported?(screen, :render, 1) and
         function_exported?(screen, :event_routes, 0) and
         function_exported?(screen, :bridge_hooks, 0) and
         function_exported?(screen, :handle_event, 3) do
      :ok
    else
      {:error, Error.invalid_screen_module(screen)}
    end
  end

  defp normalize_defaults(_screen, defaults) when is_map(defaults), do: {:ok, defaults}
  defp normalize_defaults(screen, _other), do: {:error, Error.invalid_mount_defaults(screen)}

  @doc """
  Gets the widget-local state for a given widget identity.

  Returns the stored widget-local state map, or an empty map if none exists.
  """
  @spec widget_local_state(t(), Identity.key() | Identity.t()) :: map()
  def widget_local_state(%__MODULE__{} = state, widget_key) when is_binary(widget_key) do
    Map.get(state.widget_local_state, widget_key, %{})
  end

  def widget_local_state(%__MODULE__{} = state, %Identity{} = widget_identity) do
    widget_local_state(state, Identity.key(widget_identity))
  end

  @doc """
  Puts widget-local state for a given widget identity.

  Replaces any existing widget-local state for the widget with the provided map.
  """
  @spec put_widget_local_state(t(), Identity.key() | Identity.t(), map()) :: t()
  def put_widget_local_state(%__MODULE__{} = state, widget_key, local_state)
      when is_binary(widget_key) and is_map(local_state) do
    %{state | widget_local_state: Map.put(state.widget_local_state, widget_key, local_state)}
  end

  def put_widget_local_state(%__MODULE__{} = state, %Identity{} = widget_identity, local_state) do
    put_widget_local_state(state, Identity.key(widget_identity), local_state)
  end

  @doc """
  Updates widget-local state for a given widget identity using a function.

  The function receives the current widget-local state (or an empty map if none exists)
  and must return the updated widget-local state map.
  """
  @spec update_widget_local_state(t(), Identity.key() | Identity.t(), (map() -> map())) :: t()
  def update_widget_local_state(%__MODULE__{} = state, widget_key, fun)
      when is_binary(widget_key) and is_function(fun, 1) do
    current_state = Map.get(state.widget_local_state, widget_key, %{})
    updated_state = fun.(current_state)
    put_widget_local_state(state, widget_key, updated_state)
  end

  def update_widget_local_state(%__MODULE__{} = state, %Identity{} = widget_identity, fun) do
    update_widget_local_state(state, Identity.key(widget_identity), fun)
  end

  @doc """
  Deletes widget-local state for a given widget identity.

  This is useful for cleanup when a widget is unmounted.
  """
  @spec delete_widget_local_state(t(), Identity.key() | Identity.t()) :: t()
  def delete_widget_local_state(%__MODULE__{} = state, widget_key) when is_binary(widget_key) do
    %{state | widget_local_state: Map.delete(state.widget_local_state, widget_key)}
  end

  def delete_widget_local_state(%__MODULE__{} = state, %Identity{} = widget_identity) do
    delete_widget_local_state(state, Identity.key(widget_identity))
  end

  @doc """
  Handles a widget-targeted event by routing it to the widget component's
  handle_widget_event callback and updating the widget-local state.

  The event payload should contain:
  - "widget_component" - The widget component module (as a string from inspect/1)
  - "widget_key" - The widget identity key
  - "widget_event" - The event name to route to the widget

  Returns {:ok, updated_state} on success, {:error, reason} on failure.
  """
  @spec handle_widget_event(t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def handle_widget_event(%__MODULE__{} = state, %{
        "widget_component" => widget_component_str,
        "widget_key" => widget_key,
        "widget_event" => widget_event
      }) do
    with {:ok, widget_component} <- parse_widget_component(widget_component_str),
         {:ok, current_local_state} <- fetch_widget_local_state(state, widget_key),
         {:ok, updated_local_state} <-
           apply_widget_event(widget_component, widget_event, %{}, current_local_state) do
      {:ok, put_widget_local_state(state, widget_key, updated_local_state)}
    else
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, Error.widget_event_failed(reason)}
    end
  end

  def handle_widget_event(%__MODULE__{}, _other) do
    {:error, Error.invalid_widget_event_payload()}
  end

  defp parse_widget_component(widget_component_str) when is_binary(widget_component_str) do
    try do
      {:ok, Code.eval_string(widget_component_str) |> elem(0)}
    rescue
      _ -> {:error, :invalid_widget_component}
    end
  end

  defp fetch_widget_local_state(%__MODULE__{} = state, widget_key) do
    {:ok, Map.get(state.widget_local_state, widget_key, %{})}
  end

  defp apply_widget_event(widget_component, event, payload, local_state) do
    # Convert event string to atom for the callback
    event_atom = if is_binary(event), do: String.to_existing_atom(event), else: event

    if function_exported?(widget_component, :handle_widget_event, 3) do
      case widget_component.handle_widget_event(event_atom, payload, local_state) do
        {:ok, updated_state} when is_map(updated_state) -> {:ok, updated_state}
        {:error, reason} -> {:error, reason}
        other -> {:error, {:invalid_event_result, other}}
      end
    else
      {:error, :widget_component_not_implemented}
    end
  rescue
    ArgumentError -> {:error, :invalid_event_name}
  end
end
