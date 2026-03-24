defmodule BasicDashboardLive do
  @moduledoc """
  Thin LiveView host for the ETS-backed basic dashboard example.
  """

  use Phoenix.LiveView

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.LiveView.UpdateIntegration
  alias AshUI.Rendering.LiveUIAdapter
  alias BasicDashboard.Data
  alias BasicDashboard.Storage

  @impl true
  def mount(_params, _session, socket) do
    Data.seed!()
    BasicDashboard.seed!()

    socket =
      socket
      |> assign(:current_user, Data.actor())
      |> assign(:ash_ui_storage, Storage.config())
      |> assign(:ash_ui_domains, [BasicDashboard.Domain])

    Integration.mount_ui_screen(socket, :basic_dashboard, %{})
  end

  @impl true
  def handle_event("ash_ui_change", params, socket) do
    EventHandler.handle_value_change(params, socket)
  end

  def handle_event("ash_ui_action", params, socket) do
    EventHandler.handle_action_event(params, socket)
  end

  @impl true
  def handle_info(%Ash.Notifier.Notification{} = notification, socket) do
    UpdateIntegration.handle_resource_change(notification, socket)
  end

  def handle_info(message, socket) do
    UpdateIntegration.handle_notification(message, socket)
  end

  @impl true
  def terminate(_reason, socket) do
    UpdateIntegration.cleanup_subscriptions(socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    {Phoenix.HTML.raw(rendered_screen(@ash_ui_iur))}
    """
  end

  defp rendered_screen(iur) do
    case LiveUIAdapter.render(iur, event_prefix: "ash_ui", optimize_patches: false) do
      {:ok, html} -> html
      {:error, reason} -> "<pre>#{inspect(reason, pretty: true)}</pre>"
    end
  end
end
