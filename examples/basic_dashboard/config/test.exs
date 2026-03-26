import Config

# Keep the standalone example app headless under `mix test` when SDL-backed
# renderers are available locally.
System.put_env("SDL_VIDEODRIVER", "dummy")
System.put_env("SDL_AUDIODRIVER", "dummy")
System.put_env("SDL_RENDER_DRIVER", "software")
System.put_env("ASH_UI_HEADLESS_TESTS", "true")

config :basic_dashboard_example, BasicDashboardExampleWeb.Endpoint,
  server: false,
  secret_key_base: "qg7W8d3qC6W3h9tB2mR5xL8pN1sV4yK7uE2aD5fG8hJ1kL4mN7pQ2rS5tU8vX1yAaBbCcDd"
