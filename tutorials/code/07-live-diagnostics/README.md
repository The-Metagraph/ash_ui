# Chapter 7 Checkpoint

This standalone Mix/Phoenix app freezes the Chapter 7 tutorial milestone for
`Live Diagnostics`.

It shows the services and incidents workspaces plus the first resource-backed
diagnostics panel, where authored buttons swap one coherent seeded runtime
scenario across status, inline feedback, log rows, stream entries, and process
monitor snapshots.

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
