# Tabs Example

This standalone Phoenix LiveView app demonstrates the `tabs` example from
the Phase 19 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Click the nested navigation buttons and confirm the selected value updates without moving the action ownership onto the outer custom shell.

## Expect

Meaningful Interaction Story: switch tabs and confirm the active panel value changes through nested public button resources while the outer subject remains an explicit `custom:tabs` shell.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> active panel text and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/tabs")"`
