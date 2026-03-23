defmodule BasicDashboardExampleWeb.Router do
  @moduledoc """
  Router for the standalone basic dashboard example app.
  """

  use BasicDashboardExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BasicDashboardExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live "/", BasicDashboardLive
    live "/dashboard", BasicDashboardLive
  end
end
