# Gauge Example

This standalone Phoenix LiveView app demonstrates the `gauge` example from
the Phase 20 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Switch the active feedback state and confirm the visible signal surface updates from persisted runtime metrics.

## Expect

Meaningful Interaction Story: switch the live capacity snapshot and confirm the gauge surface updates both its visible fill amount and its supporting detail.

Canonical Signal Preview: nested button click -> ExampleState.metric -> bound gauge model plus preview state.

## Validate

`mix run --no-start -e "IO.puts("example/gauge")"`
