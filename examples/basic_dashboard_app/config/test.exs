import Config

config :basic_dashboard_app, BasicDashboardAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4101],
  secret_key_base: "5N9kqD2sL7xB1uP4mH8yR3cF6gT0vW2zQ9aJ4nK7pM1rS5dL8cX2fH6yB0tN3wQ",
  server: false

config :ash_ui, AshUI.Repo,
  username: System.get_env("DATABASE_USERNAME") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "postgres",
  hostname: System.get_env("DATABASE_HOSTNAME") || "localhost",
  port: String.to_integer(System.get_env("DATABASE_PORT") || "5432"),
  database: System.get_env("DATABASE_NAME") || "ash_ui_basic_dashboard_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
