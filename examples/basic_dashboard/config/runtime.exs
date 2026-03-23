import Config

if config_env() == :prod do
  port = String.to_integer(System.get_env("PORT") || "4100")

  config :basic_dashboard_example, BasicDashboardExampleWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "localhost", port: port],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base:
      System.get_env("SECRET_KEY_BASE") ||
        raise("""
        environment variable SECRET_KEY_BASE is missing.
        Generate one with: mix phx.gen.secret
        """),
    server: true
end
