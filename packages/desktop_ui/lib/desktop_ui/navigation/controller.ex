defmodule DesktopUi.Navigation.Controller do
  @moduledoc """
  GenServer that manages navigation state for screen-to-screen navigation.

  The controller maintains:
  - Current screen and params
  - History stack for back navigation
  - Forward stack for forward navigation
  - Modal stack independent from main navigation

  Applications typically start one controller per window that needs navigation.
  """

  use GenServer
  alias DesktopUi.Navigation.State

  @type opts :: [
          name: atom(),
          initial_screen: {atom(), module(), map()},
          registry: module()
        ]

  @type transition_result ::
          {:ok, State.t(),
           {:transition,
            :navigated | :replaced | :back | :forward | :modal_opened | :modal_closed}}
          | {:error, term()}

  # Client API

  @doc """
  Starts a new navigation controller.
  """
  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {name, start_opts} = Keyword.pop(opts, :name)

    gen_opts =
      if name, do: [name: name], else: []

    GenServer.start_link(__MODULE__, opts, gen_opts ++ start_opts)
  end

  @doc """
  Navigates to a screen, pushing the current screen to history.
  """
  @spec navigate(GenServer.server() | atom(), atom(), map()) :: transition_result()
  def navigate(server, screen_id, params \\ %{}) do
    GenServer.call(server, {:navigate, screen_id, params})
  end

  @doc """
  Replaces the current screen without modifying history.
  """
  @spec replace(GenServer.server() | atom(), atom(), map()) :: transition_result()
  def replace(server, screen_id, params \\ %{}) do
    GenServer.call(server, {:replace, screen_id, params})
  end

  @doc """
  Goes back to the previous screen in history.
  """
  @spec go_back(GenServer.server() | atom()) :: transition_result()
  def go_back(server) do
    GenServer.call(server, :go_back)
  end

  @doc """
  Goes forward to the next screen in the forward stack.
  """
  @spec go_forward(GenServer.server() | atom()) :: transition_result()
  def go_forward(server) do
    GenServer.call(server, :go_forward)
  end

  @doc """
  Opens a modal screen, adding it to the modal stack.
  """
  @spec open_modal(GenServer.server() | atom(), atom(), map()) :: transition_result()
  def open_modal(server, screen_id, params \\ %{}) do
    GenServer.call(server, {:open_modal, screen_id, params})
  end

  @doc """
  Closes the top modal screen.
  """
  @spec close_modal(GenServer.server() | atom(), atom() | nil) :: transition_result()
  def close_modal(server, screen_id \\ nil) do
    GenServer.call(server, {:close_modal, screen_id})
  end

  @doc """
  Gets the current navigation state.
  """
  @spec get_state(GenServer.server() | atom()) :: State.t()
  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  @doc """
  Gets the current screen tuple.
  """
  @spec current_screen(GenServer.server() | atom()) :: {atom(), module(), map()} | nil
  def current_screen(server) do
    server
    |> get_state()
    |> State.current_screen()
  end

  @doc """
  Stops the navigation controller.

  Used during runtime shutdown to clean up the navigation process.
  """
  @spec stop(GenServer.server() | atom()) :: :ok
  def stop(server) when is_pid(server) do
    if Process.alive?(server) do
      GenServer.stop(server, :normal, 5000)
    else
      :ok
    end
  end

  def stop(server) when is_atom(server) do
    if Process.whereis(server) do
      GenServer.stop(server, :normal, 5000)
    else
      :ok
    end
  end

  # Callbacks

  @impl true
  def init(opts) do
    registry = Keyword.get(opts, :registry)

    initial_state =
      case Keyword.get(opts, :initial_screen) do
        {screen_id, screen_module, params} when is_atom(screen_module) and screen_module != nil ->
          State.new(screen_id, screen_module, params)

        {screen_id, nil, params} ->
          # Resolve screen module from screen_id
          screen_module = resolve_screen_module(registry, screen_id)
          State.new(screen_id, screen_module, params)

        nil ->
          %State{}
      end

    state = %{
      nav_state: initial_state,
      registry: registry
    }

    {:ok, state}
  end

  # Resolve screen module for init (simpler version, doesn't return errors)
  defp resolve_screen_module(registry, screen_id) do
    case resolve_screen(registry, screen_id) do
      {:ok, module} -> module
      {:error, _reason} -> __MODULE__.MockScreen.module_for(screen_id)
    end
  end

  @impl true
  def handle_call({:navigate, screen_id, params}, _from, state) do
    case resolve_screen(state.registry, screen_id) do
      {:ok, screen_module} ->
        # Push current to history, set new current, clear forward
        new_nav = navigate_to(state.nav_state, screen_id, screen_module, params)
        {:reply, {:ok, new_nav, {:transition, :navigated}}, %{state | nav_state: new_nav}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:replace, screen_id, params}, _from, state) do
    case resolve_screen(state.registry, screen_id) do
      {:ok, screen_module} ->
        # Replace current without history modification
        new_nav = replace_current(state.nav_state, screen_id, screen_module, params)
        {:reply, {:ok, new_nav, {:transition, :replaced}}, %{state | nav_state: new_nav}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:go_back, _from, state) do
    case go_back_in(state.nav_state) do
      {:ok, new_nav} ->
        {:reply, {:ok, new_nav, {:transition, :back}}, %{state | nav_state: new_nav}}

      {:error, :empty_history} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:go_forward, _from, state) do
    case go_forward_in(state.nav_state) do
      {:ok, new_nav} ->
        {:reply, {:ok, new_nav, {:transition, :forward}}, %{state | nav_state: new_nav}}

      {:error, :empty_forward} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:open_modal, screen_id, params}, _from, state) do
    case resolve_screen(state.registry, screen_id) do
      {:ok, screen_module} ->
        new_nav = push_modal(state.nav_state, screen_id, screen_module, params)
        {:reply, {:ok, new_nav, {:transition, :modal_opened}}, %{state | nav_state: new_nav}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:close_modal, screen_id}, _from, state) do
    case pop_modal(state.nav_state, screen_id) do
      {:ok, new_nav} ->
        {:reply, {:ok, new_nav, {:transition, :modal_closed}}, %{state | nav_state: new_nav}}

      {:error, :no_modal} = error ->
        {:reply, error, state}

      {:error, {:unknown_modal, _screen_id}} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.nav_state, state}
  end

  # State transition functions

  defp navigate_to(%State{} = nav, screen_id, screen_module, params) do
    # Push current to history if exists
    history =
      case State.current_screen(nav) do
        nil -> []
        {id, mod, p} -> [{id, mod, p} | nav.history]
      end

    %State{
      nav
      | current: screen_id,
        current_module: screen_module,
        current_params: params,
        history: history,
        forward: []
    }
  end

  defp replace_current(%State{} = nav, screen_id, screen_module, params) do
    %State{
      nav
      | current: screen_id,
        current_module: screen_module,
        current_params: params
    }
  end

  defp go_back_in(%State{history: []}) do
    {:error, :empty_history}
  end

  defp go_back_in(%State{
         history: [prev | history_rest],
         current: curr,
         current_module: curr_mod,
         current_params: curr_params,
         forward: fwd
       }) do
    new_nav = %State{
      current: elem(prev, 0),
      current_module: elem(prev, 1),
      current_params: elem(prev, 2),
      history: history_rest,
      forward: [{curr, curr_mod, curr_params} | fwd],
      modal_open?: false
    }

    {:ok, new_nav}
  end

  defp go_forward_in(%State{forward: []}) do
    {:error, :empty_forward}
  end

  defp go_forward_in(%State{
         forward: [next | fwd_rest],
         current: curr,
         current_module: curr_mod,
         current_params: curr_params,
         history: hist
       }) do
    new_nav = %State{
      current: elem(next, 0),
      current_module: elem(next, 1),
      current_params: elem(next, 2),
      history: [{curr, curr_mod, curr_params} | hist],
      forward: fwd_rest,
      modal_open?: false
    }

    {:ok, new_nav}
  end

  defp push_modal(%State{} = nav, screen_id, screen_module, params) do
    modal_entry = {screen_id, screen_module, params}
    %State{nav | modals: [modal_entry | nav.modals], modal_open?: true}
  end

  defp pop_modal(%State{modals: []}, _screen_id) do
    {:error, :no_modal}
  end

  defp pop_modal(%State{} = nav, nil) do
    pop_top_modal(nav)
  end

  defp pop_modal(%State{} = nav, screen_id) do
    case remove_modal(nav.modals, screen_id) do
      {:ok, modals} ->
        {:ok, %{nav | modals: modals, modal_open?: modals != []}}

      :error ->
        {:error, {:unknown_modal, screen_id}}
    end
  end

  defp pop_top_modal(%State{modals: [_]} = nav) do
    # Last modal closed - preserve current screen fields
    {:ok, %{nav | modals: [], modal_open?: false}}
  end

  defp pop_top_modal(%State{modals: [_ | rest]} = nav) do
    # More modals remain
    {:ok, %{nav | modals: rest, modal_open?: true}}
  end

  defp remove_modal(modals, screen_id) do
    {kept, removed?} =
      Enum.reduce(modals, {[], false}, fn modal = {id, _module, _params}, {acc, removed?} ->
        if not removed? and key_matches?(id, screen_id) do
          {acc, true}
        else
          {[modal | acc], removed?}
        end
      end)

    if removed?, do: {:ok, Enum.reverse(kept)}, else: :error
  end

  defp key_matches?(key, value), do: key == value or to_string(key) == to_string(value)

  # Screen resolution

  defp resolve_screen(nil, screen_id) when is_atom(screen_id) do
    # No registry configured - check if screen_id is a module
    if Code.ensure_loaded?(screen_id) and function_exported?(screen_id, :module_info, 1) do
      {:ok, screen_id}
    else
      # For testing convenience, create a mock module from the atom
      # This allows tests to use atoms like :home, :detail without defining actual modules
      {:ok, __MODULE__.MockScreen.module_for(screen_id)}
    end
  end

  defp resolve_screen(nil, screen_id) when is_binary(screen_id) do
    # String screen IDs require a registry
    {:error, {:unknown_screen, screen_id}}
  end

  defp resolve_screen(registry, screen_id) when is_atom(registry) do
    if function_exported?(registry, :get_screen, 1) do
      case registry.get_screen(screen_id) do
        nil -> {:error, {:unknown_screen, screen_id}}
        module -> {:ok, module}
      end
    else
      {:error, {:invalid_registry, registry}}
    end
  end

  defp resolve_screen(_registry, _screen_id) do
    {:error, :invalid_registry_type}
  end

  # Helper module for testing
  defmodule MockScreen do
    @moduledoc false
    def module_for(atom) when is_atom(atom) do
      # Convert atom name to CamelCase module name
      # e.g., :confirm_dialog -> ConfirmDialog, :item_id -> ItemId
      name =
        atom
        |> Atom.to_string()
        |> String.split("_")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join()

      Module.concat(__MODULE__, name)
    end
  end
end
