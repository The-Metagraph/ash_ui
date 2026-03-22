import Config

if config_env() == :prod do
  port = String.to_integer(System.get_env("PORT") || "4100")

  config :basic_dashboard_app, BasicDashboardAppWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "localhost", port: port],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base:
      System.get_env("SECRET_KEY_BASE") ||
        raise("""
        environment variable SECRET_KEY_BASE is missing.
        Generate one with: mix phx.gen.secret
        """),
    server: true

  config :ash_ui, AshUI.Repo,
    username: System.get_env("DATABASE_USERNAME") || "postgres",
    password: System.get_env("DATABASE_PASSWORD") || "postgres",
    hostname: System.get_env("DATABASE_HOSTNAME") || "localhost",
    port: String.to_integer(System.get_env("DATABASE_PORT") || "5432"),
    database: System.get_env("DATABASE_NAME") || "ash_ui_basic_dashboard_app_prod",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
