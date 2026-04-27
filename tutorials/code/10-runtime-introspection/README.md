# Chapter 10 Checkpoint

This standalone Mix/Phoenix app freezes the Chapter 10 tutorial milestone for
`Runtime Introspection`.

It keeps the earlier services, incidents, workflows, runbook review, seeded
diagnostics, topology-review surfaces, and metrics dashboards, then extends the
services workspace with a resource-authored runtime-introspection panel built
from `custom:command_palette`, `custom:tabs`,
`custom:supervision_tree_viewer`, and `table`.

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
