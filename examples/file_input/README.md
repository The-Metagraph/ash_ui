# File Input Example

This standalone Phoenix LiveView app demonstrates the `file_input` example from
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

Meaningful Interaction Story: choose a representative filename and confirm the preview stat records the selection while the support note stays explicit that upload transport is not implemented here.

Canonical Signal Preview: change -> ExampleState.submitted_value -> reviewer-visible selected filename only; no binary upload lifecycle is implied.

## Validate

`mix run --no-start -e "IO.puts("example/file_input")"`
