# Text Example

This standalone Phoenix LiveView app demonstrates the `text` example from
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

Review the bound content and confirm the preview card reflects the same persisted runtime state.

## Expect

Meaningful Interaction Story: review the authored copy and confirm the shared shell keeps text content legible without bypassing the resource-authority path.

Canonical Signal Preview: value binding -> ExampleState.display_value -> subject.content.

## Validate

`mix run --no-start -e "IO.puts("example/text")"`
