# Canvas Example

This standalone Phoenix LiveView app demonstrates the `canvas` example from
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

Trigger the nested action controls and confirm the active pane or layer updates while the larger display surface remains an explicit custom shell.

## Widget Attributes and Properties

Subject widget type: `custom:canvas`

Authored properties:

```elixir
%{
  description: "Toolbar controls and legend copy stay in related child resources while the board remains an explicit custom display surface.",
  title: "Response canvas",
  class: "ashui-example-canvas-shell"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses explicit toolbar, body, and legend slots.

## Expect

Meaningful Interaction Story: switch the active layer from the toolbar and confirm the board plus legend update through nested public controls while the canvas shell remains explicit.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> canvas board copy, legend status, and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/canvas")"`
