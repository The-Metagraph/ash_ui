defmodule BasicDashboardExample.Application do
  @moduledoc """
  Supervision tree for the standalone basic dashboard example app.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: BasicDashboardExample.PubSub},
      BasicDashboardExampleWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BasicDashboardExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BasicDashboardExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
