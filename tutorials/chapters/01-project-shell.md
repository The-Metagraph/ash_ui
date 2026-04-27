# Chapter 1 - Project Shell

## Code For This Chapter

Checkpoint app: `tutorials/code/01-project-shell/`

Previous checkpoint: none.

Supporting examples: `examples/button`, `examples/box`, `examples/grid`, `examples/text`

This chapter builds the first real screen for the tutorial application: a small
home dashboard for the Operations Control Center. The point is not just to
paint a shell around some copy. The point is to establish the architectural
pattern that every later chapter will keep using:

- runtime data lives in Ash resources
- UI structure lives in persisted `UiScreen`, `UiElement`, and `UiBinding` resources
- resource modules author the screen
- Phoenix LiveView hosts the result instead of owning the dashboard structure

By the end of the chapter, the checkpoint app at
[`tutorials/code/01-project-shell/`](../code/01-project-shell/) serves one
authoritative screen, `tutorial/project-shell/home`, inside a themed shell that
matches the Ash HQ baseline.

## What You Are Building

The finished Chapter 1 screen has four jobs:

1. introduce the tutorial application with a recognizable shell
2. prove that the first dashboard is composed from persisted screen resources
3. show a few seeded operational facts such as service count and current on-call owner
4. demonstrate one real interaction, where a button updates runtime state and the UI rehydrates through bindings

The screen is intentionally small. That is a feature, not a compromise. It lets
you focus on the resource-authority model before later chapters add navigation,
forms, overlays, diagnostics, and larger review surfaces.

## Start With The Final Architecture

Before placing widgets, it helps to understand the four layers in the
checkpoint app:

1. [`AshUITutorials.ProjectShell`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex) is the orchestration entry point.
2. `AshUITutorials.ProjectShell.Runtime.WorkspaceState` owns the runtime values the dashboard will read and update.
3. `AshUITutorials.ProjectShell.UiScreen`, `AshUITutorials.ProjectShell.UiElement`, and `AshUITutorials.ProjectShell.UiBinding` store the authored screen graph and binding definitions.
4. `AshUITutorials.ProjectShell.Web.HomeLive` mounts the persisted screen and renders the chosen runtime output inside the themed host shell.

If you want to follow the chapter from top to bottom in one source file, use:

- [`../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex)

That file contains the runtime state resource, the UI storage resources, the
screen and element definitions, and the LiveView host, so the Chapter 1 story
stays easy to follow.

## The Widget Plan For This Chapter

Chapter 1 uses a deliberately small widget set:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `card` | Root hero panel and summary stat tiles | Gives the dashboard a clear panel structure |
| `column` | Main header stack | Lets the introductory copy read top-to-bottom |
| `row` | Title row, action row, footer row | Groups small related controls horizontally |
| `text` | Kicker, title, summary, stat labels, stat values, footer copy, story copy, signal copy | Carries most of the visible content |
| `icon` | Title row and footer row | Adds light visual anchors without adding complexity |
| `label` | Status surface in the hero header | Makes the runtime state stand apart from ordinary copy |
| `divider` | End of the header block | Separates the introduction from the first action |
| `button` | Review acknowledgement action | Gives the chapter a real state-changing path |
| `custom:link` | Secondary Ash HQ reference action | Shows that the screen can mix actions with references |
| `spacer` | Action row | Adds breathing room in the horizontal control cluster |
| `grid` | Three summary cards | Establishes the dashboard layout pattern later chapters will expand |

The lesson here is simple: use a small set of widgets to prove the architecture
first. We are not trying to show every widget in Chapter 1. We are trying to
show how widgets fit into the screen graph.

## Build The Runtime Story First

Start by defining the values that the UI will read. In
[`project_shell.ex`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex),
`seed_state/0` produces the initial runtime record:

- `status`
- `current_value`
- `hero_summary`
- `next_step`
- `services_count`
- `incidents_count`
- `on_call_name`

Those values belong in `AshUITutorials.ProjectShell.Runtime.WorkspaceState`
because they are application state, not presentation structure. The screen
graph answers "what should be on screen?" and the runtime resource answers
"what values should those widgets show right now?".

Chapter 1 also seeds believable operator data from the shared Phase 23
fixtures. That is why the service count and incident count already feel like
real operational data even though the app only has one screen at this point.

## Create The Persisted UI Storage Boundary

Once runtime state exists, define the storage resources that will hold the
screen graph:

- `AshUITutorials.ProjectShell.UiScreen`
- `AshUITutorials.ProjectShell.UiElement`
- `AshUITutorials.ProjectShell.UiBinding`

These are the persistence boundary for the authored UI. They are the reason the
dashboard is not hardcoded inside `render/1`.

The helper `ui_storage/0` in
`AshUITutorials.ProjectShell` packages those resources into the storage
contract that `AshUI.Resource.Authority.create/1` and
`AshUI.LiveView.Integration.mount_ui_screen/3` use later.

## Author The Screen Root

The screen root is:

- `AshUITutorials.ProjectShell.Examples.HomeScreen`

This module does three important things:

1. sets `layout(:column)` so the page flows vertically
2. sets `route("/")` so the checkpoint app opens directly on the dashboard
3. declares child relationships for the major surfaces on the page

The screen-level relationships are:

- `home_panels`
- `story_texts`
- `signal_texts`

That means the Chapter 1 screen is made of:

1. one main dashboard panel
2. one explanation block for the interaction story
3. one explanation block for the signal flow

That is a nice early tutorial pattern because the live demo and the teaching
copy live in the same resource-authored screen.

## Build The Main Dashboard Panel

The main surface is
`AshUITutorials.ProjectShell.Examples.HomePanelElement`. It is a `card`, and
it acts as the parent container for the whole visible dashboard.

Its child relationships are:

- `header_columns`
- `action_rows`
- `summary_grids`
- `footer_rows`

That relationship list already tells the story of the screen:

1. explain the dashboard
2. provide one action
3. show key numbers
4. show the current stage and what comes next

### Header Composition

The header is built with
`AshUITutorials.ProjectShell.Examples.HomeHeaderColumnElement`, which is a
`column`.

Inside that column, place:

- `AshUITutorials.ProjectShell.Examples.HomeKickerTextElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeTitleRowElement` as `row`
- `AshUITutorials.ProjectShell.Examples.HomeSummaryTextElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeStatusLabelElement` as `label`
- `AshUITutorials.ProjectShell.Examples.HomeDividerElement` as `divider`

The title row then groups:

- `AshUITutorials.ProjectShell.Examples.HomeTitleIconElement` as `icon`
- `AshUITutorials.ProjectShell.Examples.HomeTitleTextElement` as `text`

This is a good early example of widget placement following meaning instead of
styling. The icon belongs with the title, so it lives in the title row.

### Action Composition

After the header, add
`AshUITutorials.ProjectShell.Examples.HomeActionRowElement` as a `row`. This
row carries the first operator controls:

- `AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement` as `button`
- `AshUITutorials.ProjectShell.Examples.HomeDocsLinkElement` as `custom:link`
- `AshUITutorials.ProjectShell.Examples.HomeActionSpacerElement` as `spacer`

Use a `button` because the user is changing application state. Use the link
because the user is navigating to a reference. That distinction is worth
establishing from the first chapter.

### Summary Grid Composition

The stat area lives in
`AshUITutorials.ProjectShell.Examples.HomeSummaryGridElement`, which is a
`grid` containing three cards:

- `AshUITutorials.ProjectShell.Examples.HomeServicesCardElement`
- `AshUITutorials.ProjectShell.Examples.HomeIncidentsCardElement`
- `AshUITutorials.ProjectShell.Examples.HomeOnCallCardElement`

Each card contains two `text` widgets:

- a label for what the number means
- a value that binds to the current runtime state

This lets Chapter 1 feel like a dashboard without introducing denser surfaces
like tables or lists yet.

### Footer Composition

The footer comes from
`AshUITutorials.ProjectShell.Examples.HomeFooterRowElement`, another `row`.
It carries:

- `AshUITutorials.ProjectShell.Examples.HomeSignalIconElement` as `icon`
- `AshUITutorials.ProjectShell.Examples.HomeCurrentValueElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeNextStepElement` as `text`

This is small, but it matters. It proves that the same screen can mix static
structure with bound runtime state in several places, not just in one headline.

## Bind The Dynamic Values

Once the widget tree exists, connect it to runtime data with bindings.

The main bound widgets are:

- `HomeSummaryTextElement` binds `hero_summary`
- `HomeStatusLabelElement` binds `status`
- `HomeServicesValueElement` binds `services_count`
- `HomeIncidentsValueElement` binds `incidents_count`
- `HomeOnCallValueElement` binds `on_call_name`
- `HomeCurrentValueElement` binds `current_value`
- `HomeNextStepElement` binds `next_step`

Each binding targets the widget `content` prop. That makes the data flow easy
to understand:

1. `AshUITutorials.ProjectShell.Runtime.WorkspaceState` owns the value
2. the element resource declares the binding
3. hydration fills in the rendered widget props

## Add The First Real Action

The first mutation path belongs to
`AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement`.

That button listens to `click` and updates the `WorkspaceState` record with new
values for:

- `status`
- `current_value`
- `next_step`

This is an intentionally simple action, but it proves the most important idea
in the chapter: the UI is not seeded once and frozen. It is connected to a real
resource-backed state change.

## Persist The Screen Through Authority

After defining the runtime state and the screen graph, `seed!/1` in
`AshUITutorials.ProjectShell` creates the real authored screen.

It works in the same order you should think about the architecture:

1. clear old runtime and UI storage records
2. create one `WorkspaceState` record
3. call `Authority.create(...)` for `AshUITutorials.ProjectShell.Examples.HomeScreen`
4. return the seeded screen name and storage contract

This is the heart of the chapter. The dashboard exists because authority
persists the screen graph into `UiScreen`, `UiElement`, and `UiBinding`.

## Mount The Screen In LiveView

With a persisted screen in place, the host can stay small.

`AshUITutorials.ProjectShell.Web.HomeLive` does not define the dashboard by
hand. Instead it:

1. seeds the checkpoint app
2. assigns the current user, storage contract, runtime domains, and theme
3. calls `AshUI.LiveView.Integration.mount_ui_screen/3`
4. wires Ash UI event handlers
5. renders the selected runtime preview inside the tutorial shell

That shell comes from `TutorialShell.tutorial_shell/1`, which injects the local
Ash HQ-inspired styling from
[`assets/css/app.css`](../code/01-project-shell/assets/css/app.css).

The key architectural line is:

- LiveView hosts the experience
- authoritative screen resources define the experience

## Modules And Resources You Will Touch

To keep the checkpoint easy to explore, Chapter 1 centralizes the important
pieces in one file and one host app:

- main checkpoint module: `AshUITutorials.ProjectShell`
- runtime state resource: `AshUITutorials.ProjectShell.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.ProjectShell.UiScreen`, `AshUITutorials.ProjectShell.UiElement`, `AshUITutorials.ProjectShell.UiBinding`
- authoritative screen builder: `AshUITutorials.ProjectShell.Examples.HomeScreen`
- LiveView host: `AshUITutorials.ProjectShell.Web.HomeLive`

## Run The Checkpoint

From [`tutorials/code/01-project-shell/`](../code/01-project-shell/):

```bash
mix deps.get
mix example.start
```

`mix example.start` is the default path. It starts the `live_ui` renderer and
shows the result through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

If you want to compare the same authoritative screen in another runtime, pass
the runtime name as the first argument:

```bash
mix example.start live_ui
mix example.start elm_ui
mix example.start desktop_ui
```

All three runtime previews come from the same authored screen and binding
graph. The default tutorial path stays focused on `live_ui`, because LiveView
is the easiest place to see the event flow in the early chapters.

## What To Carry Into Chapter 2

If Chapter 1 landed well, you should now have these ideas firmly in place:

1. start with runtime state and screen structure, not host templates
2. place widgets through screen and element resources instead of direct markup
3. keep bindings and actions close to the element resources that own them
4. let LiveView mount and host the screen rather than reconstructing it

Chapter 2 keeps the same shell, but it gives that shell something more
interesting to do: separate services and incidents workspaces that still share
one runtime state record.
