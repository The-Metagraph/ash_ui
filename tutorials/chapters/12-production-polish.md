# Chapter 12 - Production Polish

## Code For This Chapter

Checkpoint app: `tutorials/code/12-production-polish/`

Previous checkpoint: `tutorials/code/11-roles-and-policies/`

Supporting examples: `examples/box`, `examples/grid`, `examples/inline_feedback`, `examples/toast`

This chapter builds directly on [`tutorials/code/11-roles-and-policies/`](../code/11-roles-and-policies/). Up to now, the Operations Control Center already had real workflows, overlays, diagnostics, topology, metrics, runtime introspection, and actor-aware policy checks. What it still needed was the final product pass: the part where you make the app easier to review, easier to navigate, and more honest when the current surface is loading, empty, or blocked.

The finished checkpoint lives in [`tutorials/code/12-production-polish/`](../code/12-production-polish/), and the main implementation is in [`../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex`](../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex).

## What You Are Building

Chapter 12 is not about inventing a new feature area. It is about making the
whole tutorial application feel finished.

By the end of the chapter, the checkpoint app does four new things well:

1. it keeps `live_ui` as the default host while still making alternate runtime previews easy to review
2. it makes keyboard navigation and focus movement visible in the shell instead of treating them like hidden implementation details
3. it teaches explicit ready, loading, empty, and support-error states on the same authored services and incidents screens
4. it closes the gap between the last chapter checkpoint and the maintained final app at [`tutorials/operations_control_center/`](../operations_control_center/)

That last point matters. A tutorial series should not end with a checkpoint app
that looks finished while the maintained reference app drifts somewhere else.

## Modules and Resources You Will Touch

Start with these modules in [`../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex`](../code/12-production-polish/lib/ash_ui_tutorials/production_polish.ex):

- `AshUITutorials.ProductionPolish`
- `AshUITutorials.ProductionPolish.Runtime.WorkspaceState`
- `AshUITutorials.ProductionPolish.Web.Components.TutorialShell`
- `AshUITutorials.ProductionPolish.Examples.ServicesProductionPolishPanelElement`
- `AshUITutorials.ProductionPolish.Examples.IncidentsProductionPolishPanelElement`
- `AshUITutorials.ProductionPolish.Examples.ReviewStateStatusElement`
- `AshUITutorials.ProductionPolish.Examples.ReviewStateInlineFeedbackElement`
- `AshUITutorials.ProductionPolish.Examples.ProductionPolishGuidanceTextElement`
- `AshUITutorials.ProductionPolish.Examples.ShowServicesReadyStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowServicesLoadingStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowServicesEmptyStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowServicesErrorStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowIncidentsReadyStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowIncidentsLoadingStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowIncidentsEmptyStateButtonElement`
- `AshUITutorials.ProductionPolish.Examples.ShowIncidentsErrorStateButtonElement`

You will also update the local theme file:

- [`../code/12-production-polish/assets/css/app.css`](../code/12-production-polish/assets/css/app.css)

## Step 1: Polish The Shell Before You Touch The Workspace

Begin in `AshUITutorials.ProductionPolish.Web.Components.TutorialShell`.

The important change in this chapter is that the shell stops behaving like a
bare wrapper and starts behaving like a real product surface:

- add a skip link that jumps directly to the mounted workspace
- keep the main page navigation obvious and keyboard reachable
- keep the actor switcher in the header so the permission-aware story stays visible
- add one short shell note that tells readers `live_ui` is still the default runtime and alternate previews are optional, not the main path

This is a good point to be strict with yourself. If a reader cannot tell where
to start, or cannot tell which runtime is the normal one, the tutorial still
is not finished.

## Step 2: Make Runtime Preview Switching Friendly

Stay in the shell for a moment longer.

Chapter 11 already supported `live_ui`, `elm_ui`, and `desktop_ui`, but the
polish pass makes that support more obvious:

- keep `mix example.start` focused on the default `live_ui` host
- add runtime preview links inside the running shell so readers can switch without memorizing query strings
- keep the command examples visible because they still matter for direct review from the terminal

The goal is honesty. `live_ui` is the main teaching path. The alternate
runtimes are still useful, but they should read like alternate previews, not
like three equal-startup modes that the tutorial expects readers to juggle.

## Step 3: Add One Shared Review-State Model

Now move into `AshUITutorials.ProductionPolish.Runtime.WorkspaceState`.

Add the Chapter 12 state that explains whether the current workspace is in a:

- ready state
- loading state
- empty state
- support-error state

In the checkpoint code, that work lives in:

- the new `experience_mode` attribute
- the derived `review_status_model`
- the derived `review_feedback_model`
- the `apply_experience_mode/4` helper that adjusts the visible services and incidents rows plus the shared detail card copy

This is one of the most important architectural choices in the whole tutorial.
The loading and error stories are still expressed through the same runtime
resource that already drives the happy path. We are not adding a parallel host
state machine just for polish.

## Step 4: Teach The Services Workspace How To Be Empty Or Busy

Next, wire the new polish surface into the services screen.

The parent container is:

- `AshUITutorials.ProductionPolish.Examples.ServicesProductionPolishPanelElement`

Place it inside:

- `AshUITutorials.ProductionPolish.Examples.ServicesWorkspacePanelElement`

This panel belongs in the services workspace because that is the first place
where readers see the app-wide shell, filters, service list, topology review,
metrics review, and runtime review together. It is the right place to teach
how a real operational screen behaves when it is healthy, refreshing, empty,
or blocked.

Inside the panel, use:

- `button` elements for the four state switches
- `custom:status` for the current review-state summary
- `custom:inline_feedback` for the explanatory copy
- `text` for the accessibility and contrast reminder

That widget mix is deliberate. A polish panel should not feel like a control
dump. It should let the reader trigger a state, then immediately explain what
that state means.

## Step 5: Repeat The Same Pattern For The Incidents Workspace

Now apply the same idea to incidents.

The incident side uses:

- `AshUITutorials.ProductionPolish.Examples.IncidentsProductionPolishPanelElement`

with the four incident-specific state buttons:

- `ShowIncidentsReadyStateButtonElement`
- `ShowIncidentsLoadingStateButtonElement`
- `ShowIncidentsEmptyStateButtonElement`
- `ShowIncidentsErrorStateButtonElement`

This is where the chapter becomes useful instead of decorative. The incidents
screen already carries the most complicated teaching surface in the whole app:
filters, forms, guarded actions, runbook review, diagnostics, and actor-aware
policy differences. If that screen still reads clearly when it is loading,
empty, or blocked, the rest of the application usually will too.

## Step 6: Tighten The CSS For Focus, Mobile Layout, and Reduced Motion

With the resource graph in place, update
[`../code/12-production-polish/assets/css/app.css`](../code/12-production-polish/assets/css/app.css).

The goal here is not to redesign the Ash HQ theme. It is to finish it:

- add a visible `:focus-visible` treatment
- style the skip link so it becomes useful when focused
- let runtime links, nav links, and primary actions wrap cleanly on smaller screens
- make the major call-to-action controls full width on mobile
- keep `prefers-reduced-motion` honest by disabling ornamental motion

This is also the right moment to look at contrast. The tutorial already uses
the dark-slate shell and warm orange-red accents from the Ash HQ baseline. The
polish pass is where you confirm that the softer supporting copy still reads
cleanly against the glass panels.

## Step 7: Sync The Story Text With The Real Product Goal

After the shell and the panels are done, update the screen-level explanation
copy.

The `Meaningful Interaction Story` and `Canonical Signal Preview` text blocks
for both services and incidents should now mention the Chapter 12 goal
explicitly:

- the shell is still resource-authored
- the actor-aware policy behavior still matters
- the final checkpoint now teaches how those same screens behave when the
  current view is ready, loading, empty, or blocked

That keeps the tutorial honest. The prose should explain the exact screen the
reader is looking at, not the screen from one chapter earlier.

## What to Look For in the Finished Checkpoint

When Chapter 12 is working, the app at
[`tutorials/code/12-production-polish/`](../code/12-production-polish/) should
feel finished in a very specific way:

- `mix example.start` opens the default `live_ui` host without extra arguments
- the running shell offers clear runtime links for `live_ui`, `elm_ui`, and `desktop_ui`
- keyboard users can reach the skip link, the page nav, the actor switcher, the runtime links, and the new production-polish buttons in a predictable order
- the services screen can switch cleanly between ready, loading, empty, and support-error review states
- the incidents screen can do the same without losing the actor-aware workflow and guard story
- the maintained final app at [`tutorials/operations_control_center/`](../operations_control_center/) can now be aligned closely with this checkpoint instead of lagging behind it

That is the real finish line for the tutorial body: not one more widget, but a
coherent product surface that is pleasant to review and honest under strain.
