defmodule BasicDashboardAppWeb.Router do
  @moduledoc """
  Router for the standalone basic dashboard app.
  """

  use BasicDashboardAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BasicDashboardAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live "/", BasicDashboardLive
    live "/dashboard", BasicDashboardLive
  end
end
