defmodule BasicDashboardLive do
  @moduledoc """
  Standalone dashboard LiveView built on the generic Ash UI screen host.
  """

  use AshUI.LiveView.ScreenHost, screen: :basic_dashboard

  alias BasicDashboard.Data
  alias BasicDashboard.Storage

  @impl true
  def ash_ui_prepare(_params, _session, socket) do
    Data.seed!()
    BasicDashboard.seed!()
    {:ok, socket}
  end

  @impl true
  def ash_ui_current_user(_params, _session, _socket), do: Data.actor()

  @impl true
  def ash_ui_storage(_params, _session, _socket), do: Storage.config()

  @impl true
  def ash_ui_domains(_params, _session, _socket), do: [BasicDashboard.Domain]
end
