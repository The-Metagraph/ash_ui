import Config

config :ash_ui_example_box,
  ecto_repos: []

config :ash_ui_example_box, AshUIExamples.Box.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Box.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Box.UiScreen,
    element: AshUIExamples.Box.UiElement,
    binding: AshUIExamples.Box.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Box.RuntimeDomain]

import_config "#{config_env()}.exs"
