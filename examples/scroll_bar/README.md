# Scroll Bar Example

This standalone Phoenix LiveView app demonstrates the `scroll_bar` example from
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

Subject widget type: `custom:scroll_bar`

Authored properties:

```elixir
%{
  description: "Nested public buttons shift the focused lane while the outer custom shell owns the larger scroll-track surface only.",
  title: "Lane scroll",
  class: "ashui-example-scroll-bar-shell",
  thumb_label: "queue lane"
}
```

Binding contract:

```elixir
%{
  id: :scroll_thumb_focus,
  target: "thumb_label",
  field: :selected_value,
  transform: %{}
}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses an explicit custom shell with a bound thumb label.

## Expect

Meaningful Interaction Story: change the scroll focus through nested public buttons and confirm the thumb label plus status copy update without turning `scroll_bar` into an admitted public widget.

Canonical Signal Preview: nested button click -> ExampleState.selected_value -> thumb label binding, body copy, and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/scroll_bar")"`
