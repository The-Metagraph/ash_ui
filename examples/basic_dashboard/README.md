# Basic Dashboard Example

This example shows the smallest practical Ash UI flow in a Phoenix application:

1. create a screen with stored `unified_dsl`
2. seed ETS-backed Ash resources for dashboard data
3. mount it through `AshUI.LiveView.Integration`
4. delegate user events through `AshUI.LiveView.EventHandler`
5. present the result with an Ash HQ-inspired dark theme, warm gradient accents, stats cards, a semantic snapshot table, and a semantic explainer list
6. optionally swap UI-definition storage to ETS-backed Ash resources

## Migration Status

- [x] Phase 1 - Store the dashboard shell, hero, preview, and editor as `unified_dsl`
- [x] Phase 2 - Add the stats strip plus semantic list/table widgets to the stored screen
- [x] Phase 3 - Adopt the generic Ash UI LiveView host end to end
- [x] 3.1 Section - Add a reusable `AshUI.LiveView.ScreenHost` for stored screens
- [x] 3.2 Section - Switch `BasicDashboardLive` to the generic screen host
- [x] 3.3 Section - Refresh example docs/tests around the generic host flow

## Files

- `lib/basic_dashboard.ex`: seed helpers that create the full stored dashboard layout as `unified_dsl`
- `lib/basic_dashboard_data.ex`: example Ash domain and ETS-backed resources
- `lib/basic_dashboard_live.ex`: a minimal `AshUI.LiveView.ScreenHost` wrapper with dashboard-specific seeding and storage config
- `lib/basic_dashboard_storage.ex`: example ETS-backed `Screen`, `Element`, and `Binding` resources

## Run It

This example is now a standalone Phoenix app. From this directory:

```bash
mix setup
mix phx.server
```

Then open [http://localhost:4100](http://localhost:4100).

The app runs entirely on ETS-backed Ash resources for both dashboard data and
UI-definition storage, so it does not require Postgres.

The full page layout now lives in the stored screen definition: top bar, hero,
stats strip, live preview, editor, snapshot table, and explainer list are all
rendered from IUR widgets rather than a handwritten LiveView shell.

The standalone LiveView is now a thin generic-host wrapper. It seeds data and
configures the screen host, while the common Ash UI mount, event, notifier, and
render flow comes from `AshUI.LiveView.ScreenHost`.

## Suggested Use

You can run this directory as-is, or treat it as a reference implementation to
copy into another app while wiring your own repo, router, and user lookup.

The example data uses `Ash.DataLayer.Ets`, which is ideal for demos, tests, and lightweight prototypes.
The visual treatment intentionally borrows the Ash site palette and glow accents while leaving out the checkerboard background.

## Core Flow

```elixir
BasicDashboard.Data.seed!()
BasicDashboard.seed!()
```

```elixir
defmodule BasicDashboardLive do
  use AshUI.LiveView.ScreenHost, screen: :basic_dashboard
end
```

To render the example directly through a specific adapter from this directory:

```bash
mix ash_ui.example.basic_dashboard --renderer liveview
mix ash_ui.example.basic_dashboard --renderer elm
mix ash_ui.example.basic_dashboard --renderer desktop
```

`BasicDashboard.seed!/0` uses the configured Ash UI storage resources, so you
can keep the same seed code while changing the backend.
