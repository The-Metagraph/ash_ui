# Row Example

This standalone Phoenix LiveView app demonstrates the `row` example from
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

Meaningful Interaction Story: review the horizontal lane sequence and confirm the row example compiles its order from related child resources rather than one inline screen fragment.

Canonical Signal Preview: relationship order -> compiler composition -> rendered lane sequence inside the maintained row widget.

## Validate

`mix run --no-start -e "IO.puts("example/row")"`
