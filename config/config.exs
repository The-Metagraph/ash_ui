import Config

config :ash_ui,
  ecto_repos: [AshUI.Repo],
  ash_domains: [AshUI.Domain]

config :ash_ui, :ui_storage,
  domain: AshUI.Domain,
  resources: [
    screen: AshUI.Resources.Screen,
    element: AshUI.Resources.Element,
    binding: AshUI.Resources.Binding
  ],
  repo: AshUI.Repo

# Configure AshUI Domain
config :ash_ui, AshUI.Domain,
  resources: [
    AshUI.Resources.Screen,
    AshUI.Resources.Element,
    AshUI.Resources.Binding
  ]

# Configure Ash
config :ash, :domains, [AshUI.Domain]

# Configure AshPostgres
config :ash, AshUI.Repo,
  timeout: 30_000,
  poll_interval: 50_000

# Configure AshUI Rendering
config :ash_ui, :rendering,
  # Default renderer: :liveview, :html, or :desktop
  default_renderer: :liveview,
  # Enable automatic renderer detection based on context
  auto_detect: true,
  # Allow adapter fallback when external renderer packages are not installed
  allow_adapter_fallback: true,
  # Fallback renderer if primary is unavailable
  fallback_renderer: nil,
  # Renderer-specific options
  renderers: %{
    liveview: [
      # Enable LiveView optimizations
      optimize_patches: true,
      # Default LiveView module for renders
      view_module: nil
    ],
    html: [
      # Enable SEO meta tags
      seo_enabled: true,
      # WebUI always boots Elm; configure the module name here
      elm_module: "Main"
    ],
    desktop: [
      # Window properties
      window_width: 1280,
      window_height: 720,
      window_resizable: true,
      # Platform-specific features
      native_menu_bar: true
    ]
  }

# Import environment specific config
import_config "#{config_env()}.exs"
