defmodule AshUI.LiveView.ScreenHost do
  @moduledoc """
  Generic LiveView host for stored Ash UI screens.

  This module centralizes the common LiveView behavior needed to mount a
  stored screen, route Ash UI events, react to notifier messages, and render
  the hydrated canonical IUR tree through the LiveUI adapter.
  """

  require Logger

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.LiveView.UpdateIntegration
  alias AshUI.Rendering.LiveUIAdapter

  @type host_opt ::
          {:screen, Integration.screen_identifier()}
          | {:prepare, (Phoenix.LiveView.Socket.t() -> prepare_result())}
          | {:current_user, term()}
          | {:ui_storage, keyword() | nil}
          | {:ash_domains, [module()]}
          | {:mount_params, map()}

  @type prepare_result ::
          :ok
          | Phoenix.LiveView.Socket.t()
          | {:ok, Phoenix.LiveView.Socket.t()}
          | {:error, term()}

  @doc """
  Injects a generic Ash UI LiveView host into the caller.

  ## Required options
    * `:screen` - the screen identifier to mount

  ## Overridable callbacks
    * `ash_ui_prepare/3`
    * `ash_ui_current_user/3`
    * `ash_ui_storage/3`
    * `ash_ui_domains/3`
    * `ash_ui_mount_params/3`
    * `ash_ui_render_options/0`
  """
  defmacro __using__(opts) do
    screen = Keyword.fetch!(opts, :screen)

    quote bind_quoted: [screen: screen] do
      use Phoenix.LiveView

      @ash_ui_screen screen

      @doc false
      def ash_ui_screen_id(_params, _session, _socket), do: @ash_ui_screen

      @doc false
      def ash_ui_prepare(_params, _session, socket), do: {:ok, socket}

      @doc false
      def ash_ui_current_user(_params, _session, socket),
        do: Map.get(socket.assigns, :current_user)

      @doc false
      def ash_ui_storage(_params, _session, _socket), do: nil

      @doc false
      def ash_ui_domains(_params, _session, _socket), do: []

      @doc false
      def ash_ui_mount_params(params, _session, _socket), do: params

      @doc false
      def ash_ui_render_options, do: [event_prefix: "ash_ui", optimize_patches: false]

      defoverridable ash_ui_screen_id: 3,
                     ash_ui_prepare: 3,
                     ash_ui_current_user: 3,
                     ash_ui_storage: 3,
                     ash_ui_domains: 3,
                     ash_ui_mount_params: 3,
                     ash_ui_render_options: 0

      @impl true
      def mount(params, session, socket) do
        AshUI.LiveView.ScreenHost.mount_screen(socket, params, session,
          screen: ash_ui_screen_id(params, session, socket),
          prepare: fn mounted_socket -> ash_ui_prepare(params, session, mounted_socket) end,
          current_user: ash_ui_current_user(params, session, socket),
          ui_storage: ash_ui_storage(params, session, socket),
          ash_domains: ash_ui_domains(params, session, socket),
          mount_params: ash_ui_mount_params(params, session, socket)
        )
      end

      @impl true
      def handle_event(event_name, params, socket) do
        AshUI.LiveView.ScreenHost.handle_event(event_name, params, socket)
      end

      @impl true
      def handle_info(message, socket) do
        AshUI.LiveView.ScreenHost.handle_info(message, socket)
      end

      @impl true
      def terminate(reason, socket) do
        AshUI.LiveView.ScreenHost.terminate(reason, socket)
      end

      @impl true
      def render(assigns) do
        AshUI.LiveView.ScreenHost.render_iur(
          Map.get(assigns, :ash_ui_iur),
          ash_ui_render_options()
        )
        |> Phoenix.HTML.raw()
      end
    end
  end

  @doc """
  Mounts a stored screen into a generic LiveView host.
  """
  @spec mount_screen(Phoenix.LiveView.Socket.t(), map(), map(), [host_opt()]) ::
          {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}
  def mount_screen(socket, params, _session, opts) do
    screen = Keyword.fetch!(opts, :screen)
    mount_params = Keyword.get(opts, :mount_params, params)

    with {:ok, socket} <- run_prepare(socket, Keyword.get(opts, :prepare)),
         socket <- assign_host_context(socket, opts),
         {:ok, socket} <- Integration.mount_ui_screen(socket, screen, mount_params) do
      {:ok, socket}
    end
  end

  @doc """
  Dispatches Ash UI LiveView events through the shared event handler.
  """
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()} | {:reply, map(), Phoenix.LiveView.Socket.t()}
  def handle_event("ash_ui_change", params, socket) do
    EventHandler.handle_value_change(params, socket)
  end

  def handle_event("ash_ui_action", params, socket) do
    EventHandler.handle_action_event(params, socket)
  end

  def handle_event(event_name, _params, socket) do
    Logger.debug("Unhandled Ash UI screen host event: #{inspect(event_name)}")
    {:noreply, socket}
  end

  @doc """
  Routes notifier messages through the shared update integration.
  """
  @spec handle_info(term(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(%Ash.Notifier.Notification{} = notification, socket) do
    UpdateIntegration.handle_resource_change(notification, socket)
  end

  def handle_info(message, socket) do
    UpdateIntegration.handle_notification(message, socket)
  end

  @doc """
  Cleans up Ash UI subscriptions for the hosted screen.
  """
  @spec terminate(term(), Phoenix.LiveView.Socket.t()) :: :ok
  def terminate(_reason, socket) do
    UpdateIntegration.cleanup_subscriptions(socket)
  end

  @doc """
  Renders a hydrated canonical IUR tree through the LiveUI adapter.
  """
  @spec render_iur(map() | nil, keyword()) :: String.t()
  def render_iur(iur, opts \\ [])

  def render_iur(nil, _opts), do: ""

  def render_iur(iur, opts) do
    case LiveUIAdapter.render(iur, opts) do
      {:ok, html} -> html
      {:error, reason} -> "<pre>#{inspect(reason, pretty: true)}</pre>"
    end
  end

  defp run_prepare(socket, nil), do: {:ok, socket}

  defp run_prepare(socket, prepare) when is_function(prepare, 1) do
    case prepare.(socket) do
      :ok -> {:ok, socket}
      %Phoenix.LiveView.Socket{} = updated_socket -> {:ok, updated_socket}
      {:ok, %Phoenix.LiveView.Socket{} = updated_socket} -> {:ok, updated_socket}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_prepare_result, other}}
    end
  end

  defp assign_host_context(socket, opts) do
    socket
    |> maybe_assign(:current_user, Keyword.get(opts, :current_user))
    |> maybe_assign(:ash_ui_storage, Keyword.get(opts, :ui_storage))
    |> maybe_assign_domains(Keyword.get(opts, :ash_domains, []))
  end

  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, value), do: Phoenix.Component.assign(socket, key, value)

  defp maybe_assign_domains(socket, []), do: socket

  defp maybe_assign_domains(socket, domains),
    do: Phoenix.Component.assign(socket, :ash_ui_domains, domains)
end
