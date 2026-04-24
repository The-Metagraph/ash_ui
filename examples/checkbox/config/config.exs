import Config

config :ash_ui_example_checkbox,
  ecto_repos: []

config :ash_ui_example_checkbox, AshUIExamples.Checkbox.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Checkbox.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Checkbox.UiScreen,
    element: AshUIExamples.Checkbox.UiElement,
    binding: AshUIExamples.Checkbox.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Checkbox.RuntimeDomain]

import_config "#{config_env()}.exs"
