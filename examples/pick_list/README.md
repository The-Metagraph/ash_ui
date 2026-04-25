# Pick List Example

This standalone Phoenix LiveView app demonstrates the `pick_list` example from
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

Review the focused subject panel together with the story and signal surfaces.

## Expect

Meaningful Interaction Story: choose one promoted pick-list option and confirm the custom surface stays explicit about the current single-selection runtime boundary.

Canonical Signal Preview: change -> ExampleState.selected_value -> custom pick-list surface and preview stat.

## Validate

`mix run --no-start -e "IO.puts("example/pick_list")"`
