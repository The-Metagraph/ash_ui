# Chapter 2 - Services and Incidents Checkpoint

This standalone Phoenix LiveView app is the checkpoint for
`tutorials/chapters/02-services-and-incidents.md`.

It adds the first operational workspace, with separate services and incidents
screens that share one seeded runtime state.

## Run

From this directory:

```bash
mix deps.get
mix example.start
```

`mix example.start` starts the default `live_ui` renderer, shown through the
tutorial's Phoenix LiveView host at `http://127.0.0.1:5000/`.

To preview another runtime, pass its name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

If the server is already running, the same runtime switch can be reviewed by
visiting `/?runtime=live_ui`, `/?runtime=elm_ui`, or
`/?runtime=desktop_ui`.

## Chapter Focus

This checkpoint introduces the first real operator workspace through separate
services and incidents screens, while keeping their data and detail state in a
shared resource-backed runtime model.
