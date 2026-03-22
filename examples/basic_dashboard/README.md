# Basic Dashboard Example

This example shows the smallest practical Ash UI flow in a Phoenix application:

1. create a screen with stored `unified_dsl`
2. seed ETS-backed Ash resources for dashboard data
3. mount it through `AshUI.LiveView.Integration`
4. delegate user events through `AshUI.LiveView.EventHandler`
5. present the result with an Ash HQ-inspired dark theme, warm gradient accents, and live data cards
6. optionally swap UI-definition storage to ETS-backed Ash resources

## Files

- `lib/basic_dashboard.ex`: seed helpers that create the screen, elements, and bindings
- `lib/basic_dashboard_data.ex`: example Ash domain and ETS-backed resources
- `lib/basic_dashboard_live.ex`: a LiveView that mounts the screen and forwards events
- `lib/basic_dashboard_storage.ex`: example ETS-backed `Screen`, `Element`, and `Binding` resources

## Suggested Use

Treat this directory as a reference implementation to copy into an app while wiring your own repo, router, and user lookup.

The example data uses `Ash.DataLayer.Ets`, which is ideal for demos, tests, and lightweight prototypes.
The visual treatment intentionally borrows the Ash site palette and glow accents while leaving out the checkerboard background.

## Core Flow

```elixir
BasicDashboard.Data.seed!()
BasicDashboard.seed!()
```

`BasicDashboard.seed!/0` uses the configured Ash UI storage resources, so you can keep the same seed code while changing the backend.

To use the included ETS-backed example storage instead of the built-in Postgres-backed resources:

```elixir
config :ash_ui,
  ui_storage: [
    domain: BasicDashboard.Storage.Domain,
    resources: [
      screen: BasicDashboard.Storage.Screen,
      element: BasicDashboard.Storage.Element,
      binding: BasicDashboard.Storage.Binding
    ],
    repo: nil
  ]
```

Keep your runtime binding source domains separate:

```elixir
config :ash_ui,
  ash_domains: [MyApp.Domain]
```

Then route a LiveView to the dashboard screen name:

```elixir
live "/dashboard", BasicDashboardLive
```

## Adapter Runner

To inspect the example through a specific Ash UI adapter without starting a
Phoenix server, use:

```bash
mix ash_ui.example.basic_dashboard --renderer liveview
mix ash_ui.example.basic_dashboard --renderer html --output /tmp/basic_dashboard.html
mix ash_ui.example.basic_dashboard --renderer desktop
```

Notes:

- the task configures the example's ETS-backed UI storage automatically
- `liveview` prints HEEx output
- `html` prints or writes static HTML
- `desktop` prints JSON instructions
- add `--strict-external` if you want the task to fail instead of using adapter fallback
