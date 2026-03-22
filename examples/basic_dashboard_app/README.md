# Basic Dashboard Standalone App

This is a minimal Phoenix host app for the Ash UI `basic_dashboard` example.

It runs the themed dashboard example as a real browser application while keeping:

- Ash UI screen, element, and binding storage in PostgreSQL through `AshUI.Repo`
- dashboard domain data in ETS through `BasicDashboard.Domain`
- the existing `BasicDashboard`, `BasicDashboard.Data`, and `BasicDashboardLive` example modules

## Run It

From the repo root:

```bash
cd examples/basic_dashboard_app
mix setup
mix phx.server
```

Then open:

```text
http://localhost:4100
```

## Requirements

- PostgreSQL running locally
- default local credentials:
  - username: `postgres`
  - password: `postgres`

You can override database settings with environment variables:

- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `DATABASE_HOSTNAME`
- `DATABASE_PORT`
- `DATABASE_NAME`
- `PORT`

## Notes

- The first `mix setup` creates and migrates the Ash UI database used for screen storage.
- The dashboard's example domain data is still seeded into ETS on mount.
- The app compiles the shared example modules from `../basic_dashboard/lib`.
