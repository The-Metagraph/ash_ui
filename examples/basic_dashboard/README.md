# Basic Dashboard Example

This example shows the smallest practical Ash UI flow in a Phoenix application:

1. create a screen with stored `unified_dsl`
2. seed ETS-backed Ash resources for dashboard data
3. mount it through `AshUI.LiveView.Integration`
4. delegate user events through `AshUI.LiveView.EventHandler`

## Files

- `lib/basic_dashboard.ex`: seed helpers that create the screen, elements, and bindings
- `lib/basic_dashboard_data.ex`: example Ash domain and ETS-backed resources
- `lib/basic_dashboard_live.ex`: a LiveView that mounts the screen and forwards events

## Suggested Use

Treat this directory as a reference implementation to copy into an app while wiring your own repo, router, and user lookup.

The example data uses `Ash.DataLayer.Ets`, which is ideal for demos, tests, and lightweight prototypes.

## Core Flow

```elixir
BasicDashboard.Data.seed!()
BasicDashboard.seed!()
```

Then route a LiveView to the dashboard screen name:

```elixir
live "/dashboard", BasicDashboardLive
```
