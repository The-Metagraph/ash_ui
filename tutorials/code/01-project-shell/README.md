# Chapter 1 - Project Shell Checkpoint

This standalone Phoenix LiveView app is the checkpoint for
`tutorials/chapters/01-project-shell.md`.

It establishes the shared Operations Control Center shell, the first
resource-authority screen, and the initial home-dashboard review path.

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

This checkpoint proves the shell, dashboard, and screen bootstrap path before
the tutorial adds richer workspaces in later chapters.
