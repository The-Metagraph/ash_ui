# Basic Dashboard Example

This example shows the intended Ash UI authoring model in a Phoenix
application:

1. define a screen resource with `AshUI.Resource.DSL.Screen`
2. define related element resources with `AshUI.Resource.DSL.Element`
3. persist the composed screen authority graph with `AshUI.Resource.Authority`
4. seed ETS-backed Ash resources for dashboard data
5. mount it through `AshUI.LiveView.Integration`
6. delegate user events through `AshUI.LiveView.EventHandler`
7. render the stored screen through `liveview`, `elm`, or `desktop` adapters

## Files

- `lib/basic_dashboard.ex`: seed helpers plus authority-graph inspection helpers
- `lib/basic_dashboard_screen.ex`: screen and element resource modules for the dashboard graph
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

Adapter parity coverage currently exercises `liveview` and `elm` against the
same persisted screen authority graph and related element modules. `desktop` is
still considered work in progress, and `terminal_ui` is not yet present in this
repo.

`BasicDashboard.seed!/0` persists the relationship-driven
`BasicDashboard.Screen` resource through `AshUI.Resource.Authority`, so the
example demonstrates the same screen and element resource boundary that Ash UI
now expects in production code. The tiny `inline_fragment` on the screen exists
only for shell chrome; the actual dashboard body comes from related element
resources.
