# Operations Control Center

This is the maintained final tutorial application for the Operations Control
Center series.

It now tracks the Chapter 12 milestone from
[`tutorials/code/12-production-polish/`](../code/12-production-polish/): the
shared shell, actor-aware mounts, authored services and incidents workspaces,
runbook review, diagnostics, topology, metrics, runtime introspection, and the
final production-polish pass with explicit ready/loading/empty/error review
states.

If you want the frozen chapter checkpoint, start in
[`tutorials/code/12-production-polish/`](../code/12-production-polish/). If
you want the maintained completed reference, stay here.

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

You can still mount the maintained app for a specific actor profile:

```text
/?actor=admin
/?actor=on_call_operator
/?actor=viewer
```

## Allowed Differences From Chapter 12

This directory is intentionally kept very close to
[`tutorials/code/12-production-polish/`](../code/12-production-polish/). The
allowed differences are narrow and documented:

- module and OTP app names use `AshUITutorials.OperationsControlCenter` and
  `:ash_ui_tutorial_operations_control_center`
- screen metadata identifies the maintained directory with
  `tutorial_directory: "operations_control_center"`
- shell ids and iframe titles use `operations-control-center-*`
- this README and the top-level summary copy describe the maintained-final-app
  role rather than the Chapter 12 checkpoint role

The authored screen graph, resource structure, routes, shell behavior, actor
switching, runtime switching, and production-polish review states should remain
aligned with the Chapter 12 checkpoint.

## Traceability

- Maintained final app module:
  [`AshUITutorials.OperationsControlCenter`](./lib/ash_ui_tutorials/operations_control_center.ex)
- Chapter 12 checkpoint module:
  [`AshUITutorials.ProductionPolish`](../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex)

Keep the maintained app readable as a tutorial product. When possible, prefer a
direct sync from the Chapter 12 checkpoint over extracting opaque shared helper
layers.
