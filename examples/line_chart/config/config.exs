import Config

config :ash_ui_example_line_chart,
  ecto_repos: []

config :ash_ui_example_line_chart, AshUIExamples.LineChart.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.LineChart.UiStorageDomain,
  resources: [
    screen: AshUIExamples.LineChart.UiScreen,
    element: AshUIExamples.LineChart.UiElement,
    binding: AshUIExamples.LineChart.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.LineChart.RuntimeDomain]

import_config "#{config_env()}.exs"
