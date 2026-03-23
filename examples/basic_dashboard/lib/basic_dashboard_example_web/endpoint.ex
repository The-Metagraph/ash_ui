defmodule BasicDashboardExampleWeb.Endpoint do
  @moduledoc """
  Phoenix endpoint for the standalone basic dashboard example app.
  """

  use Phoenix.Endpoint, otp_app: :basic_dashboard_example

  @session_options [
    store: :cookie,
    key: "_basic_dashboard_example_key",
    signing_salt: "basicdashsess"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :basic_dashboard_example,
    gzip: false,
    only: []

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BasicDashboardExampleWeb.Router
end
