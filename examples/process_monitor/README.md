# Process Monitor Example

This standalone Phoenix LiveView app demonstrates the `process_monitor` example from
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

Switch the active operational snapshot and confirm the surface redraws from persisted runtime data instead of hidden background state.

## Expect

Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders.

Canonical Signal Preview: nested button click -> ExampleState.payload -> bound process monitor model plus preview label.

## Validate

`mix run --no-start -e "IO.puts("example/process_monitor")"`
