# Table Example

This standalone Phoenix LiveView app demonstrates the `table` example from
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

Meaningful Interaction Story: switch the active operational dataset and confirm the table rows refresh through list binding hydration instead of a one-shot render.

Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `table` props.items plus preview value for the active dataset.

## Validate

`mix run --no-start -e "IO.puts("example/table")"`
