# Form Builder Example

This standalone Phoenix LiveView app demonstrates the `form_builder` example from
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

Edit the nested form field, submit the form, and confirm the preview surface captures the persisted result.

## Expect

Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph.

Canonical Signal Preview: nested input change -> ExampleState.display_value; form submit -> ExampleState.submitted_value and ExampleState.status.

## Validate

`mix run --no-start -e "IO.puts("example/form_builder")"`
