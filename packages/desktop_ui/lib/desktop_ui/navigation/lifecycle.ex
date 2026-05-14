defmodule DesktopUi.Navigation.Lifecycle do
  @moduledoc """
  Optional lifecycle callbacks that screen modules can implement.

  These callbacks allow screens to react to navigation events and manage
  their state lifecycle.
  """

  @doc """
  Called when a screen becomes the current screen.

  This allows screens to initialize state, subscribe to events, or prepare
  their UI before being displayed.

  Returning `{:cont, state}` continues with the provided state.
  Returning `{:halt, state}` cancels the navigation and keeps the current screen.
  """
  @callback on_mount(screen_id :: atom(), params :: map()) ::
              {:cont, map()} | {:halt, map()}

  @doc """
  Called when a screen is no longer the current screen.

  This allows screens to clean up resources, unsubscribe from events, or
  save state before being replaced.
  """
  @callback on_unmount(screen_id :: atom(), state :: map()) :: :ok

  @doc """
  Called when a navigation action is about to be executed.

  This allows screens to intercept navigation, validate transitions, or
  modify navigation parameters.

  Returning `{:cont, action}` allows the navigation to proceed.
  Returning `{:halt, state}` cancels the navigation with the given state.
  """
  @callback handle_navigation(
              from :: atom() | nil,
              to :: atom(),
              action :: atom(),
              params :: map()
            ) :: {:cont, keyword()} | {:halt, map()}

  @optional_callbacks on_mount: 2, on_unmount: 2, handle_navigation: 4

  @spec mount(module(), atom(), map()) :: {:ok, map()} | {:error, term()}
  def mount(screen_module, screen_id, params \\ %{}) do
    if function_exported?(screen_module, :on_mount, 2) do
      case screen_module.on_mount(screen_id, params) do
        {:cont, state} -> {:ok, state}
        {:halt, state} -> {:ok, state}
        other -> {:error, {:invalid_mount_result, other}}
      end
    else
      {:ok, %{}}
    end
  end

  @spec unmount(module(), atom(), map()) :: :ok
  def unmount(screen_module, screen_id, state) do
    if function_exported?(screen_module, :on_unmount, 2) do
      screen_module.on_unmount(screen_id, state)
    end

    :ok
  end

  @spec handle_transition(module(), atom(), atom(), atom(), map()) ::
          {:cont, map()} | {:halt, map()}
  def handle_transition(screen_module, from, to, action, params) do
    if function_exported?(screen_module, :handle_navigation, 4) do
      case screen_module.handle_navigation(from, to, action, params) do
        {:cont, opts} -> {:cont, Keyword.get(opts, :params, params)}
        {:halt, state} -> {:halt, state}
        other -> {:error, {:invalid_navigation_result, other}}
      end
    else
      {:cont, params}
    end
  end
end
