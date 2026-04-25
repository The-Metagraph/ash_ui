# Dialog Example

This standalone Phoenix LiveView app demonstrates the `dialog` example from
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

Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.

Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/dialog")"`
