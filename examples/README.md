# Examples

This directory contains runnable and copyable Ash UI examples.

## Prerequisites

From the repo root:

```bash
mix deps.get
```

Most example commands expect `MIX_ENV=dev` so the example modules are compiled.

## Available Examples

### `basic_dashboard`

`basic_dashboard` is the reference dashboard example. It seeds ETS-backed demo
data and renders a stored `unified_dsl` screen through Ash UI adapters.

Example files:

- `examples/basic_dashboard/README.md`
- `examples/basic_dashboard/lib/basic_dashboard.ex`
- `examples/basic_dashboard/lib/basic_dashboard_data.ex`
- `examples/basic_dashboard/lib/basic_dashboard_live.ex`
- `examples/basic_dashboard/lib/basic_dashboard_storage.ex`

Adapter options:

- `liveview`: prints HEEx output from the LiveView renderer
- `elm`: prints or writes the Elm-backed web shell
- `desktop`: prints desktop instruction JSON

Commands:

```bash
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer liveview
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer elm
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer elm --output /tmp/basic_dashboard.html
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer desktop
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer desktop --pretty
MIX_ENV=dev mix ash_ui.example.basic_dashboard --renderer elm --strict-external
```

Notes:

- The task configures the example's ETS-backed UI storage automatically.
- `--strict-external` fails instead of using adapter fallback.
- `--output PATH` writes the rendered output to a file.
