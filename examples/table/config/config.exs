import Config

config :ash_ui_example_table,
  ecto_repos: []

config :ash_ui_example_table, AshUIExamples.Table.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Table.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Table.UiScreen,
    element: AshUIExamples.Table.UiElement,
    binding: AshUIExamples.Table.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Table.RuntimeDomain]

import_config "#{config_env()}.exs"
