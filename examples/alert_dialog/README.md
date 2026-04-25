# Alert Dialog Example

This standalone Phoenix LiveView app demonstrates the `alert_dialog` example from
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

Choose one nested decision button and confirm the persisted result closes the modal shell while updating the preview stat.

## Expect

Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> alert decision summary plus dismissal state on the explicit `custom:alert_dialog` shell.

## Validate

`mix run --no-start -e "IO.puts("example/alert_dialog")"`
