# Select Example

This standalone Phoenix LiveView app demonstrates the `select` example from
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

Review the focused subject panel together with the story and signal surfaces.

## Expect

Meaningful Interaction Story: change the selected option and confirm the preview stat tracks the current selection through the shared example shell.

Canonical Signal Preview: change -> ExampleState.selected_value -> select.value and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/select")"`
