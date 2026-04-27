import Config

config :ash_ui_tutorial_metrics_and_capacity,
  ecto_repos: []

config :ash_ui_tutorial_metrics_and_capacity, AshUITutorials.MetricsAndCapacity.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuitutorialcontrol", 4),
  server: true,
  live_view: [signing_salt: "ashuitut23b"]

config :ash_ui, :ui_storage,
  domain: AshUITutorials.MetricsAndCapacity.UiStorageDomain,
  resources: [
    screen: AshUITutorials.MetricsAndCapacity.UiScreen,
    element: AshUITutorials.MetricsAndCapacity.UiElement,
    binding: AshUITutorials.MetricsAndCapacity.UiBinding
  ],
  repo: nil

# The maintained app passes the real runtime domains through `:ash_ui_domains`
# on the LiveView socket. Keeping `AshUI.Domain` here lets the dependency
# compile before this child app's own modules exist.
config :ash_ui, :ash_domains, [AshUI.Domain]

import_config "#{config_env()}.exs"
