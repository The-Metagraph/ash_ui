# Text Input Example

This standalone Phoenix LiveView app demonstrates the `text_input` example from
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
  name: "headline",
  type: "text",
  value: "Ada Example",
  placeholder: "Type a label",
  class: "ashui-example-input"
}
```

Binding contract:

```elixir
%{id: :text_input_value, target: "value", field: :display_value, transform: %{}}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Preserves the sibling directory name through the canonical input widget.

## Expect

Meaningful Interaction Story: edit the canonical input control and confirm the preview stat updates through an element-local value binding without bypassing the shared shell.

Canonical Signal Preview: change -> ExampleState.display_value -> input.value and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/text_input")"`
