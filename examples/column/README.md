# Column Example

This standalone Phoenix LiveView app demonstrates the `column` example from
the Phase 19 Ash UI suite.

It preserves the sibling `unified_ui` directory name while rebuilding the
example through resource-authority screens, related element resources, and the
shared Ash HQ shell.

## Run

From this directory:

`mix deps.get`
`mix phx.server`

The app mounts at `http://127.0.0.1:5000/` by default.

## Try It

Review the rendered lane order and confirm the resource-authored structure stays visible in the mounted shell.

## Expect

Meaningful Interaction Story: inspect the vertical review flow and confirm the column example makes ordering obvious through related child resources and consistent spacing.

Canonical Signal Preview: relationship order -> compiler composition -> rendered stack sequence inside the maintained column widget.

## Validate

`mix run --no-start -e "IO.puts("example/column")"`
