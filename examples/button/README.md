# Button Example

This standalone Phoenix LiveView app demonstrates the `button` example from
the Phase 18 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Click the primary subject and watch the persisted preview surface update.

## Expect

Meaningful Interaction Story: click the primary button and confirm the current status changes without leaving the resource-authority runtime path.

Canonical Signal Preview: click -> ExampleState.update(status, current_value) through an element-local action.

## Validate

`mix run --no-start -e "IO.puts("example/button")"`
