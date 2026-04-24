# Date Input Example

This standalone Phoenix LiveView app demonstrates the `date_input` example from
the Phase 18 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Review the focused subject panel together with the story and signal surfaces.

## Expect

Meaningful Interaction Story: choose a date and confirm the preview stat reflects the authored input state inside the shared form-oriented shell.

Canonical Signal Preview: change -> ExampleState.current_value -> specialized date input props and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/date_input")"`
