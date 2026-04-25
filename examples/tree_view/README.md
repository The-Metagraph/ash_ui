# Tree View Example

This standalone Phoenix LiveView app demonstrates the `tree_view` example from
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

Swap the focused hierarchy and confirm the rendered tree redraws from bound runtime data instead of a static outline.

## Expect

Meaningful Interaction Story: switch the focused hierarchy and confirm the tree viewer redraws its nested branches from persisted runtime data rather than a static shell.

Canonical Signal Preview: nested button click -> ExampleState.items -> bound tree model plus selected-branch preview.

## Validate

`mix run --no-start -e "IO.puts("example/tree_view")"`
