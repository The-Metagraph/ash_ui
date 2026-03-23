import Config

config :basic_dashboard_example,
  generators: [timestamp_type: :utc_datetime]

config :basic_dashboard_example, BasicDashboardExampleWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: BasicDashboardExampleWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: BasicDashboardExample.PubSub,
  live_view: [signing_salt: "basicdashsalt"]

config :phoenix, :json_library, Jason

config :ash_ui,
  ui_storage: [
    domain: BasicDashboard.Storage.Domain,
    resources: [
      screen: BasicDashboard.Storage.Screen,
      element: BasicDashboard.Storage.Element,
      binding: BasicDashboard.Storage.Binding
    ],
    repo: nil
  ],
  ash_domains: [AshUI.Domain]

config :ash, BasicDashboard.Domain, authorize: false
config :ash, BasicDashboard.Storage.Domain, authorize: false

import_config "#{config_env()}.exs"
