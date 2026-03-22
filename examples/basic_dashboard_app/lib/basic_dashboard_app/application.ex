defmodule BasicDashboardApp.Application do
  @moduledoc """
  Supervision tree for the standalone basic dashboard app.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: BasicDashboardApp.PubSub},
      BasicDashboardAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BasicDashboardApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BasicDashboardAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
