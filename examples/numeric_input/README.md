# Numeric Input Example

This standalone Phoenix LiveView app demonstrates the `numeric_input` example from
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

## Expect

Meaningful Interaction Story: change the numeric value and confirm the preview stat reflects the stored example-state value without pretending Ash UI is doing hidden coercion.

Canonical Signal Preview: change -> ExampleState.current_value -> specialized numeric input props and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/numeric_input")"`
