# Context Menu Example

This standalone Phoenix LiveView app demonstrates the `context_menu` example from
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

Trigger one nested menu action and confirm the selected operation is reflected in both the body summary and the preview stat.

## Expect

Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state.

Canonical Signal Preview: nested menu button click -> ExampleState.selected_value -> context-menu summary text and footer status.

## Validate

`mix run --no-start -e "IO.puts("example/context_menu")"`
