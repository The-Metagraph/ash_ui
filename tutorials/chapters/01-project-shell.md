# Chapter 1 - Project Shell

## Code For This Chapter

Checkpoint app: `tutorials/code/01-project-shell/`

Previous checkpoint: none.

Supporting examples: `examples/button`, `examples/box`, `examples/grid`, `examples/text`

This chapter builds the first real screen for the tutorial application: a small
home dashboard for the Operations Control Center. The goal is not just to make
something that looks nice. The real goal is to set the architectural pattern
that every later chapter will reuse:

- runtime data lives in Ash resources
- UI storage lives in persisted `UiScreen`, `UiElement`, and `UiBinding` resources
- the visible screen is authored through resource modules, not handwritten host markup
- Phoenix LiveView is the host, not the source of truth for the dashboard structure

By the end of the chapter, the checkpoint app at
[`tutorials/code/01-project-shell/`](../code/01-project-shell/) serves one
authoritative screen, `tutorial/project-shell/home`, inside a themed shell that
matches the Ash HQ visual baseline.

## What You Are Building

The final Chapter 1 screen has four jobs:

1. introduce the tutorial application with a recognizable shell
2. prove that a dashboard can be composed from persisted screen and element resources
3. show a few seeded operational facts such as service count and current on-call owner
4. demonstrate one real interaction, where a button updates runtime state and the UI rehydrates from bindings

The finished screen is small on purpose, but it is already structured like a
real app. The reader should come away understanding that this tutorial is not
about sprinkling widgets into templates. It is about building screens through
Ash UI's resource-authority model.

## Start With The Final Architecture

Before you place any widgets, it helps to understand the four layers in the
checkpoint app:

1. The checkpoint module, [`AshUITutorials.ProjectShell`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex), is the orchestration entry point. It defines the seed data, storage contract, runtime helpers, and renderer helpers.
2. The runtime state resource, `AshUITutorials.ProjectShell.Runtime.WorkspaceState`, holds the values that the home dashboard reads and updates.
3. The persisted UI resources, `AshUITutorials.ProjectShell.UiScreen`, `AshUITutorials.ProjectShell.UiElement`, and `AshUITutorials.ProjectShell.UiBinding`, store the authored screen graph and the binding definitions.
4. The LiveView host, `AshUITutorials.ProjectShell.Web.HomeLive`, mounts the persisted screen and renders the chosen runtime output inside the themed shell.

If you want one file to read from top to bottom while following this chapter,
use:

- [`../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex)

That file contains the runtime resource, UI storage resources, screen and
element definitions, and the LiveView host in one place so the Chapter 1 story
is easy to follow.

## The Widget Plan For This Chapter

Chapter 1 uses a deliberately small but useful widget set:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `card` | Root hero panel and each summary stat tile | Gives the home dashboard a clear panel structure without introducing complex navigation yet |
| `column` | Main header stack | Lets the hero content read top-to-bottom: kicker, title, summary, status, divider |
| `row` | Title row, action row, footer row | Groups small related items horizontally |
| `text` | Kicker, title, summary, stat labels, stat values, story copy, signal copy, footer copy | Handles almost all chapter copy and keeps the first screen readable |
| `icon` | Title row and footer row | Adds visual anchors without pulling in heavier media widgets |
| `label` | Status pill in the hero header | Distinguishes the runtime status from ordinary copy |
| `divider` | End of the hero header block | Separates the introduction from the first actionable controls |
| `button` | Review acknowledgement action | Gives the chapter one real mutation path |
| `custom:link` | Secondary Ash HQ reference action | Shows that a dashboard can mix local actions with navigation or external references |
| `spacer` | Action row | Creates breathing room in a tight horizontal action cluster |
| `grid` | Three summary cards | Establishes the dashboard pattern that later chapters expand into full workspaces |

This is the first important design decision of the tutorial: use simple widgets
to prove the architecture first. We are not trying to show every widget in
Chapter 1. We are trying to show how widgets fit into the application's screen
graph.

## Build The Runtime Story First

Start by defining the values that the UI will read. In
[`project_shell.ex`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex),
the `seed_state/0` function produces the initial runtime record:

- `status`
- `current_value`
- `hero_summary`
- `next_step`
- `services_count`
- `incidents_count`
- `on_call_name`

Those values belong in `AshUITutorials.ProjectShell.Runtime.WorkspaceState`
because they represent application state, not presentation structure. That
separation matters. The screen graph answers "what should exist on screen?".
The runtime resource answers "what values should the screen show right now?".

This chapter also seeds believable operator data from the shared Phase 23
fixtures. That is why the service and incident counts already look real even
though the app only has one screen at this point.

## Create The Persisted UI Storage Boundary

Once runtime state exists, define the storage boundary that will hold the
screen graph itself:

- `AshUITutorials.ProjectShell.UiScreen`
- `AshUITutorials.ProjectShell.UiElement`
- `AshUITutorials.ProjectShell.UiBinding`

These resources are the persistence layer for the authored UI. They are the
reason you can say, truthfully, that the Chapter 1 dashboard is not hardcoded
inside `render/1`.

The helper `ui_storage/0` in
[`AshUITutorials.ProjectShell`](../code/01-project-shell/lib/ash_ui_tutorials/project_shell.ex)
packages those resources into the storage contract that
`AshUI.Resource.Authority.create/1` and
`AshUI.LiveView.Integration.mount_ui_screen/3` will use later.

## Author The Screen Root

Now build the first actual screen resource:

- `AshUITutorials.ProjectShell.Examples.HomeScreen`

This module is the root of the Chapter 1 dashboard. It does three important
things:

1. sets `layout(:column)` so the whole screen flows vertically
2. sets `route("/")` so the checkpoint app opens directly on the dashboard
3. declares child relationships for the major surfaces on the page

The screen-level relationships are:

- `home_panels`
- `story_texts`
- `signal_texts`

That gives the screen a simple shape:

1. the main dashboard panel
2. one explanation block describing the interaction story
3. one explanation block describing the signal flow

This is a good early tutorial pattern because it keeps the main demo visible
while also teaching the reader what the demo is proving.

## Build The Main Dashboard Panel

The main surface is `AshUITutorials.ProjectShell.Examples.HomePanelElement`.
This is a `card`, and it is the parent container for the entire visible
dashboard experience.

Its child relationships are the first place where the tutorial starts to feel
like application architecture instead of loose widget placement:

- `header_columns`
- `action_rows`
- `summary_grids`
- `footer_rows`

That relationship list tells the story of the screen immediately:

1. explain the screen
2. offer an action
3. show key numbers
4. show the current workflow state

### Header Composition

The header is built with `AshUITutorials.ProjectShell.Examples.HomeHeaderColumnElement`,
which is a `column`. Use a `column` here because the reader needs to scan the
content top-to-bottom, like a dashboard hero block.

Inside that column, place:

- `AshUITutorials.ProjectShell.Examples.HomeKickerTextElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeTitleRowElement` as `row`
- `AshUITutorials.ProjectShell.Examples.HomeSummaryTextElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeStatusLabelElement` as `label`
- `AshUITutorials.ProjectShell.Examples.HomeDividerElement` as `divider`

The title row is its own `row` because the icon and title belong together:

- `AshUITutorials.ProjectShell.Examples.HomeTitleIconElement` as `icon`
- `AshUITutorials.ProjectShell.Examples.HomeTitleTextElement` as `text`

This is the first good example of widget placement following meaning instead of
styling. The icon does not sit at the screen root. It belongs specifically in
the title row because it is part of the title unit.

### Action Composition

After the header, add `AshUITutorials.ProjectShell.Examples.HomeActionRowElement`
as a `row`. This row carries the first operator controls:

- `AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement` as `button`
- `AshUITutorials.ProjectShell.Examples.HomeDocsLinkElement` as `custom:link`
- `AshUITutorials.ProjectShell.Examples.HomeActionSpacerElement` as `spacer`

Use a `button` here because the user is changing application state. Use the
link because the user is navigating to reference material. That distinction is
worth keeping clear from the very first chapter.

### Summary Grid Composition

The summary numbers live in
`AshUITutorials.ProjectShell.Examples.HomeSummaryGridElement`, which is a
`grid` with three cards:

- `AshUITutorials.ProjectShell.Examples.HomeServicesCardElement`
- `AshUITutorials.ProjectShell.Examples.HomeIncidentsCardElement`
- `AshUITutorials.ProjectShell.Examples.HomeOnCallCardElement`

Each card contains two `text` widgets:

- one label widget for what the number means
- one value widget for the current seeded runtime value

This is a great Chapter 1 pattern because it introduces a dashboard layout
without adding tables, lists, or tabs too early. The reader can focus on
composition first.

### Footer Composition

The last child of the panel is
`AshUITutorials.ProjectShell.Examples.HomeFooterRowElement`, another `row`.
It carries the "where are we now?" status strip:

- `AshUITutorials.ProjectShell.Examples.HomeSignalIconElement` as `icon`
- `AshUITutorials.ProjectShell.Examples.HomeCurrentValueElement` as `text`
- `AshUITutorials.ProjectShell.Examples.HomeNextStepElement` as `text`

This footer is small, but architecturally it matters. It proves that the same
screen can mix static structure with bound runtime values in several places,
not just in one headline.

## Bind The Dynamic Values

Once the widget tree is in place, connect it to runtime data with bindings.
That is where `AshUITutorials.ProjectShell.UiBinding` becomes visible in the
user experience.

The main bound widgets are:

- `HomeSummaryTextElement` binds `hero_summary`
- `HomeStatusLabelElement` binds `status`
- `HomeServicesValueElement` binds `services_count`
- `HomeIncidentsValueElement` binds `incidents_count`
- `HomeOnCallValueElement` binds `on_call_name`
- `HomeCurrentValueElement` binds `current_value`
- `HomeNextStepElement` binds `next_step`

Every one of those bindings targets the widget `content` prop. That is an easy
starting pattern for the first chapter because readers can see the data flow
clearly:

1. the runtime resource owns the value
2. the element resource declares a binding
3. the renderer hydrates the final widget props

## Add The First Real Action

The first mutation path belongs to
`AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement`.

This button matters because it proves the chapter's central promise: the UI is
not just seeded once and frozen. It is connected to application state.

The button action listens to the `click` signal and updates the
`WorkspaceState` record with new values for:

- `status`
- `current_value`
- `next_step`

That choice is intentional. The button does not just flip a cosmetic flag. It
updates the values that tell the reader what stage the tutorial is in and what
comes next. This keeps the first interaction meaningful and easy to reason
about.

## Persist The Screen Through Authority

After defining the runtime state and the screen graph, use `seed!/1` in
`AshUITutorials.ProjectShell` to create the real authored screen.

That function does the work in the order readers should understand it:

1. reset previous runtime and UI storage records
2. create one `WorkspaceState` runtime record
3. call `Authority.create(...)` for `AshUITutorials.ProjectShell.Examples.HomeScreen`
4. return the seeded screen name and storage contract

This is the heart of the chapter. The dashboard exists because the authority
module persists an authored screen graph into `UiScreen`, `UiElement`, and
`UiBinding`. That is the architectural step readers need to carry into every
later tutorial chapter.

## Mount The Screen In LiveView

With a persisted screen in place, the host can stay very small.

`AshUITutorials.ProjectShell.Web.HomeLive` does not define the dashboard
structure by hand. Instead it:

1. seeds the checkpoint app
2. assigns the current user, storage contract, domains, and theme
3. calls `AshUI.LiveView.Integration.mount_ui_screen/3`
4. wires Ash UI event handlers
5. renders the selected runtime preview inside the tutorial shell

That host shell is wrapped by `TutorialShell.tutorial_shell/1`, which injects
the local Ash HQ-inspired styling from
[`assets/css/app.css`](../code/01-project-shell/assets/css/app.css).

This is the architectural line to remember:

- LiveView hosts the experience
- authoritative screen resources define the experience

## Why These Widgets Belong In Chapter 1

This chapter is doing more teaching than it may look like at first glance.

- `text` and `label` teach content and status surfaces
- `row`, `column`, and `grid` teach layout composition
- `card` teaches grouped dashboard surfaces
- `button` teaches mutation
- `icon`, `divider`, `spacer`, and `custom:link` teach supporting structure without overwhelming the chapter

That mix is enough to make the screen feel like a real application shell, while
still keeping the reader focused on the resource-authority architecture.

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

The important part is that all three runtime previews come from the same
authored screen and binding graph. The default tutorial path stays focused on
`live_ui`, because LiveView is the easiest place to see the event flow in early
chapters.

## What To Carry Into Chapter 2

If Chapter 1 landed well, the reader should now understand these ideas:

1. start with runtime state and screen structure, not with host templates
2. use screen and element resources to place widgets into a meaningful hierarchy
3. keep bindings and actions close to the element resources that own them
4. let LiveView mount and host the screen instead of manually recreating it

Chapter 2 will reuse the same structure, but it will turn this single home
dashboard into the first true operator workspace with separate services and
incidents screens.
