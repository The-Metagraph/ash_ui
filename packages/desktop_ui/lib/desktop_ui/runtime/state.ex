defmodule DesktopUi.Runtime.State do
  @moduledoc """
  Authoritative runtime state for the `desktop_ui` Phase 1 backbone.
  """

  alias DesktopUi.Navigation.State

  @enforce_keys [:runtime_id, :screen_id, :source_kind, :platform_target, :root, :screen]
  defstruct [
    :runtime_id,
    :screen_id,
    :title,
    :source_kind,
    :platform_target,
    :platform_adapter,
    :root,
    :screen,
    :windows,
    :focus,
    :redraw,
    :realization,
    :event_loop,
    :lifecycle,
    :validation_state,
    # Navigation fields
    :navigation_controller,
    :current_screen_module,
    navigation_state: nil,
    screen_params: %{},
    # Event logging
    event_log: []
  ]

  @type source_kind :: :native | :canonical

  @type t :: %__MODULE__{
          runtime_id: String.t(),
          screen_id: String.t(),
          title: String.t() | nil,
          source_kind: source_kind(),
          platform_target: atom(),
          platform_adapter: map() | nil,
          root: map(),
          screen: DesktopUi.Runtime.Screen.t(),
          windows: map(),
          focus: map(),
          redraw: map(),
          realization: map(),
          event_loop: map(),
          lifecycle: map(),
          validation_state: atom(),
          navigation_controller: pid() | nil,
          current_screen_module: module() | nil,
          navigation_state: State.t() | nil,
          screen_params: map(),
          event_log: [map()]
        }
end
