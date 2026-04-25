# Menu Example

This standalone Phoenix LiveView app demonstrates the `menu` example from
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

Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> menu summary text and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/menu")"`
