# Chapter 11 Checkpoint

This standalone Mix/Phoenix app freezes the Chapter 11 tutorial milestone for
`Roles and Policies`.

It keeps the earlier services, incidents, workflows, runbook review, seeded
diagnostics, topology-review surfaces, metrics dashboards, and runtime
introspection lanes, then adds actor-aware mounts for `admin`,
`on_call_operator`, and `viewer` so the same resource-authored screens can show
different panels, forms, actions, and policy outcomes.

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

## Actor Mounts

This checkpoint is meant to be reviewed under three seeded actor profiles:

- `admin`
- `on_call_operator`
- `viewer`

Use the built-in actor links in the shell header, or mount a specific actor
directly by query string:

```text
/?actor=admin
/?actor=on_call_operator
/?actor=viewer
```

You can combine actor and runtime, for example:

```text
/?actor=viewer&runtime=desktop_ui
```
