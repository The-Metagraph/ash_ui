import Config

config :ash_ui_tutorial_project_shell,
  ecto_repos: []

config :ash_ui_tutorial_project_shell, AshUITutorials.ProjectShell.Web.Endpoint,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
  secret_key_base: String.duplicate("ashuitutorialshell", 4),
  server: true,
  live_view: [signing_salt: "ashuitut23a"]

config :ash_ui, :ui_storage,
  domain: AshUITutorials.ProjectShell.UiStorageDomain,
  resources: [
    screen: AshUITutorials.ProjectShell.UiScreen,
    element: AshUITutorials.ProjectShell.UiElement,
    binding: AshUITutorials.ProjectShell.UiBinding
  ],
  repo: nil

# The checkpoint host passes the real runtime domains through `:ash_ui_domains`
# on the LiveView socket. Keeping `AshUI.Domain` here lets the dependency
# compile before this child app's own modules exist.
config :ash_ui, :ash_domains, [AshUI.Domain]

import_config "#{config_env()}.exs"
