import Config

config :ash_ui_example_alert_dialog,
  ecto_repos: []

config :ash_ui_example_alert_dialog, AshUIExamples.AlertDialog.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.AlertDialog.UiStorageDomain,
  resources: [
    screen: AshUIExamples.AlertDialog.UiScreen,
    element: AshUIExamples.AlertDialog.UiElement,
    binding: AshUIExamples.AlertDialog.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.AlertDialog.RuntimeDomain]

import_config "#{config_env()}.exs"
