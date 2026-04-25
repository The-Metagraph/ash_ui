# Form Builder Example

This standalone Phoenix LiveView app demonstrates the `form_builder` example from
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

Edit the nested form field, submit the form, and confirm the preview surface captures the persisted result.

## Expect

Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph.

Canonical Signal Preview: nested input change -> ExampleState.display_value; form submit -> ExampleState.submitted_value and ExampleState.status.

## Validate

`mix run --no-start -e "IO.puts("example/form_builder")"`
