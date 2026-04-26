# Field Group Example

This standalone Phoenix LiveView app demonstrates the `field_group` example from
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

Subject widget type: `custom:field_group`

Authored properties:

```elixir
%{
  description: "A grouped review subject can still compile from native form resources.",
  title: "Profile fields",
  class: "ashui-example-field-group"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a composed native screen pattern behind a custom review surface.

## Expect

Meaningful Interaction Story: edit either grouped field and confirm the example stays explicit that `field_group` is a composed review subject built from nested `form_field` resources.

Canonical Signal Preview: grouped child inputs change -> ExampleState.display_value and ExampleState.notes while the outer subject remains `custom:field_group`.

## Validate

`mix run --no-start -e "IO.puts("example/field_group")"`
