import Config

config :basic_dashboard_example, BasicDashboardExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4100")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "qg7W8d3qC6W3h9tB2mR5xL8pN1sV4yK7uE2aD5fG8hJ1kL4mN7pQ2rS5tU8vX1yAaBbCcDd",
  watchers: []
