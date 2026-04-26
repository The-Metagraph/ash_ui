# Menu Example

This standalone Phoenix LiveView app demonstrates the `menu` example from
the Phase 19 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer, shown through the
example's Phoenix LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Try It

Click the nested navigation buttons and confirm the selected value updates without moving the action ownership onto the outer custom shell.

## Widget Attributes and Properties

Subject widget type: `custom:menu`

Authored properties:

```elixir
%{
  description: "Nested public buttons own selection changes inside an explicit custom menu shell.",
  title: "Workspace menu",
  class: "ashui-example-menu-shell"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a dedicated example-only custom shell with nested public buttons.

## Expect

Meaningful Interaction Story: select a menu item and confirm the selection state changes through nested public button resources while the outer subject remains an explicit `custom:menu` shell.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> menu summary text and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/menu")"`
