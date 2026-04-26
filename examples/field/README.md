# Field Example

This standalone Phoenix LiveView app demonstrates the `field` example from
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

Subject widget type: `form_field`

Authored properties:

```elixir
%{
  label: "Display name",
  name: "display_name",
  help: "Field structure stays local to the resource graph.",
  class: "ashui-example-form-field"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Preserves sibling naming while using the public form_field widget.

## Expect

Meaningful Interaction Story: review the field wrapper and edit the nested input to confirm the field keeps label and help context while the write remains owned by the input element.

Canonical Signal Preview: nested input change -> ExampleState.display_value -> preview stat, while `field` stays normalized to the canonical `form_field` widget.

## Validate

`mix run --no-start -e "IO.puts("example/field")"`
