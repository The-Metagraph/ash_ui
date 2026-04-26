# Viewport Example

This standalone Phoenix LiveView app demonstrates the `viewport` example from
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

Use the nested focus controls and confirm the larger display shell updates without moving state ownership onto the outer custom surface.

## Widget Attributes and Properties

Subject widget type: `custom:viewport`

Authored properties:

```elixir
%{
  description: "Nested public buttons in the aside move viewport focus while the larger shell stays explicit.",
  title: "Operations viewport",
  class: "ashui-example-viewport-shell"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a dedicated example-only custom shell with bound body and footer text.

## Expect

Meaningful Interaction Story: change the focused lane from the viewport aside and confirm the larger display surface updates through nested public controls rather than a monolithic screen authority fragment.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> viewport body copy, footer status, and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/viewport")"`
