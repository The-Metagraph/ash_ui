defmodule DesktopUi.Navigation.Integration do
  @moduledoc """
  Integration layer for navigation with the runtime.

  This module provides functions for integrating the navigation controller
  with the runtime event system, including handling navigation signals and
  updating runtime state.

  ## Screen Swapping

  When navigation occurs, the root widget tree is swapped to display the
  new screen while preserving window state (position, size, focus).

  ## Modal Rendering

  When a modal is open, the modal screen widgets are layered above the
  current screen content with backdrop and focus trapping.

  """

  alias DesktopUi.Navigation.{Controller, Signal, State}
  alias DesktopUi.Runtime.State, as: RuntimeState

  @type navigation_result :: {:ok, RuntimeState.t(), State.t(), atom()} | {:error, term()}

  @doc """
  Handles a navigation event from the runtime.

  Processes navigation signals and updates the runtime state with the
  new navigation state.

  ## Examples

      iex> {:ok, new_runtime, nav_state, transition} =
      ...>   Navigation.Integration.handle_navigation(
      ...>     runtime_state,
      ...>     %Signal{type: :navigate_to, screen_id: :detail, params: %{item_id: 1}}
      ...>   )

  """
  @spec handle_navigation(RuntimeState.t(), Signal.t()) :: navigation_result()
  def handle_navigation(%RuntimeState{navigation_controller: nil}, _signal) do
    {:error, :no_navigation_controller}
  end

  def handle_navigation(%RuntimeState{} = runtime, %Signal{} = signal) do
    case Signal.execute(signal, runtime.navigation_controller) do
      {:ok, nav_state, {:transition, _transition}} = result ->
        {:ok, update_runtime_for_navigation(runtime, nav_state), nav_state, elem(result, 2)}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Handles navigation from an event payload.

  Extracts navigation parameters from an event and processes the navigation.

  ## Examples

      iex> event = %{family: :navigation, type: :navigate_to, screen_id: :detail, params: %{}}
      iex> {:ok, new_runtime, _nav_state, _transition} =
      ...>   Navigation.Integration.handle_event(runtime, event)

  """
  @spec handle_event(RuntimeState.t(), map()) :: navigation_result()
  def handle_event(%RuntimeState{} = runtime, event) when is_map(event) do
    case signal_from_event(event) do
      {:ok, signal} -> handle_navigation(runtime, signal)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Checks if a runtime event is a navigation event.

  ## Examples

      iex> Navigation.Integration.navigation_event?(%{family: :navigation, type: :navigate_to})
      true

      iex> Navigation.Integration.navigation_event?(%{family: :click})
      false

  """
  @spec navigation_event?(map()) :: boolean()
  def navigation_event?(event) when is_map(event) do
    Map.get(event, :family) == :navigation
  end

  @doc """
  Gets the current screen module from the runtime state.

  """
  @spec current_screen_module(RuntimeState.t()) :: module() | nil
  def current_screen_module(%RuntimeState{current_screen_module: module}), do: module

  @doc """
  Gets the current screen params from the runtime state.

  """
  @spec current_screen_params(RuntimeState.t()) :: map()
  def current_screen_params(%RuntimeState{screen_params: params}), do: params

  @doc """
  Checks if a modal is currently open.

  """
  @spec modal_open?(RuntimeState.t()) :: boolean()
  def modal_open?(%RuntimeState{navigation_state: nil}), do: false

  def modal_open?(%RuntimeState{navigation_state: %State{modal_open?: open?}}), do: open?

  @doc """
  Gets the current modal screen if one is open.

  """
  @spec current_modal(RuntimeState.t()) :: {atom(), module(), map()} | nil
  def current_modal(%RuntimeState{navigation_state: nil}), do: nil

  def current_modal(%RuntimeState{navigation_state: %State{modals: []}}), do: nil

  def current_modal(%RuntimeState{navigation_state: %State{modals: [{id, mod, params} | _]}}) do
    {id, mod, params}
  end

  @doc """
  Checks if back navigation is available.

  """
  @spec can_go_back?(RuntimeState.t()) :: boolean()
  def can_go_back?(%RuntimeState{navigation_state: nil}), do: false

  def can_go_back?(%RuntimeState{navigation_state: nav_state}) do
    State.can_go_back?(nav_state)
  end

  @doc """
  Checks if forward navigation is available.

  """
  @spec can_go_forward?(RuntimeState.t()) :: boolean()
  def can_go_forward?(%RuntimeState{navigation_state: nil}), do: false

  def can_go_forward?(%RuntimeState{navigation_state: nav_state}) do
    State.can_go_forward?(nav_state)
  end

  @doc """
  Stops the navigation controller when the runtime shuts down.

  """
  @spec shutdown(RuntimeState.t()) :: :ok
  def shutdown(%RuntimeState{navigation_controller: nil}), do: :ok

  def shutdown(%RuntimeState{navigation_controller: controller}) when is_pid(controller) do
    if Process.alive?(controller) do
      Controller.stop(controller)
    else
      :ok
    end
  end

  # Private functions

  defp signal_from_event(%{family: :navigation, type: type} = event)
       when is_atom(type) do
    screen_id = Map.get(event, :screen_id)
    params = Map.get(event, :params, %{})

    case type do
      :navigate_to ->
        if screen_id do
          {:ok, Signal.navigate(screen_id, params)}
        else
          {:error, :missing_screen_id}
        end

      :replace_with ->
        if screen_id do
          {:ok, Signal.replace(screen_id, params)}
        else
          {:error, :missing_screen_id}
        end

      :go_back ->
        {:ok, Signal.go_back()}

      :go_forward ->
        {:ok, Signal.go_forward()}

      :open_modal ->
        if screen_id do
          {:ok, Signal.open_modal(screen_id, params)}
        else
          {:error, :missing_screen_id}
        end

      :close_modal ->
        {:ok, Signal.close_modal()}

      _ ->
        {:error, :unknown_navigation_type}
    end
  end

  defp signal_from_event(_event), do: {:error, :not_a_navigation_event}

  defp update_runtime_for_navigation(%RuntimeState{} = runtime, %State{} = nav_state) do
    # Extract current screen from navigation state
    {_screen_id, screen_module, params} = State.current_screen(nav_state)

    %RuntimeState{
      runtime
      | navigation_state: nav_state,
        current_screen_module: screen_module,
        screen_params: params
    }
  end
end
