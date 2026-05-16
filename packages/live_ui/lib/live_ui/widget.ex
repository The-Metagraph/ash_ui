defmodule LiveUi.Widget do
  @moduledoc """
  Shared LiveComponent contract for mountable `live_ui` widget boundaries.
  """

  use Phoenix.LiveComponent

  alias LiveUi.Component.Metadata
  alias LiveUi.Widget.Identity

  @type local_state :: map()

  @callback metadata() :: Metadata.t()
  @callback wrapper_module() :: module()
  @callback mount_defaults() :: local_state()
  @callback event_routes() :: %{optional(String.t()) => atom()}
  @callback local_state_keys() :: [atom()]
  @callback handle_widget_event(atom(), map(), local_state()) ::
              {:ok, local_state()} | {:error, term()}

  @optional_callbacks mount_defaults: 0,
                      event_routes: 0,
                      local_state_keys: 0,
                      handle_widget_event: 3

  defmacro __using__(opts) do
    wrapper = Keyword.fetch!(opts, :wrapper)
    family = Keyword.fetch!(opts, :family)
    name = Keyword.fetch!(opts, :name)
    slots = Keyword.get(opts, :slots, [])
    widget_assigns_contract = Keyword.get(opts, :assigns, [])
    widget_events = Keyword.get(opts, :events, [])
    widget_local_state_keys = Keyword.get(opts, :local_state_keys, [])

    quote bind_quoted: [
            wrapper: wrapper,
            family: family,
            name: name,
            slots: slots,
            widget_assigns_contract: widget_assigns_contract,
            widget_events: widget_events,
            widget_local_state_keys: widget_local_state_keys
          ] do
      use Phoenix.LiveComponent

      @behaviour LiveUi.Widget

      @live_ui_widget_wrapper wrapper
      @live_ui_widget_family family
      @live_ui_widget_name name
      @live_ui_widget_slots slots
      @live_ui_widget_assigns widget_assigns_contract
      @live_ui_widget_events widget_events
      @live_ui_widget_local_state_keys widget_local_state_keys

      @impl true
      def metadata do
        Metadata.new(@live_ui_widget_wrapper,
          family: @live_ui_widget_family,
          name: @live_ui_widget_name,
          assigns: LiveUi.Component.common_assigns() ++ @live_ui_widget_assigns,
          slots: @live_ui_widget_slots,
          style_hooks: LiveUi.Component.style_hooks(),
          events: @live_ui_widget_events,
          component_module: __MODULE__,
          wrapper_module: @live_ui_widget_wrapper,
          mountable?: true,
          local_state_keys: @live_ui_widget_local_state_keys,
          identity_keys: [:id],
          runtime_boundary: :live_component
        )
      end

      @impl true
      def wrapper_module, do: @live_ui_widget_wrapper

      @impl true
      def mount_defaults, do: %{}

      @impl true
      def event_routes, do: %{}

      @impl true
      def local_state_keys, do: @live_ui_widget_local_state_keys

      @impl true
      def handle_widget_event(_route, _payload, _local_state),
        do: {:error, :unsupported_widget_event}

      @impl true
      def update(%{widget_assigns: widget_assigns} = incoming_assigns, socket) do
        widget_assigns = Map.new(widget_assigns)
        widget_metadata = metadata()

        widget_identity =
          incoming_assigns[:widget_identity] ||
            socket.assigns[:widget_identity] ||
            Identity.new(widget_metadata, widget_assigns,
              mode: Map.get(incoming_assigns, :mode, :native),
              path: Map.get(incoming_assigns, :path, [])
            )

        widget_local_state =
          incoming_assigns[:widget_local_state] ||
            widget_assigns[:widget_local_state] ||
            socket.assigns[:widget_local_state] ||
            mount_defaults()

        {:ok,
         socket
         |> assign(:widget_assigns, widget_assigns)
         |> assign(:widget_identity, widget_identity)
         |> assign(:widget_local_state, widget_local_state)
         |> assign(:widget_metadata, widget_metadata)
         |> assign(:widget_wrapper_module, wrapper_module())
         |> assign(:event_target, Map.get(incoming_assigns, :event_target))}
      end

      @impl true
      def render(var!(assigns)) do
        var!(assigns) =
          assign(var!(assigns), :render_assigns, build_render_assigns(var!(assigns)))

        ~H"""
        <div
          id={"#{@widget_identity.id}--component"}
          data-live-ui-widget-boundary={Atom.to_string(@widget_metadata.name)}
          data-live-ui-widget-key={LiveUi.Widget.Identity.key(@widget_identity)}
          data-live-ui-widget-component={inspect(__MODULE__)}
          style="display: contents;"
        >
          <%= @widget_wrapper_module.render(@render_assigns) %>
        </div>
        """
      end

      defp build_render_assigns(assigns) do
        metadata =
          assigns.widget_assigns
          |> Map.get(:metadata, %{})
          |> Map.merge(%{
            widget_component_module: __MODULE__,
            widget_wrapper_module: assigns.widget_wrapper_module,
            widget_identity: assigns.widget_identity,
            widget_boundary: :live_component
          })

        assigns.widget_assigns
        |> Map.drop([
          :widget_assigns,
          :widget_identity,
          :widget_local_state,
          :widget_component_module,
          :widget_wrapper_module,
          :event_target,
          :path,
          :mode
        ])
        |> Map.put(:metadata, metadata)
        |> Map.put(:__changed__, %{})
      end

      defoverridable metadata: 0,
                     mount_defaults: 0,
                     event_routes: 0,
                     local_state_keys: 0,
                     handle_widget_event: 3
    end
  end
end
