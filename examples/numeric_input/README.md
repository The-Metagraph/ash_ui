# Numeric Input Example

This standalone Phoenix LiveView app demonstrates the `numeric_input` example from
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

Meaningful Interaction Story: change the numeric value and confirm the preview stat reflects the stored example-state value without pretending Ash UI is doing hidden coercion.

Canonical Signal Preview: change -> ExampleState.current_value -> specialized numeric input props and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/numeric_input")"`
