# List Example

This standalone Phoenix LiveView app demonstrates the `list` example from
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

Switch the active dataset with the nested controls and confirm the collection surface refreshes through persisted bound data.

## Expect

Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows.

Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `list` props.items plus preview status inside the shared Ash HQ shell.

## Validate

`mix run --no-start -e "IO.puts("example/list")"`
