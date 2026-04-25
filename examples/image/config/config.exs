import Config

config :ash_ui_example_image,
  ecto_repos: []

config :ash_ui_example_image, AshUIExamples.Image.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.Image.UiStorageDomain,
  resources: [
    screen: AshUIExamples.Image.UiScreen,
    element: AshUIExamples.Image.UiElement,
    binding: AshUIExamples.Image.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.Image.RuntimeDomain]

import_config "#{config_env()}.exs"
