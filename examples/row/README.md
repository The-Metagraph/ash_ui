# Row Example

This standalone Phoenix LiveView app demonstrates the `row` example from
the Phase 19 Ash UI suite.

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

Review the rendered lane order and confirm the resource-authored structure stays visible in the mounted shell.

## Expect

Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment.

Canonical Signal Preview: relationship order -> compiler composition -> rendered lane sequence inside the maintained row widget.

## Validate

`mix run --no-start -e "IO.puts("example/row")"`
