import Config

config :ash_ui_tutorial_production_polish,
  ecto_repos: []

config :ash_ui_tutorial_production_polish, AshUITutorials.ProductionPolish.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuitutorialcontrol", 4),
  server: true,
  live_view: [signing_salt: "ashuitut23b"]

config :ash_ui, :ui_storage,
  domain: AshUITutorials.ProductionPolish.UiStorageDomain,
  resources: [
    screen: AshUITutorials.ProductionPolish.UiScreen,
    element: AshUITutorials.ProductionPolish.UiElement,
    binding: AshUITutorials.ProductionPolish.UiBinding
  ],
  repo: nil

# The maintained app passes the real runtime domains through `:ash_ui_domains`
# on the LiveView socket. Keeping `AshUI.Domain` here lets the dependency
# compile before this child app's own modules exist.
config :ash_ui, :ash_domains, [AshUI.Domain]

import_config "#{config_env()}.exs"
