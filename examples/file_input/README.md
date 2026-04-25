# File Input Example

This standalone Phoenix LiveView app demonstrates the `file_input` example from
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

Meaningful Interaction Story: choose a representative filename and confirm the preview stat records the selection while the support note stays explicit that upload transport is not implemented here.

Canonical Signal Preview: change -> ExampleState.submitted_value -> reviewer-visible selected filename only; no binary upload lifecycle is implied.

## Validate

`mix run --no-start -e "IO.puts("example/file_input")"`
