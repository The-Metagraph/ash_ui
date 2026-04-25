# Supervision Tree Viewer Example

This standalone Phoenix LiveView app demonstrates the `supervision_tree_viewer` example from
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

Switch the active operational snapshot and confirm the surface redraws from persisted runtime data instead of hidden background state.

## Expect

Meaningful Interaction Story: switch the viewed supervision snapshot and confirm the tree structure updates from persisted runtime data instead of a fixed outline.

Canonical Signal Preview: nested button click -> ExampleState.payload -> bound supervision tree model plus preview label.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Operational examples expose the mounted snapshot through shell status copy and support notes instead of pretending to stream unseen background state. Incident and pressure snapshots must render degraded copy inside the primary surface and shared status/footer surfaces. Stable snapshot controls and notification-backed refresh return the mounted view to a healthy state without remounting.

## Validate

`mix run --no-start -e "IO.puts("example/supervision_tree_viewer")"`
