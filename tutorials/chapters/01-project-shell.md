# Chapter 1 - Project Shell

## Code For This Chapter

Checkpoint app: `tutorials/code/01-project-shell/`

Previous checkpoint: none.

Supporting examples: `examples/button`, `examples/box`, `examples/grid`, `examples/text`

This chapter establishes the shared shell, the first resource-authority screen,
and the home dashboard baseline for the tutorial application.

## What You Build

The checkpoint app at
[`tutorials/code/01-project-shell/`](../code/01-project-shell/) mounts one
authoritative screen, `tutorial/project-shell/home`, inside the shared Ash HQ
shell that later chapters keep extending.

The home dashboard is intentionally small but real. It uses foundational
widgets such as `text`, `label`, `button`, `icon`, `link`, `separator`,
`spacer`, `content`, `box`, `row`, `column`, and `grid` to prove that the
tutorial starts from persisted screen and element resources instead of ad-hoc
LiveView markup.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.ProjectShell`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex)
- Runtime state resource:
  `AshUITutorials.ProjectShell.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.ProjectShell.UiScreen`,
  `AshUITutorials.ProjectShell.UiElement`, and
  `AshUITutorials.ProjectShell.UiBinding`
- Authoritative screen builder:
  `AshUITutorials.ProjectShell.Examples.HomeScreen`
- LiveView host:
  `AshUITutorials.ProjectShell.Web.HomeLive`

The key code path is `AshUITutorials.ProjectShell.seed!/1`, which seeds one
runtime record, persists the home screen through
`AshUI.Resource.Authority.create/1`, and then allows
`AshUI.LiveView.Integration.mount_ui_screen/3` to hydrate the LiveView socket.

## Run The Checkpoint

From [`tutorials/code/01-project-shell/`](../code/01-project-shell/):

```bash
mix deps.get
mix example.start
```

`mix example.start` is the default path. It starts the `live_ui` renderer and
shows the result through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Alternate runtimes stay secondary in this chapter. You can preview them with:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes use the same authoritative screen definition, but the default
tutorial flow should stay focused on the `live_ui` host until later chapters
need deeper renderer comparisons.
