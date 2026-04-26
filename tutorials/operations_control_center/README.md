# Operations Control Center

This is the maintained final tutorial application for the Operations Control
Center series.

Phase 23 brings this app up to the same milestone as
[`tutorials/code/02-services-and-incidents/`](../code/02-services-and-incidents/):
the shared shell plus the first services and incidents workspace. Later phases
should keep advancing this directory, while the checkpoint apps under
`tutorials/code/` remain frozen chapter snapshots.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer inside the Phoenix
LiveView host at `http://127.0.0.1:5000/`.

Alternate runtime previews are available with:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

## Current Surface

- Main module:
  [`AshUITutorials.OperationsControlCenter`](./lib/ash_ui_tutorials/operations_control_center.ex)
- Current authoritative screens:
  `tutorial/services-incidents/services` and
  `tutorial/services-incidents/incidents`
- Current story scope:
  services review, incidents review, shared detail focus, and the maintained
  shell that later tutorial chapters will extend
