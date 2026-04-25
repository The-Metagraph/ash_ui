import Config

config :ash_ui_example_pick_list,
  ecto_repos: []

config :ash_ui_example_pick_list, AshUIExamples.PickList.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph18"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.PickList.UiStorageDomain,
  resources: [
    screen: AshUIExamples.PickList.UiScreen,
    element: AshUIExamples.PickList.UiElement,
    binding: AshUIExamples.PickList.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.PickList.RuntimeDomain]

import_config "#{config_env()}.exs"
