# Pick List Example

This standalone Phoenix LiveView app demonstrates the `pick_list` example from
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

Subject widget type: `custom:pick_list`

Authored properties:

```elixir
%{
  name: "role",
  value: "ops",
  options: [
    {"Operations", "ops"},
    {"Finance", "finance"},
    {"Support", "support"}
  ],
  class: "ashui-example-pick-list"
}
```

Binding contract:

```elixir
%{id: :pick_list_value, target: "value", field: :selected_value, transform: %{}}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses an explicit custom surface until a public pick-list contract exists.

## Expect

Meaningful Interaction Story: choose one promoted pick-list option and confirm the custom surface stays explicit about the current single-selection runtime boundary.

Canonical Signal Preview: change -> ExampleState.selected_value -> custom pick-list surface and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/pick_list")"`
