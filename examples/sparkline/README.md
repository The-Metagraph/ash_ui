# Sparkline Example

This standalone Phoenix LiveView app demonstrates the `sparkline` example from
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

Swap the active series and confirm the chart surface redraws from persisted runtime points.

## Expect

Meaningful Interaction Story: switch the active mini-series and confirm the sparkline redraws its trend points from persisted runtime data.

Canonical Signal Preview: nested button click -> ExampleState.series -> bound sparkline points plus preview series label.

Runtime contract:
- Mount path: active viewers can mount the seeded screen, but mutating controls are reserved for operators and admins.
- Refresh path: mounted viewers stay current through `ExampleState` notifications and LiveView binding reevaluation, not only by remounting the screen.
- Shell state path: Feedback examples mount with an explicit seeded metric snapshot so the first visible state is already reviewer-verifiable. Risk, warning, and degraded chart states remain visible through the rendered metric shell and preview status copy. Operator metric writes and notification-backed refresh restore the viewer-visible signal without ad hoc local state.

## Validate

`mix run --no-start -e "IO.puts("example/sparkline")"`
