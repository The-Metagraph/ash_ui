import Config

config :ash_ui_example_field,
  ecto_repos: []

config :ash_ui_example_field, AshUIExamples.Field.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Field.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Field.UiScreen,
    element: AshUIExamples.Field.UiElement,
    binding: AshUIExamples.Field.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Field.RuntimeDomain]

import_config "#{config_env()}.exs"
