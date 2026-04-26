# Text Example

This standalone Phoenix LiveView app demonstrates the `text` example from
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

Review the bound content and confirm the preview card reflects the same persisted runtime state.

## Expect

Meaningful Interaction Story: review the authored copy and confirm the shared shell keeps text content legible without bypassing the resource-authority path.

Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.content.

## Validate

`mix run --no-start -e "IO.puts("example/text")"`
