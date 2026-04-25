import Config

config :ash_ui_example_menu,
  ecto_repos: []

config :ash_ui_example_menu, AshUIExamples.Menu.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph19"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Menu.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Menu.UiScreen,
    element: AshUIExamples.Menu.UiElement,
    binding: AshUIExamples.Menu.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Menu.RuntimeDomain]

import_config "#{config_env()}.exs"
