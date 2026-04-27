# Chapter 12 Checkpoint

This standalone Mix/Phoenix app freezes the Chapter 12 tutorial milestone for
`Production Polish`.

It keeps the earlier services, incidents, workflows, guarded actions, runbook
review, diagnostics, topology, metrics, runtime introspection, and actor-aware
policy surfaces, then adds the final product pass: stronger shell navigation,
explicit ready/loading/empty/error review states, and more obvious keyboard and
contrast guidance.

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

This checkpoint is still meant to be reviewed under three seeded actor
profiles:

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

## Production Polish Walkthrough

Both the services and incidents screens now include a `Production polish
walkthrough` panel. Use it to move the current workspace between:

- ready
- loading
- empty
- support-error

Those buttons are not decorative. They exist so the tutorial can teach how
resource-authored screens should behave when the data is fine, when it is still
refreshing, when filters produce zero rows, and when the shell needs to surface
support trouble honestly.
