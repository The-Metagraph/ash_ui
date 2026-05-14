defmodule DesktopUi.Navigation.State do
  @moduledoc """
  Navigation state for screen-to-screen navigation within desktop_ui windows.

  This struct manages the navigation state independent of window state, allowing
  windows to persist across screen transitions while maintaining history and
  modal stacks.
  """

  @type screen_id :: atom() | String.t()
  @type screen_module :: module()
  @type params :: map()

  @type t :: %__MODULE__{
          current: screen_id() | nil,
          current_module: screen_module() | nil,
          current_params: params(),
          history: [{screen_id(), screen_module(), params()}],
          forward: [{screen_id(), screen_module(), params()}],
          modals: [{screen_id(), screen_module(), params()}],
          modal_open?: boolean()
        }

  defstruct [
    :current,
    :current_module,
    current_params: %{},
    history: [],
    forward: [],
    modals: [],
    modal_open?: false
  ]

  @doc """
  Creates a new navigation state with the given screen as the current screen.
  """
  @spec new(screen_id(), screen_module(), params()) :: t()
  def new(screen_id, screen_module, params \\ %{}) do
    %__MODULE__{
      current: screen_id,
      current_module: screen_module,
      current_params: params,
      history: [],
      forward: [],
      modals: [],
      modal_open?: false
    }
  end

  @doc """
  Returns whether back navigation is available.
  """
  @spec can_go_back?(t()) :: boolean()
  def can_go_back?(%__MODULE__{history: history}) when is_list(history) do
    length(history) > 0
  end

  @doc """
  Returns whether forward navigation is available.
  """
  @spec can_go_forward?(t()) :: boolean()
  def can_go_forward?(%__MODULE__{forward: forward}) when is_list(forward) do
    length(forward) > 0
  end

  @doc """
  Returns whether a modal is currently open.
  """
  @spec modal_open?(t()) :: boolean()
  def modal_open?(%__MODULE__{modal_open?: open?}), do: open?

  @doc """
  Returns the current screen tuple or nil if no screen is set.
  """
  @spec current_screen(t()) :: {screen_id(), screen_module(), params()} | nil
  def current_screen(%__MODULE__{current: nil}), do: nil

  def current_screen(%__MODULE__{
        current: screen_id,
        current_module: module,
        current_params: params
      }) do
    {screen_id, module, params}
  end

  @doc """
  Returns the top modal screen tuple or nil if no modal is open.
  """
  @spec top_modal(t()) :: {screen_id(), screen_module(), params()} | nil
  def top_modal(%__MODULE__{modals: []}), do: nil

  def top_modal(%__MODULE__{modals: [modal | _]}), do: modal

  @doc """
  Returns the depth of the modal stack.
  """
  @spec modal_depth(t()) :: non_neg_integer()
  def modal_depth(%__MODULE__{modals: modals}) when is_list(modals), do: length(modals)
end
