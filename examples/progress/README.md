# Progress Example

This standalone Phoenix LiveView app demonstrates the `progress` example from
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

Meaningful Interaction Story: switch the rollout phase and confirm the progress surface updates both its completion amount and explanatory detail.

Canonical Signal Preview: nested button click -> ExampleState.metric -> bound progress model plus preview value.

## Validate

`mix run --no-start -e "IO.puts("example/progress")"`
