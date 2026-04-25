import Config

config :ash_ui_example_scroll_bar,
  ecto_repos: []

config :ash_ui_example_scroll_bar, AshUIExamples.ScrollBar.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph19"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.ScrollBar.UiStorageDomain,
  resources: [
    screen: AshUIExamples.ScrollBar.UiScreen,
    element: AshUIExamples.ScrollBar.UiElement,
    binding: AshUIExamples.ScrollBar.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.ScrollBar.RuntimeDomain]

import_config "#{config_env()}.exs"
