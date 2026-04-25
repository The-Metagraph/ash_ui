# Log Viewer Example

This standalone Phoenix LiveView app demonstrates the `log_viewer` example from
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

Swap the active stream and confirm the visible log rows refresh through persisted runtime entries.

## Expect

Meaningful Interaction Story: switch the active stream and confirm the visible log rows refresh through persisted runtime data rather than one fixed code sample.

Canonical Signal Preview: nested button click -> ExampleState.items -> bound log entries plus active-stream preview state.

## Validate

`mix run --no-start -e "IO.puts("example/log_viewer")"`
