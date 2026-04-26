# Button Example

This standalone Phoenix LiveView app demonstrates the `button` example from
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

Click the primary subject and watch the persisted preview surface update.

## Widget Attributes and Properties

Subject widget type: `button`

Authored properties:

```elixir
%{
  label: "Persist button story",
  class: "ashui-example-primary-cta",
  variant: "primary"
}
```

Binding contract: none. This subject widget is rendered without a dedicated binding in the example definition.

Action contract:

```elixir
%{
  id: :press_button,
  metadata: %{intent: "button_press", success_message: "Button example updated"},
  signal: :click,
  params: %{
    status: %{"from" => "static", "value" => "Action completed"},
    current_value: %{"from" => "static", "value" => "Button press persisted"}
  }
}
```

Notes: Uses the current public button widget directly.

## Expect

Meaningful Interaction Story: click the primary button and confirm the current status changes without leaving the resource-authority runtime path.

Canonical Signal Preview: click -> ExampleState.update(status, current_value) through an element-local action.

## Validate

`mix run --no-start -e "IO.puts("example/button")"`
