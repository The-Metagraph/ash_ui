defmodule DesktopUi.Navigation do
  @moduledoc """
  Screen navigation subsystem for desktop_ui applications.

  This module provides the entry point for screen-to-screen navigation within
  windows, including history management, modal dialogs, and navigation actions.

  ## Navigation State

  Navigation state is managed by a `DesktopUi.Navigation.Controller` GenServer
  that maintains:
  - Current screen and params
  - History stack for back navigation
  - Forward stack for forward navigation
  - Modal stack independent from main navigation

  ## Starting a Controller

      # Without a registry (screen IDs must be modules)
      {:ok, pid} = DesktopUi.Navigation.Controller.start_link(
        name: :my_nav,
        initial_screen: {:home, HomeScreen, %{}}
      )

      # With a registry (screen IDs map to modules)
      {:ok, pid} = DesktopUi.Navigation.Controller.start_link(
        name: :my_nav,
        registry: MyApp.Screens,
        initial_screen: {:home, HomeScreen, %{}}
      )

  ## Navigation Actions

      # Navigate to a screen (adds to history)
      {:ok, _state, {:transition, :navigated}} =
        DesktopUi.Navigation.Controller.navigate(:my_nav, :detail, %{item_id: 123})

      # Replace current screen (no history entry)
      {:ok, _state, {:transition, :replaced}} =
        DesktopUi.Navigation.Controller.replace(:my_nav, :error, %{code: 404})

      # Go back in history
      {:ok, _state, {:transition, :back}} =
        DesktopUi.Navigation.Controller.go_back(:my_nav)

      # Go forward
      {:ok, _state, {:transition, :forward}} =
        DesktopUi.Navigation.Controller.go_forward(:my_nav)

      # Open a modal (independent stack)
      {:ok, _state, {:transition, :modal_opened}} =
        DesktopUi.Navigation.Controller.open_modal(:my_nav, :confirm_dialog, %{})

      # Close the top modal
      {:ok, _state, {:transition, :modal_closed}} =
        DesktopUi.Navigation.Controller.close_modal(:my_nav)

  ## Screen Registry

  Applications should implement a registry module that maps screen IDs to
  screen modules:

      defmodule MyApp.Screens do
        @doc "Returns the map of registered screens"
        def register do
          %{
            home: HomeScreen,
            list: ItemListScreen,
            detail: ItemDetailScreen,
            settings: SettingsScreen
          }
        end

        @doc "Lookup a screen module by ID"
        def get_screen(screen_id) do
          Map.get(register(), screen_id)
        end
      end

  """

  alias DesktopUi.Navigation.{Controller, Integration, Lifecycle, Registry, Signal, State}

  @type screen_id :: atom() | String.t()
  @type screen_module :: module()
  @type params :: map()
  @type transition :: {:transition, atom()}

  @doc """
  Returns the list of navigation modules.
  """
  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      Controller,
      Integration,
      Lifecycle,
      Registry,
      Signal,
      State
    ]
  end

  @doc """
  Returns the navigation capabilities.
  """
  @spec capabilities() :: [atom()]
  def capabilities do
    [
      :screen_navigation,
      :history_stack,
      :forward_stack,
      :modal_stack,
      :navigation_controller,
      :screen_registry
    ]
  end

  @doc """
  Creates a new navigation state struct.
  """
  @spec new_state(screen_id(), screen_module(), params()) :: State.t()
  def new_state(screen_id, screen_module, params \\ %{}) do
    State.new(screen_id, screen_module, params)
  end

  @doc """
  Starts a navigation controller with the given options.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  defdelegate start_link(opts), to: Controller

  @doc """
  Navigates to a screen.
  """
  @spec navigate(GenServer.server() | atom(), screen_id(), params()) ::
          {:ok, State.t(), transition()} | {:error, term()}
  defdelegate navigate(server, screen_id, params \\ %{}), to: Controller

  @doc """
  Replaces the current screen.
  """
  @spec replace(GenServer.server() | atom(), screen_id(), params()) ::
          {:ok, State.t(), transition()} | {:error, term()}
  defdelegate replace(server, screen_id, params \\ %{}), to: Controller

  @doc """
  Goes back in history.
  """
  @spec go_back(GenServer.server() | atom()) ::
          {:ok, State.t(), transition()} | {:error, term()}
  defdelegate go_back(server), to: Controller

  @doc """
  Goes forward in history.
  """
  @spec go_forward(GenServer.server() | atom()) ::
          {:ok, State.t(), transition()} | {:error, term()}
  defdelegate go_forward(server), to: Controller

  @doc """
  Opens a modal dialog.
  """
  @spec open_modal(GenServer.server() | atom(), screen_id(), params()) ::
          {:ok, State.t(), transition()} | {:error, term()}
  defdelegate open_modal(server, screen_id, params \\ %{}), to: Controller

  @doc """
  Closes the top modal dialog.
  """
  @spec close_modal(GenServer.server() | atom(), screen_id() | nil) ::
          {:ok, State.t(), transition()} | {:error, term()}
  def close_modal(server, screen_id \\ nil), do: Controller.close_modal(server, screen_id)

  @doc """
  Gets the current navigation state.
  """
  @spec get_state(GenServer.server() | atom()) :: State.t()
  defdelegate get_state(server), to: Controller

  @doc """
  Gets the current screen tuple.
  """
  @spec current_screen(GenServer.server() | atom()) ::
          {screen_id(), screen_module(), params()} | nil
  defdelegate current_screen(server), to: Controller

  @doc """
  Checks if back navigation is available.
  """
  @spec can_go_back?(State.t()) :: boolean()
  defdelegate can_go_back?(state), to: State, as: :can_go_back?

  @doc """
  Checks if forward navigation is available.
  """
  @spec can_go_forward?(State.t()) :: boolean()
  defdelegate can_go_forward?(state), to: State, as: :can_go_forward?

  @doc """
  Checks if a modal is currently open.
  """
  @spec modal_open?(State.t()) :: boolean()
  defdelegate modal_open?(state), to: State, as: :modal_open?

  @doc """
  Returns the top modal entry for the given state.
  """
  @spec top_modal(State.t()) :: {screen_id(), screen_module(), params()} | nil
  defdelegate top_modal(state), to: State

  @doc """
  Returns the number of open modals in the given state.
  """
  @spec modal_depth(State.t()) :: non_neg_integer()
  defdelegate modal_depth(state), to: State
end
