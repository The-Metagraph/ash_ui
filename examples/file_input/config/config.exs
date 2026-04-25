import Config

config :ash_ui_example_file_input,
  ecto_repos: []

config :ash_ui_example_file_input, AshUIExamples.FileInput.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.FileInput.UiStorageDomain,
  resources: [
    screen: AshUIExamples.FileInput.UiScreen,
    element: AshUIExamples.FileInput.UiElement,
    binding: AshUIExamples.FileInput.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.FileInput.RuntimeDomain]

import_config "#{config_env()}.exs"
