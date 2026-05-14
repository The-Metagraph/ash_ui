defmodule DesktopUi.Navigation.Signal do
  @moduledoc """
  Navigation-specific signal types for screen navigation.

  This module defines the canonical signal types for navigation actions
  that widgets can emit and that transport routes to the navigation controller.

  ## Navigation Signal Types

  * `:navigate_to` - Navigate to a screen (adds to history)
  * `:replace_with` - Replace current screen (no history entry)
  * `:go_back` - Go back in history
  * `:go_forward` - Go forward in history
  * `:open_modal` - Open a modal dialog
  * `:close_modal` - Close the top modal dialog

  ## Example

      # Create a navigate_to signal
      signal = Navigation.Signal.navigate(:detail, %{item_id: 123})

      # Create a go_back signal
      signal = Navigation.Signal.go_back()

  """

  alias DesktopUi.Navigation.State

  @type screen_id :: atom() | String.t()
  @type params :: map()
  @type navigation_signal :: %{
          __struct__: __MODULE__,
          type: atom(),
          screen_id: screen_id() | nil,
          params: params()
        }

  @type t :: %__MODULE__{
          type: atom(),
          screen_id: screen_id() | nil,
          params: params()
        }

  defstruct [:type, :screen_id, :params]

  @doc """
  Creates a navigate_to signal for navigating to a screen.

  ## Examples

      iex> Navigation.Signal.navigate(:detail, %{item_id: 123})
      %Navigation.Signal{type: :navigate_to, screen_id: :detail, params: %{item_id: 123}}

  """
  @spec navigate(screen_id(), params()) :: t()
  def navigate(screen_id, params \\ %{}) when is_atom(screen_id) or is_binary(screen_id) do
    %__MODULE__{
      type: :navigate_to,
      screen_id: screen_id,
      params: normalize_params(params)
    }
  end

  @doc """
  Creates a replace_with signal for replacing the current screen.

  ## Examples

      iex> Navigation.Signal.replace(:error, %{code: 404})
      %Navigation.Signal{type: :replace_with, screen_id: :error, params: %{code: 404}}

  """
  @spec replace(screen_id(), params()) :: t()
  def replace(screen_id, params \\ %{}) when is_atom(screen_id) or is_binary(screen_id) do
    %__MODULE__{
      type: :replace_with,
      screen_id: screen_id,
      params: normalize_params(params)
    }
  end

  @doc """
  Creates a go_back signal for going back in history.

  ## Examples

      iex> Navigation.Signal.go_back()
      %Navigation.Signal{type: :go_back, screen_id: nil, params: %{}}

  """
  @spec go_back() :: t()
  def go_back do
    %__MODULE__{
      type: :go_back,
      screen_id: nil,
      params: %{}
    }
  end

  @doc """
  Creates a go_forward signal for going forward in history.

  ## Examples

      iex> Navigation.Signal.go_forward()
      %Navigation.Signal{type: :go_forward, screen_id: nil, params: %{}}

  """
  @spec go_forward() :: t()
  def go_forward do
    %__MODULE__{
      type: :go_forward,
      screen_id: nil,
      params: %{}
    }
  end

  @doc """
  Creates an open_modal signal for opening a modal dialog.

  ## Examples

      iex> Navigation.Signal.open_modal(:confirm_dialog, %{message: "Are you sure?"})
      %Navigation.Signal{type: :open_modal, screen_id: :confirm_dialog, params: %{message: "Are you sure?"}}

  """
  @spec open_modal(screen_id(), params()) :: t()
  def open_modal(screen_id, params \\ %{}) when is_atom(screen_id) or is_binary(screen_id) do
    %__MODULE__{
      type: :open_modal,
      screen_id: screen_id,
      params: normalize_params(params)
    }
  end

  @doc """
  Creates a close_modal signal for closing the top modal dialog or a named
  modal.

  ## Examples

      iex> Navigation.Signal.close_modal()
      %Navigation.Signal{type: :close_modal, screen_id: nil, params: %{}}

  """
  @spec close_modal(screen_id() | nil) :: t()
  def close_modal(screen_id \\ nil) do
    %__MODULE__{
      type: :close_modal,
      screen_id: screen_id,
      params: %{}
    }
  end

  @doc """
  Creates a navigation signal from a map with type and optional screen_id/params.

  ## Examples

      iex> Navigation.Signal.from_map(%{type: :navigate_to, screen_id: :home, params: %{}})
      {:ok, %Navigation.Signal{type: :navigate_to, screen_id: :home, params: %{}}}

      iex> Navigation.Signal.from_map(%{type: :invalid})
      {:error, :unknown_navigation_type}

  """
  @spec from_map(map()) :: {:ok, t()} | {:error, atom()}
  def from_map(%{type: type} = map) when is_atom(type) do
    case type do
      :navigate_to ->
        {:ok, navigate(Map.get(map, :screen_id), Map.get(map, :params, %{}))}

      :replace_with ->
        {:ok, replace(Map.get(map, :screen_id), Map.get(map, :params, %{}))}

      :go_back ->
        {:ok, go_back()}

      :go_forward ->
        {:ok, go_forward()}

      :open_modal ->
        {:ok, open_modal(Map.get(map, :screen_id), Map.get(map, :params, %{}))}

      :close_modal ->
        {:ok, close_modal()}

      _ ->
        {:error, :unknown_navigation_type}
    end
  end

  def from_map(_), do: {:error, :invalid_signal_format}

  @doc """
  Validates a navigation signal.

  ## Examples

      iex> Navigation.Signal.validate(%Navigation.Signal{type: :navigate_to, screen_id: :home, params: %{}})
      :ok

      iex> Navigation.Signal.validate(%Navigation.Signal{type: :navigate_to, screen_id: nil, params: %{}})
      {:error, :screen_id_required}

  """
  @spec validate(t()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{type: type, screen_id: screen_id}) do
    cond do
      type not in [:navigate_to, :replace_with, :go_back, :go_forward, :open_modal, :close_modal] ->
        {:error, :unknown_navigation_type}

      type in [:navigate_to, :replace_with, :open_modal] and is_nil(screen_id) ->
        {:error, :screen_id_required}

      true ->
        :ok
    end
  end

  @doc """
  Executes a navigation signal against a navigation controller.

  ## Examples

      iex> {:ok, nav} = DesktopUi.Navigation.Controller.start_link(name: :test_nav, initial_screen: {:home, HomeScreen, %{}})
      iex> signal = Navigation.Signal.navigate(:detail, %{item_id: 1})
      iex> {:ok, _state, _transition} = Navigation.Signal.execute(signal, nav)

  """
  @spec execute(t(), GenServer.server()) :: {:ok, State.t(), atom()} | {:error, term()}
  def execute(%__MODULE__{type: :navigate_to, screen_id: screen_id, params: params}, controller) do
    DesktopUi.Navigation.Controller.navigate(controller, screen_id, params)
  end

  def execute(%__MODULE__{type: :replace_with, screen_id: screen_id, params: params}, controller) do
    DesktopUi.Navigation.Controller.replace(controller, screen_id, params)
  end

  def execute(%__MODULE__{type: :go_back}, controller) do
    DesktopUi.Navigation.Controller.go_back(controller)
  end

  def execute(%__MODULE__{type: :go_forward}, controller) do
    DesktopUi.Navigation.Controller.go_forward(controller)
  end

  def execute(%__MODULE__{type: :open_modal, screen_id: screen_id, params: params}, controller) do
    DesktopUi.Navigation.Controller.open_modal(controller, screen_id, params)
  end

  def execute(%__MODULE__{type: :close_modal, screen_id: screen_id}, controller) do
    DesktopUi.Navigation.Controller.close_modal(controller, screen_id)
  end

  # Private helpers

  defp normalize_params(params) when is_map(params), do: params
  defp normalize_params(params) when is_list(params), do: Map.new(params)
  defp normalize_params(_), do: %{}
end
