# Process Monitor Example

This standalone Phoenix LiveView app demonstrates the `process_monitor` example from
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

Switch the active operational snapshot and confirm the surface redraws from persisted runtime data instead of hidden background state.

## Widget Attributes and Properties

Subject widget type: `custom:process_monitor`

Authored properties:

```elixir
%{
  description: "A compact runtime process surface fed by one persisted model snapshot.",
  title: "Process monitor",
  class: "ashui-example-process-monitor-shell"
}
```

Binding contract:

```elixir
%{
  id: :process_monitor_model,
  target: "model",
  field: :payload,
  transform: %{},
  binding_type: :value
}
```

Action contract: none. This subject widget is rendered without a dedicated action in the example definition.

Notes: Binds one process monitor model map into a renderer-backed operational shell.

## Expect

Meaningful Interaction Story: switch the monitored process state and confirm the visible process cards update from persisted runtime data rather than decorative placeholders.

Canonical Signal Preview: nested button click -> ExampleState.payload -> bound process monitor model plus preview label.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Operational examples expose the mounted snapshot through shell status copy and support notes instead of pretending to stream unseen background state. Incident and pressure snapshots must render degraded copy inside the primary surface and shared status/footer surfaces. Stable snapshot controls and notification-backed refresh return the mounted view to a healthy state without remounting.

## Validate

`mix run --no-start -e "IO.puts("example/process_monitor")"`
