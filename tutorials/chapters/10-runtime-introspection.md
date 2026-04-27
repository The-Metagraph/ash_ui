# Chapter 10 - Runtime Introspection

## Code For This Chapter

Checkpoint app: `tutorials/code/10-runtime-introspection/`

Previous checkpoint: `tutorials/code/09-metrics-and-capacity/`

Supporting examples: `examples/command_palette`, `examples/supervision_tree_viewer`, `examples/table`, `examples/tabs`

This chapter builds directly on [`tutorials/code/09-metrics-and-capacity/`](../code/09-metrics-and-capacity/). The goal is to keep the Operations Control Center believable once the high-level dashboards stop being enough. By the end of the chapter, the services workspace can still do filtering, topology review, and metrics review, but it also adds a real runtime-introspection lane with one command palette, one set of runtime tabs, one `supervision_tree_viewer`, and one process table that all read from the same persisted workspace state.

The finished checkpoint lives in [`tutorials/code/10-runtime-introspection/`](../code/10-runtime-introspection/), and the main implementation is in [`../code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex`](../code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex).

## What You Are Building

The Chapter 9 app already gave us the broad operational picture. Chapter 10 adds the moment where an operator asks, “What is the runtime actually doing right now?” We answer that with a new runtime review panel on the services screen.

That panel has five jobs:

1. Let the operator choose a runtime story quickly with a command palette.
2. Keep the active runtime lane visible with tabs.
3. Show the supervisor hierarchy with `custom:supervision_tree_viewer`.
4. Show the current process rows in a `table`.
5. Keep the support copy honest about what is real, sampled, and tutorial-seeded.

The important architectural point is that we are still not dropping down into host-only UI state. The runtime review surface is fed by `AshUITutorials.RuntimeIntrospection.Runtime.WorkspaceState`, and the rendered screen still comes from authored screen and element resources, not from a hand-written LiveView template.

## Modules and Resources You Will Touch

The checkpoint keeps the same “one file, many modules” pattern as the earlier tutorial chapters. The main source file defines both the runnable app and the resource graph behind it.

Start with these modules:

- `AshUITutorials.RuntimeIntrospection`
- `AshUITutorials.RuntimeIntrospection.Runtime.WorkspaceState`
- `AshUITutorials.RuntimeIntrospection.UiScreen`
- `AshUITutorials.RuntimeIntrospection.UiElement`
- `AshUITutorials.RuntimeIntrospection.UiBinding`
- `AshUITutorials.RuntimeIntrospection.Examples.ServicesScreen`
- `AshUITutorials.RuntimeIntrospection.Examples.IncidentsScreen`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeReviewPanelElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandPaletteElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeTabsElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupervisionTreeViewerElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeProcessTableElement`
- `AshUITutorials.RuntimeIntrospection.Web.ServicesLive`
- `AshUITutorials.RuntimeIntrospection.Web.IncidentsLive`

Those are all defined in [`../code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex`](../code/10-runtime-introspection/lib/ash_ui_tutorials/runtime_introspection.ex).

## Step 1: Extend the Persisted Workspace State

The first thing to add is more state, not more widgets. The new runtime panel only works if one record can describe the active runtime story in the same way that earlier chapters described filters, runbook focus, diagnostics, topology, and metrics.

In `AshUITutorials.RuntimeIntrospection.Runtime.WorkspaceState`, add fields for:

- the current runtime focus
- the current runtime query
- the supervision tree model
- the full process catalog
- the filtered process rows
- the runtime command summary
- the runtime support title and support notice
- the runtime status copy

The three seeded runtime scenarios in this chapter are:

- gateway supervisor review
- search recovery supervision
- rollback coordination

Each scenario is represented as one helper that returns a map of authored state. The chapter code keeps those helpers explicit so the tutorial can say, in plain language, which parts are sampled and why.

That is why the runtime lane uses functions like the seeded gateway, search, and recovery runtime contexts instead of pretending there is an invisible BEAM inspector hidden behind the UI.

## Step 2: Keep Runtime Filtering in Hydration

Once the new fields exist, update `AshUITutorials.RuntimeIntrospection.hydrate_state/1`.

This chapter follows the same pattern as the earlier ones:

- normalize incoming keys
- merge defaults from the seeded contexts
- derive visible collections
- derive summary copy

For runtime review, the derived collection is the process table. The code filters `runtime_process_catalog` into `runtime_process_rows` using the persisted `runtime_query`. That keeps the command-palette search honest: typing into the runtime query field changes the persisted state, and hydration recomputes the visible rows.

This is the same architectural move we used earlier for the services list and incidents table. The chapter is deliberately teaching repetition here: resource-backed state changes are still the center of the app, even when the UI is about runtime supervision.

## Step 3: Add the Runtime Review Panel to the Services Screen

The new runtime surfaces belong on the services screen, not the incidents screen.

That choice matters. Chapter 10 is about deepening the services workspace after topology and metrics have already made it broad. We are saying: when the service is still in trouble, this is where the operator drills into supervisor lanes and process rows.

To do that, wire `AshUITutorials.RuntimeIntrospection.Examples.ServicesWorkspacePanelElement` to include one more child relationship:

- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeReviewPanelElement`

Place it after the metrics panel. The services workspace now flows like this:

1. workspace navigation
2. command palette
3. filters and services list
4. topology review
5. metrics review
6. runtime introspection
7. shared detail card

That ordering is intentional. Readers should see runtime introspection as the deeper layer of the same story, not as a detached widget demo.

## Step 4: Build the Runtime Command Palette

Inside `AshUITutorials.RuntimeIntrospection.Examples.RuntimeReviewPanelElement`, start with a `custom:command_palette`.

Use `AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandPaletteElement` for the shell, then add:

- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandSearchInputElement`
- `AshUITutorials.RuntimeIntrospection.Examples.FocusGatewayRuntimeButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.FocusSearchRuntimeButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.FocusRecoveryRuntimeButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeCommandSummaryTextElement`

The command palette has a simple teaching role:

- the search input writes `runtime_query`
- the buttons switch the runtime story
- the summary text proves the persisted state changed

Each button is authored as a normal action binding that targets `WorkspaceState.update`. That keeps the runtime lane aligned with the rest of the tutorial. We are still not mutating assigns directly in LiveView.

## Step 5: Add Runtime Tabs

Next, add `AshUITutorials.RuntimeIntrospection.Examples.RuntimeTabsElement`.

This is not duplicate navigation for its own sake. The command palette is the “jump me there” surface. The tabs are the “keep the three lanes visible while I compare them” surface.

The runtime tabs own:

- `AshUITutorials.RuntimeIntrospection.Examples.ShowGatewayRuntimeTabButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.ShowSearchRuntimeTabButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.ShowRecoveryRuntimeTabButtonElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeTabsStatusTextElement`

They bind to `runtime_focus`, so the current lane is visible in authored UI state, not hidden in component-local memory.

## Step 6: Add the Summary Panel

Before showing the tree itself, add one small summary card:

- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupportPanelElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupportTitleElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupportNoticeElement`

This card is the honesty layer for the tutorial. It tells the reader and the operator whether the current tree is a sampled packet, a seeded snapshot, or a review lane that intentionally stops short of pretending to be a live supervisor tap.

That phrasing is part of the chapter’s teaching goal. Operational UI can easily overclaim. This chapter is meant to show how to stay explicit.

## Step 7: Add the Supervision Tree and Process Table

Now add the two core widgets:

- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeSupervisionTreeViewerElement`
- `AshUITutorials.RuntimeIntrospection.Examples.RuntimeProcessTableElement`

The supervision tree binds the `model` target to the persisted runtime supervision map. The process table binds `items` to the hydrated `runtime_process_rows`.

These two widgets answer complementary questions:

- the tree answers “what is supervising what?”
- the table answers “what do the current rows say about the active components?”

Keeping both in the same authored panel is what makes the chapter useful. A real operator usually wants both structure and row-level detail at the same time.

## Step 8: Keep the LiveView Host Thin

The runnable checkpoint still uses:

- `AshUITutorials.RuntimeIntrospection.Web.ServicesLive`
- `AshUITutorials.RuntimeIntrospection.Web.IncidentsLive`

Those modules should stay thin. Their job is still:

- seed the checkpoint
- assign `current_user`, storage, and runtime domains
- mount the authored screen through `AshUI.LiveView.Integration`
- wire handlers through `AshUI.LiveView.EventHandler`

That separation matters. The LiveView host remains a transport shell. The screen graph and runtime state remain the real authored source of truth.

## What to Look For in the Finished Checkpoint

When Chapter 10 is working, you should be able to open the checkpoint app and see:

- the original services workflow still intact
- topology and metrics still present
- a new runtime review panel on the services page
- a `supervision_tree_viewer` whose nodes change when you change runtime stories
- a process table whose visible rows follow the persisted runtime query
- copy that explicitly says which runtime data is seeded or sampled

That is the full point of the chapter: deeper runtime visibility without abandoning the same resource-first screen architecture the tutorial has used from the start.
