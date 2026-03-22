import Config

config :basic_dashboard_app, BasicDashboardAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4100")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "oK6roFb5gjE9UAwjlwmW3W7T9xvxr8kD6QF2G7mF0g9Kk9zQm4Yh1yJr7sL2nP5x",
  watchers: []

config :ash_ui, AshUI.Repo,
  username: System.get_env("DATABASE_USERNAME") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "postgres",
  hostname: System.get_env("DATABASE_HOSTNAME") || "localhost",
  port: String.to_integer(System.get_env("DATABASE_PORT") || "5432"),
  database: System.get_env("DATABASE_NAME") || "ash_ui_basic_dashboard_app_dev",
  pool_size: 10
