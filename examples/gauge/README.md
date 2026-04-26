# Gauge Example

This standalone Phoenix LiveView app demonstrates the `gauge` example from
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

Switch the active feedback state and confirm the visible signal surface updates from persisted runtime metrics.

## Expect

Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail.

Canonical Signal Preview: nested button click -> ExampleState.metric -> bound gauge model plus preview state.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Feedback examples mount with an explicit seeded metric snapshot so the first visible state is already reviewer-verifiable. Risk, warning, and degraded chart states remain visible through the rendered metric shell and preview status copy. Operator metric writes and notification-backed refresh restore the viewer-visible signal without ad hoc local state.

## Validate

`mix run --no-start -e "IO.puts("example/gauge")"`
