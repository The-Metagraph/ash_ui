defmodule LiveUi.Component do
  @moduledoc """
  Shared contract for native `live_ui` widgets.
  """

  use Phoenix.Component

  alias LiveUi.Component.Metadata
  alias LiveUi.Runtime.State, as: RuntimeState
  alias LiveUi.Widget.Identity

  @type assigns_contract :: [atom()]
  @type style_hook :: :tone | :variant | :state
  @type event_surface :: :click | :navigate | :submit | :change | :selection | :command

  @callback metadata() :: Metadata.t()
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  @spec common_assigns() :: assigns_contract()
  def common_assigns do
    [:id, :metadata, :class, :tone, :variant, :state, :rest]
  end

  @spec style_hooks() :: [style_hook()]
  def style_hooks do
    [:tone, :variant, :state]
  end

  @spec metadata(module()) :: Metadata.t()
  def metadata(module) do
    module.metadata()
  end

  @spec component_module(module()) :: module()
  def component_module(module) when is_atom(module) do
    metadata(module).component_module || Module.concat(module, Component)
  end

  @spec widget_identity(module(), map() | keyword(), keyword()) :: Identity.t()
  def widget_identity(module, assigns, opts \\ []) when is_atom(module) do
    module
    |> metadata()
    |> Identity.new(assigns, opts)
  end

  @doc """
  Returns true if the given module is a structural component (pure layout primitives).

  Structural components don't handle events and don't need LiveComponent boundaries.
  """
  @spec structural?(module()) :: boolean()
  def structural?(module) when is_atom(module) do
    module
    |> metadata()
    |> Metadata.structural?()
  end

  @doc """
  Returns true if the given module is an interactive component that handles events.
  """
  @spec interactive?(module()) :: boolean()
  def interactive?(module) when is_atom(module) do
    module
    |> metadata()
    |> Metadata.interactive?()
  end

  @doc """
  Returns true if the given module uses the full widget LiveComponent architecture.

  Widget components have:
  - A Component submodule using LiveUi.Widget
  - A component/1 function for compatibility
  - mount_defaults, event_routes, local_state_keys, and handle_widget_event callbacks

  Non-component widgets are pure function components without LiveComponent overhead.
  """
  @spec widget_component?(module()) :: boolean()
  def widget_component?(module) when is_atom(module) do
    module
    |> metadata()
    |> Metadata.requires_live_component?()
  end

  @doc """
  Returns true if the module has a compatibility wrapper for transitional use.

  Modules with widget LiveComponent architecture also provide a component/1 function
  that wraps the LiveComponent in a function component interface for backward compatibility.
  """
  @spec has_compatibility_wrapper?(module()) :: boolean()
  def has_compatibility_wrapper?(module) when is_atom(module) do
    widget_component?(module)
  end

  @doc """
  Mounts a widget component with runtime state integration.

  This function handles the connection between the shared runtime state
  and individual widget components, providing:
  - Widget identity for addressing and event routing
  - Widget local state scoped to the component boundary
  - Event target for routing widget events back to the runtime
  - Mode tracking (native vs canonical rendering)

  ## Expected Assigns

  * `:module` - The widget module to mount
  * `:assigns` - The assigns to pass to the widget
  * `:runtime_state` - Optional runtime state for local state integration
  * `:event_target` - Optional event target for widget events
  * `:path` - Optional path for nested widget addressing
  """
  @spec mount(keyword() | map()) :: Phoenix.LiveView.Rendered.t()
  def mount(assigns) when is_list(assigns), do: mount(Map.new(assigns))

  def mount(assigns) do
    module = Map.fetch!(assigns, :module)
    widget_assigns = Map.fetch!(assigns, :assigns)
    runtime_state = Map.get(assigns, :runtime_state)
    event_target = Map.get(assigns, :event_target)
    path = Map.get(assigns, :path, [])

    widget_mode = runtime_mode(runtime_state)
    widget_identity =
      widget_identity(module, widget_assigns,
        mode: widget_mode,
        path: path
      )

    component_module = component_module(module)
    widget_local_state = fetch_widget_local_state(runtime_state, widget_identity)

    ~H"""
    <.live_component
      module={component_module}
      id={widget_identity.id}
      widget_assigns={widget_assigns}
      widget_identity={widget_identity}
      widget_local_state={widget_local_state}
      event_target={event_target}
      path={path}
      mode={widget_mode}
    />
    """
  end

  defp fetch_widget_local_state(%RuntimeState{} = runtime_state, widget_identity) do
    RuntimeState.widget_local_state(runtime_state, widget_identity)
  end

  defp fetch_widget_local_state(_other, _widget_identity), do: %{}

  defp runtime_mode(%RuntimeState{mode: mode}), do: mode
  defp runtime_mode(_other), do: :native

  defmacro common_attrs do
    quote do
      attr(:id, :string, required: true)
      attr(:metadata, :map, default: %{})
      attr(:class, :string, default: nil)
      attr(:tone, :string, default: nil)
      attr(:variant, :string, default: nil)
      attr(:state, :string, default: nil)
      attr(:rest, :global)
    end
  end

  defmacro __using__(opts) do
    family = Keyword.fetch!(opts, :family)
    name = Keyword.fetch!(opts, :name)
    slots = Keyword.get(opts, :slots, [])
    widget_assigns_contract = Keyword.get(opts, :assigns, [])
    widget_events = Keyword.get(opts, :events, [])
    widget_local_state_keys = Keyword.get(opts, :local_state_keys, [])

    # Pure layout primitives that don't need LiveComponent overhead
    # These are the core structural helpers for composition
    structural_primitives = [
      {:layout, :row},
      {:layout, :column},
      {:layout, :grid},
      {:layout, :separator},
      {:layout, :spacer}
    ]
    structural = {family, name} in structural_primitives

    quote bind_quoted: [
            family: family,
            name: name,
            slots: slots,
            widget_assigns_contract: widget_assigns_contract,
            widget_events: widget_events,
            widget_local_state_keys: widget_local_state_keys,
            structural: structural
          ] do
      use Phoenix.Component

      @behaviour LiveUi.Component

      @live_ui_component_family family
      @live_ui_component_name name
      @live_ui_component_slots slots
      @live_ui_component_assigns widget_assigns_contract
      @live_ui_component_events widget_events
      @live_ui_component_local_state_keys widget_local_state_keys
      @live_ui_structural structural

      wrapper_module = __MODULE__
      @live_ui_component_module Module.concat(__MODULE__, Component)

      defmodule Component do
        use LiveUi.Widget,
          wrapper: wrapper_module,
          family: family,
          name: name,
          slots: slots,
          assigns: widget_assigns_contract,
          events: widget_events,
          local_state_keys: widget_local_state_keys
      end

      @impl true
      def metadata do
        component_class =
          if @live_ui_structural do
            :structural
          else
            nil
          end

        base_metadata = [
          family: @live_ui_component_family,
          name: @live_ui_component_name,
          assigns: LiveUi.Component.common_assigns() ++ @live_ui_component_assigns,
          slots: @live_ui_component_slots,
          style_hooks: LiveUi.Component.style_hooks(),
          events: @live_ui_component_events,
          component_module: @live_ui_component_module,
          wrapper_module: __MODULE__,
          component_class: component_class
        ]

        metadata =
          if @live_ui_structural do
            # Pure layout primitives don't need LiveComponent overhead
            Keyword.put(base_metadata, :runtime_boundary, :function_component)
          else
            # All other components use LiveComponent for event handling and lifecycle
            base_metadata ++
              [
                mountable?: true,
                local_state_keys: @live_ui_component_local_state_keys,
                identity_keys: [:id],
                runtime_boundary: :live_component
              ]
          end

        Metadata.new(__MODULE__, metadata)
      end

      def component(var!(assigns)) when is_map(var!(assigns)) do
        var!(assigns) =
          var!(assigns)
          |> Map.new()
          |> Map.put(:widget_assigns, Map.new(var!(assigns)))
          |> Map.put(:widget_component_module, @live_ui_component_module)
          |> Map.put(
            :widget_identity,
            LiveUi.Component.widget_identity(__MODULE__, var!(assigns))
          )

        ~H"""
        <.live_component
          module={@widget_component_module}
          id={@widget_identity.id}
          widget_assigns={@widget_assigns}
          widget_identity={@widget_identity}
        />
        """
      end

      defoverridable metadata: 0
    end
  end
end
