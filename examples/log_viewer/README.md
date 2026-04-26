# Log Viewer Example

This standalone Phoenix LiveView app demonstrates the `log_viewer` example from
the Phase 20 Ash UI suite.

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

Swap the active stream and confirm the visible log rows refresh through persisted runtime entries.

## Widget Attributes and Properties

Subject widget type: `custom:log_viewer`

Authored properties:

```elixir
%{
  description: "A bounded log review surface fed by persisted runtime rows.",
  title: "Event stream",
  class: "ashui-example-log-shell"
}
```

Binding contract:

```elixir
%{
  id: :log_entries,
  target: "entries",
  field: :items,
  transform: %{},
  binding_type: :value
}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Uses a bound entry list and nested controls to swap representative streams.

## Expect

Meaningful Interaction Story: switch the active stream and confirm the visible log rows refresh through persisted runtime data rather than one fixed code sample.

Canonical Signal Preview: nested button click -> ExampleState.items -> bound log entries plus active-stream preview state.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Data-surface examples expose the active dataset through preview and status copy as soon as the seeded screen mounts. Fallback or warning states must stay visible in the shared shell status copy rather than being implied by an empty collection alone. Operator-driven dataset changes and runtime notifications refresh the mounted viewer session through real binding reevaluation.

## Validate

`mix run --no-start -e "IO.puts("example/log_viewer")"`
