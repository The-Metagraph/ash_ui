# Checkbox Example

This standalone Phoenix LiveView app demonstrates the `checkbox` example from
the Phase 18 Ash UI suite.

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

Review the focused subject panel together with the story and signal surfaces.

## Widget Attributes and Properties

Subject widget type: `checkbox`

Authored properties:

```elixir
%{name: "receive_updates", class: "ashui-example-checkbox", checked: true}
```

Binding contract:

```elixir
%{id: :checkbox_value, target: "checked", field: :checked, transform: %{}}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses the current public checkbox widget directly.

## Expect

Meaningful Interaction Story: toggle the checkbox and confirm the preview stat tracks the boolean state through an element-local binding.

Canonical Signal Preview: change -> ExampleState.checked -> checkbox.checked and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/checkbox")"`
