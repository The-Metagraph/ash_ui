# Command Palette Example

This standalone Phoenix LiveView app demonstrates the `command_palette` example from
the Phase 19 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Change the query, trigger a command button, and confirm the last-command preview updates through nested public controls.

## Expect

Meaningful Interaction Story: change the query and execute a command to confirm the example keeps both the input and the actions on nested public child resources while the shell remains explicit.

Canonical Signal Preview: input change -> ExampleState.current_value; nested button click -> ExampleState.submitted_value and ExampleState.status.

## Validate

`mix run --no-start -e "IO.puts("example/command_palette")"`
