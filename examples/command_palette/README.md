# Command Palette Example

This standalone Phoenix LiveView app demonstrates the `command_palette` example from
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

Change the query, trigger a command button, and confirm the last-command preview updates through nested public controls.

## Expect

Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit.

Canonical Signal Preview: input change -> ExampleState.current_value; nested button click -> ExampleState.submitted_value and ExampleState.status.

## Validate

`mix run --no-start -e "IO.puts("example/command_palette")"`
