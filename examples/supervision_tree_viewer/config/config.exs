import Config

config :ash_ui_example_supervision_tree_viewer,
  ecto_repos: []

config :ash_ui_example_supervision_tree_viewer, AshUIExamples.SupervisionTreeViewer.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuiexample", 6),
  server: true,
  live_view: [signing_salt: "ashuiph20"]

config :ash_ui, :ui_storage,
  domain: AshUIExamples.SupervisionTreeViewer.UiStorageDomain,
  resources: [
    screen: AshUIExamples.SupervisionTreeViewer.UiScreen,
    element: AshUIExamples.SupervisionTreeViewer.UiElement,
    binding: AshUIExamples.SupervisionTreeViewer.UiBinding
  ],
  repo: nil

config :ash_ui, :ash_domains, [AshUIExamples.SupervisionTreeViewer.RuntimeDomain]

import_config "#{config_env()}.exs"
