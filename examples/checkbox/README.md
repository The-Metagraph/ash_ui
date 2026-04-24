# Checkbox Example

This standalone Phoenix LiveView app demonstrates the `checkbox` example from
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

Meaningful Interaction Story: toggle the checkbox and confirm the preview stat tracks the boolean state through an element-local binding.

Canonical Signal Preview: change -> ExampleState.checked -> checkbox.checked and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/checkbox")"`
