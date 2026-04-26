# List Example

This standalone Phoenix LiveView app demonstrates the `list` example from
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

Switch the active dataset with the nested controls and confirm the collection surface refreshes through persisted bound data.

## Expect

Meaningful Interaction Story: switch between review queues and confirm the collection surface refreshes through a list binding instead of hard-coded inline rows.

Canonical Signal Preview: nested button click -> ExampleState.items -> hydrated `list` props.items plus preview status inside the shared Ash HQ shell.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Data-surface examples expose the active dataset through preview and status copy as soon as the seeded screen mounts. Fallback or warning states must stay visible in the shared shell status copy rather than being implied by an empty collection alone. Operator-driven dataset changes and runtime notifications refresh the mounted viewer session through real binding reevaluation.

## Validate

`mix run --no-start -e "IO.puts("example/list")"`
