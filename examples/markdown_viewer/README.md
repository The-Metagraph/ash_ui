# Markdown Viewer Example

This standalone Phoenix LiveView app demonstrates the `markdown_viewer` example from
the Phase 20 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Review the bound content and confirm the preview card reflects the same persisted runtime state.

## Expect

Meaningful Interaction Story: switch the active document and confirm the markdown viewer updates its rendered body from persisted runtime content instead of duplicated static copy.

Canonical Signal Preview: nested button click -> ExampleState.notes -> bound markdown content plus active-document preview.

## Validate

`mix run --no-start -e "IO.puts("example/markdown_viewer")"`
