import Config

config :ash_ui_example_cluster_dashboard,
  ecto_repos: []

config :ash_ui_example_cluster_dashboard, AshUIExamples.ClusterDashboard.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.ClusterDashboard.UiStorageDomain,
  resources: [
    screen: AshUIExamples.ClusterDashboard.UiScreen,
    element: AshUIExamples.ClusterDashboard.UiElement,
    binding: AshUIExamples.ClusterDashboard.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.ClusterDashboard.RuntimeDomain]

import_config "#{config_env()}.exs"
