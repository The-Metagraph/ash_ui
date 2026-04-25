import Config

config :ash_ui_example_command_palette,
  ecto_repos: []

config :ash_ui_example_command_palette, AshUIExamples.CommandPalette.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph19"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.CommandPalette.UiStorageDomain,
  resources: [
    screen: AshUIExamples.CommandPalette.UiScreen,
    element: AshUIExamples.CommandPalette.UiElement,
    binding: AshUIExamples.CommandPalette.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.CommandPalette.RuntimeDomain]

import_config "#{config_env()}.exs"
