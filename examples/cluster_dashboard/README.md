# Cluster Dashboard Example

This standalone Phoenix LiveView app demonstrates the `cluster_dashboard` example from
the Phase 20 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer, shown through the
example's Phoenix LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Try It

Switch the active operational snapshot and confirm the surface redraws from persisted runtime data instead of hidden background state.

## Expect

Meaningful Interaction Story: switch the dashboard between stable and incident snapshots and confirm the headline, regional cards, and alert rail all update from persisted runtime data.

Canonical Signal Preview: nested button click -> ExampleState.payload -> bound dashboard model plus preview label.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Operational examples expose the mounted snapshot through shell status copy and support notes instead of pretending to stream unseen background state. Incident and pressure snapshots must render degraded copy inside the primary surface and shared status/footer surfaces. Stable snapshot controls and notification-backed refresh return the mounted view to a healthy state without remounting.

## Validate

`mix run --no-start -e "IO.puts("example/cluster_dashboard")"`
