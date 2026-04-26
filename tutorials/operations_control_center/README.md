# Operations Control Center

This is the maintained final tutorial application for the Operations Control
Center series.

It now tracks the Chapter 3 milestone from
[`tutorials/code/03-filtering-and-search/`](../code/03-filtering-and-search/):
the shared shell, the persisted services-and-incidents workspace, plus the new
filtering, quick-search, and command-navigation surface. Later phases should
keep advancing this directory, while the checkpoint apps under `tutorials/code/`
remain frozen chapter snapshots.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer inside the Phoenix
LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Current Surface

- Main module:
  [`AshUITutorials.OperationsControlCenter`](./lib/ash_ui_tutorials/operations_control_center.ex)
- Current authoritative screens:
  `tutorial/services-incidents/services` and
  `tutorial/services-incidents/incidents`
- Current story scope:
  services review, incidents review, shared detail focus, persisted filters,
  command navigation, and the maintained shell that later tutorial chapters
  will extend
