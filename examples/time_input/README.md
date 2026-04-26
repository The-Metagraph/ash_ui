# Time Input Example

This standalone Phoenix LiveView app demonstrates the `time_input` example from
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

Subject widget type: `input`

Authored properties:

```elixir
%{
  name: "start_time",
  type: "time",
  value: "09:30",
  class: "ashui-example-input"
}
```

Binding contract:

```elixir
%{id: :time_input_value, target: "value", field: :current_value, transform: %{}}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses the canonical input widget with time props.

## Expect

Meaningful Interaction Story: adjust the time control and confirm the preview stat stays in sync through the resource-owned binding path.

Canonical Signal Preview: change -> ExampleState.current_value -> specialized time input props and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/time_input")"`
