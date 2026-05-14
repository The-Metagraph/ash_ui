defmodule LiveUi.Component.Metadata do
  @moduledoc """
  Declares the shared metadata contract for native `live_ui` widgets.

  ## Component Classification

  Components are classified by their purpose and runtime requirements:

  * `:structural` - Pure layout/composition primitives like `Row`, `Column`, `Grid`,
    `Viewport`, `Box`, `Content`, `Separator`, `Spacer`. These components don't
    handle events, don't maintain local UI state, and their output is fully
    determined by their assigns. They should remain as function components
    without LiveComponent overhead.

  * `:interactive` - Widgets that handle user interactions and may maintain
    ephemeral UI state (e.g., `Button`, `TextInput`, `Select`, `Menu`). These
    require LiveComponent boundaries for event routing and state management.

  * `:container` - Complex containers that may have composition behavior plus
    lifecycle or event handling requirements (e.g., `Overlay`, `Dialog`).

  * `nil` - Unclassified components (legacy or not yet categorized).

  ## Runtime Boundaries

  * `:function_component` - Pure Phoenix.Component function without lifecycle hooks.
    Used for structural components where no event handling or local state is needed.

  * `:live_component` - Phoenix.LiveComponent with mount/update/handle_event lifecycle.
    Used for interactive components that need event routing and bounded local state.

  * `nil` - Boundary not explicitly specified.
  """

  @type component_class :: :structural | :interactive | :container | nil
  @type runtime_boundary :: :live_component | :function_component | nil

  @enforce_keys [:module, :family, :name]
  defstruct [
    :module,
    :family,
    :name,
    :component_module,
    :wrapper_module,
    :component_class,
    assigns: [],
    slots: [],
    style_hooks: [],
    events: [],
    mountable?: false,
    local_state_keys: [],
    identity_keys: [],
    runtime_boundary: nil
  ]

  @type t :: %__MODULE__{
          module: module(),
          family: atom(),
          name: atom(),
          component_module: module() | nil,
          wrapper_module: module() | nil,
          component_class: component_class(),
          assigns: [atom()],
          slots: [atom()],
          style_hooks: [LiveUi.Component.style_hook()],
          events: [LiveUi.Component.event_surface()],
          mountable?: boolean(),
          local_state_keys: [atom()],
          identity_keys: [atom()],
          runtime_boundary: runtime_boundary()
        }

  @spec new(module(), keyword()) :: t()
  def new(module, opts) do
    %__MODULE__{
      module: module,
      family: Keyword.fetch!(opts, :family),
      name: Keyword.fetch!(opts, :name),
      component_module: Keyword.get(opts, :component_module),
      wrapper_module: Keyword.get(opts, :wrapper_module, module),
      component_class: Keyword.get(opts, :component_class),
      assigns: Keyword.get(opts, :assigns, []),
      slots: Keyword.get(opts, :slots, []),
      style_hooks: Keyword.get(opts, :style_hooks, []),
      events: Keyword.get(opts, :events, []),
      mountable?: Keyword.get(opts, :mountable?, false),
      local_state_keys: Keyword.get(opts, :local_state_keys, []),
      identity_keys: Keyword.get(opts, :identity_keys, []),
      runtime_boundary: Keyword.get(opts, :runtime_boundary)
    }
  end

  @doc """
  Returns true if the component is a structural helper (layout, display, etc.).

  Structural components don't handle events, don't maintain local state, and
  should be rendered as function components without LiveComponent overhead.
  """
  @spec structural?(t()) :: boolean()
  def structural?(%__MODULE__{component_class: :structural}), do: true
  def structural?(%__MODULE__{family: family}) when family in [:layout, :display], do: true
  def structural?(%__MODULE__{}), do: false

  @doc """
  Returns true if the component is interactive (handles events, has local state).
  """
  @spec interactive?(t()) :: boolean()
  def interactive?(%__MODULE__{component_class: :interactive}), do: true
  def interactive?(%__MODULE__{events: events}) when is_list(events) and events != [], do: true
  def interactive?(%__MODULE__{mountable?: true}), do: true
  def interactive?(%__MODULE__{}), do: false

  @doc """
  Returns true if the component requires a LiveComponent boundary for proper functioning.
  """
  @spec requires_live_component?(t()) :: boolean()
  def requires_live_component?(%__MODULE__{} = metadata), do: interactive?(metadata)
end
