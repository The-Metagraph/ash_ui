import Config

# Force SDL-backed renderers into headless mode for tests so renderer suites do
# not open visible windows on machines with SDL installed.
System.put_env("SDL_VIDEODRIVER", "dummy")
System.put_env("SDL_AUDIODRIVER", "dummy")
System.put_env("SDL_RENDER_DRIVER", "software")
System.put_env("ASH_UI_HEADLESS_TESTS", "true")

# Configure your database
config :ash_ui, AshUI.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ash_ui_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure Ash for test
config :ash, AshUI.Domain,
  authorize: false

# Configure Ash to use the domain
config :ash, :domains, [AshUI.Domain]
