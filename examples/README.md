# Examples

This directory contains runnable and copyable Ash UI examples.

## Prerequisites

From an example directory:

```bash
mix deps.get
```

Standalone example apps can then be started directly from their own directory.

## Available Examples

### `basic_dashboard`

`basic_dashboard` is the reference dashboard example. It now ships as a
standalone Phoenix app, seeds ETS-backed demo data, and renders a stored
`unified_dsl` screen through Ash UI adapters.

The dashboard screen itself is authored through upstream `UnifiedUi.Dsl` and
persisted through `AshUI.Authoring.Screen`, so the example demonstrates the
current intended authoring boundary directly.

Example files:

- `examples/basic_dashboard/README.md`
- `examples/basic_dashboard/lib/basic_dashboard.ex`
- `examples/basic_dashboard/lib/basic_dashboard_authored_screen.ex`
- `examples/basic_dashboard/lib/basic_dashboard_data.ex`
- `examples/basic_dashboard/lib/basic_dashboard_live.ex`
- `examples/basic_dashboard/lib/basic_dashboard_storage.ex`

Run the standalone app:

- `mix setup`: installs dependencies for the example app
- `mix phx.server`: starts the dashboard at `http://localhost:4100`

Adapter options:

- `liveview`: prints HEEx output from the LiveView renderer
- `elm`: prints or writes the Elm-backed web shell
- `desktop`: prints desktop instruction JSON

Current parity coverage:

- `liveview` and `elm` are covered for the full dashboard screen
- `desktop` remains a work in progress
- `terminal_ui` is not yet implemented in this repo

Commands:

```bash
cd examples/basic_dashboard
mix setup
mix phx.server

mix ash_ui.example.basic_dashboard --renderer liveview
mix ash_ui.example.basic_dashboard --renderer elm
mix ash_ui.example.basic_dashboard --renderer elm --output /tmp/basic_dashboard.html
mix ash_ui.example.basic_dashboard --renderer desktop
mix ash_ui.example.basic_dashboard --renderer desktop --pretty
mix ash_ui.example.basic_dashboard --renderer elm --strict-external
```

Notes:

- The task configures the example's ETS-backed UI storage automatically.
- `--strict-external` fails instead of using adapter fallback.
- `--output PATH` writes the rendered output to a file.
