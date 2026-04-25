import Config

config :ash_ui_example_context_menu,
  ecto_repos: []

config :ash_ui_example_context_menu, AshUIExamples.ContextMenu.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.ContextMenu.UiStorageDomain,
  resources: [
    screen: AshUIExamples.ContextMenu.UiScreen,
    element: AshUIExamples.ContextMenu.UiElement,
    binding: AshUIExamples.ContextMenu.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.ContextMenu.RuntimeDomain]

import_config "#{config_env()}.exs"
