import Config

config :ash_ui_example_spacer,
  ecto_repos: []

config :ash_ui_example_spacer, AshUIExamples.Spacer.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Spacer.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Spacer.UiScreen,
    element: AshUIExamples.Spacer.UiElement,
    binding: AshUIExamples.Spacer.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Spacer.RuntimeDomain]

import_config "#{config_env()}.exs"
