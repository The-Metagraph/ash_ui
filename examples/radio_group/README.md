# Radio Group Example

This standalone Phoenix LiveView app demonstrates the `radio_group` example from
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

Subject widget type: `radio`

Authored properties:

```elixir
%{
  name: "plan",
  value: "pro",
  options: [
    {"Starter", "starter"},
    {"Pro", "pro"},
    {"Enterprise", "enterprise"}
  ],
  class: "ashui-example-radio-group"
}
```

Binding contract:

```elixir
%{
  id: :radio_group_value,
  target: "value",
  field: :selected_value,
  transform: %{}
}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Preserves the sibling directory name while using the canonical radio widget.

## Expect

Meaningful Interaction Story: pick a radio option and confirm the normalized `radio` subject preserves the directory story while the preview stat reflects the selected value.

Canonical Signal Preview: change -> ExampleState.selected_value -> canonical radio-group markup and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/radio_group")"`
