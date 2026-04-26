# Tabs Example

This standalone Phoenix LiveView app demonstrates the `tabs` example from
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

Subject widget type: `custom:tabs`

Authored properties:

```elixir
%{
  description: "Nested public buttons own tab switching while the outer shell stays explicit.",
  title: "Triage tabs",
  class: "ashui-example-tabs-shell"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a dedicated example-only custom shell with nested public buttons.

## Expect

Meaningful Interaction Story: switch tabs and confirm the active panel value changes through nested public button resources while the outer subject remains an explicit `custom:tabs` shell.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> active panel text and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/tabs")"`
