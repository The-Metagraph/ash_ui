import Config

config :basic_dashboard_app,
  generators: [timestamp_type: :utc_datetime]

config :basic_dashboard_app, BasicDashboardAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: BasicDashboardAppWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: BasicDashboardApp.PubSub,
  live_view: [signing_salt: "dashboardsalt"]

config :phoenix, :json_library, Jason

config :ash_ui,
  ecto_repos: [AshUI.Repo],
  ash_domains: [AshUI.Domain]

config :ash_ui, AshUI.Domain,
  resources: [
    AshUI.Resources.Screen,
    AshUI.Resources.Element,
    AshUI.Resources.Binding
  ]

config :ash, :domains, [AshUI.Domain]

config :ash, AshUI.Domain, authorize: false
config :ash, BasicDashboard.Domain, authorize: false

import_config "#{config_env()}.exs"
