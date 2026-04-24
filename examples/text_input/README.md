# Text Input Example

This standalone Phoenix LiveView app demonstrates the `text_input` example from
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

Meaningful Interaction Story: edit the canonical input control and confirm the preview stat updates through an element-local value binding without bypassing the shared shell.

Canonical Signal Preview: change -> ExampleState.display_value -> input.value and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/text_input")"`
