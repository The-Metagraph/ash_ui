# Grid Example

This standalone Phoenix LiveView app demonstrates the `grid` example from
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

Meaningful Interaction Story: review the multi-tile structure and confirm the grid example keeps tile ordering, spacing, and grouping in related element resources.

Canonical Signal Preview: relationship order + grid props -> rendered tile matrix inside the maintained grid widget.

## Validate

`mix run --no-start -e "IO.puts("example/grid")"`
