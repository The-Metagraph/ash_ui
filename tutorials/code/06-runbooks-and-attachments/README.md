# Chapter 6 Checkpoint

This standalone Mix/Phoenix app freezes the Chapter 6 tutorial milestone for
`Runbooks and Attachments`.

It shows the services and incidents workspaces plus the first resource-backed
runbook-review panel, where authored markdown, filename-only attachment
capture, an explicit reference link, and an evidence preview image all live in
the same incidents screen graph.

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
