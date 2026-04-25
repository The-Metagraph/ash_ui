import Config

config :ash_ui_example_inline_feedback,
  ecto_repos: []

config :ash_ui_example_inline_feedback, AshUIExamples.InlineFeedback.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.InlineFeedback.UiStorageDomain,
  resources: [
    screen: AshUIExamples.InlineFeedback.UiScreen,
    element: AshUIExamples.InlineFeedback.UiElement,
    binding: AshUIExamples.InlineFeedback.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.InlineFeedback.RuntimeDomain]

import_config "#{config_env()}.exs"
