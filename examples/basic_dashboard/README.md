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

## Run It

This example is now a standalone Phoenix app. From this directory:

```bash
mix setup
mix phx.server
```

Then open [http://localhost:4100](http://localhost:4100).

The app runs entirely on ETS-backed Ash resources for both dashboard data and
UI-definition storage, so it does not require Postgres.

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

To render the example directly through a specific adapter from this directory:

```bash
mix ash_ui.example.basic_dashboard --renderer liveview
mix ash_ui.example.basic_dashboard --renderer elm
mix ash_ui.example.basic_dashboard --renderer desktop
```

`BasicDashboard.seed!/0` uses the configured Ash UI storage resources, so you
can keep the same seed code while changing the backend.
