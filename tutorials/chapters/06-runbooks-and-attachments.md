# Chapter 6 - Runbooks and Attachments

## Code For This Chapter

Checkpoint app: `tutorials/code/06-runbooks-and-attachments/`

Previous checkpoint: `tutorials/code/05-safe-overlays-and-guards/`

Supporting examples: `examples/file_input`, `examples/image`, `examples/link`, `examples/markdown_viewer`

By Chapter 5, the incidents workspace can filter, submit workflows, and guard
sensitive actions. Chapter 6 adds the next thing a real operator console needs:
guidance and evidence.

The checkpoint app at
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/)
keeps building directly on
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/)
and extends the incidents workspace with a resource-authored runbook review
lane and a deliberately narrow attachment review surface.

## What You Are Building

By the end of Chapter 6, the incidents workspace can:

1. switch between two authored runbook stories
2. render the active guide through a markdown viewer surface
3. keep guide review and evidence review visible side by side
4. capture a filename-only evidence selection
5. show an external reference link and a durable image preview

This chapter is also where the tutorial gets very explicit about support limits.
The widgets can express rich review surfaces, but the code should never pretend
to implement a full file-upload pipeline when it does not.

## Start With Shared Runbook State

The central runtime resource is:

- `AshUITutorials.RunbooksAndAttachments.Runtime.WorkspaceState`

Important new fields include:

- `runbook_focus`
- `runbook_markdown`
- `runbook_status`
- `attachment_filename`
- `attachment_support_notice`

Those values belong in the runtime record because the active guide, current
evidence filename, and support notice are part of the operator’s working state.

The chapter intentionally keeps attachment handling narrow. The file input only
echoes the selected filename. That is not a weakness in the writing. It is an
honest statement about what this checkpoint actually implements.

## Keep The Screen Structure Stable

Chapter 6 still persists:

- `AshUITutorials.RunbooksAndAttachments.UiScreen`
- `AshUITutorials.RunbooksAndAttachments.UiElement`
- `AshUITutorials.RunbooksAndAttachments.UiBinding`

And it still keeps the explicit screen roots:

- `AshUITutorials.RunbooksAndAttachments.Examples.ServicesScreen`
- `AshUITutorials.RunbooksAndAttachments.Examples.IncidentsScreen`

The new behavior is concentrated in one incidents-side panel, which means the
tutorial can grow without losing the structure you already learned.

## The Widget Plan For This Chapter

Chapter 6 adds the first documentation-and-artifact review lane:

| Widget | Where it goes | Why it belongs there |
|---|---|---|
| `custom:split_pane` | Runbook review shell | Keeps guide review and artifact review visible together |
| `custom:markdown_viewer` | Primary guide surface | Best fit for authored runbook text |
| `input` with `type="file"` | Evidence filename control | Demonstrates attachment selection without overclaiming upload support |
| `custom:link` | Reference action | Gives the operator one explicit external reference |
| `image` | Evidence preview | Adds a durable visual artifact surface |
| `button` | Runbook selectors | Lets the operator switch between authored guide stories |
| `card` and `text` | Evidence panel and support notices | Keep attachment context readable |

The big idea is that runbooks and attachments should feel like part of the same
incident workspace, not like a side quest.

## Build The Runbook Review Panel

The new panel is:

- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookReviewPanelElement`

It contains:

- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookSplitPaneElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookStatusTextElement`

This structure works well because the split pane does the heavy visual layout
work while the footer keeps the current review status explicit.

## Use A Split Pane To Separate Guide And Evidence

The main authored shell is:

- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookSplitPaneElement`

It divides the review surface into:

- a `primary` side for guide reading
- a `secondary` side for evidence review
- an `actions` slot for runbook switching

Its key children are:

- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookFocusTitleElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentEvidenceCardElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.LoadGatewayRunbookButtonElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.LoadRollbackRunbookButtonElement`

This is exactly the kind of layout a tutorial application should show. Operators
rarely read guidance without also checking supporting artifacts.

## Build The Guide Side

The guide side is intentionally simple:

- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookFocusTitleElement` shows the current guide focus
- `AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement` renders the active markdown

Those widgets bind directly to:

- `runbook_focus`
- `runbook_markdown`

That keeps the runbook lane honest and easy to understand. The guide you see is
not hidden inside the host or loaded through an untracked side channel. It is
just runtime-backed state flowing into authored widgets.

## Build The Evidence Side

The evidence card is:

- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentEvidenceCardElement`

It contains:

- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentPreviewTextElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileFieldElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentReferenceLinkElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentImageElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentSupportTextElement`

The file field then wraps:

- `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileInputElement`

This split is helpful because the evidence lane now has three different jobs:

1. show the current filename
2. accept a new filename selection
3. explain the support boundary clearly

That last point is important. A tutorial is better when it says exactly what is
implemented instead of implying more than the code does.

## Use Buttons To Swap Coherent Runbook Stories

The two authored selectors are:

- `AshUITutorials.RunbooksAndAttachments.Examples.LoadGatewayRunbookButtonElement`
- `AshUITutorials.RunbooksAndAttachments.Examples.LoadRollbackRunbookButtonElement`

Each button updates a whole runbook context at once:

- guide title
- markdown body
- evidence filename
- support notice
- shared detail card state
- status text

That is a strong design choice. The operator is not changing isolated fragments.
They are loading one coherent review story.

## Keep The Incidents Workspace Layered

By this point, the incidents screen contains:

1. filters
2. the incidents table
3. operator forms
4. guarded actions
5. the runbook and evidence review lane

That sounds like a lot, but the authored panels keep each concern in its own
place. The tutorial is showing that a resource-authored screen can grow in
capability without collapsing into chaos.

The services screen remains available and stable, but the incidents screen is
now clearly the deeper operational workspace.

## Persist And Mount The Runbook-Enabled Screens

The persistence flow is still the same:

- `AshUITutorials.RunbooksAndAttachments.seed!/1` creates the runtime record
- authority persists `AshUITutorials.RunbooksAndAttachments.Examples.ServicesScreen`
- authority persists `AshUITutorials.RunbooksAndAttachments.Examples.IncidentsScreen`

The hosts remain:

- `AshUITutorials.RunbooksAndAttachments.Web.ServicesLive`
- `AshUITutorials.RunbooksAndAttachments.Web.IncidentsLive`

That continuity matters. The tutorial keeps adding capability, but the core
screen-authority model does not change.

## Modules And Resources You Will Touch

Keep these names visible while working through the checkpoint:

- source file: [`../code/06-runbooks-and-attachments/lib/ash_ui_tutorials/runbooks_and_attachments.ex`](../code/06-runbooks-and-attachments/lib/ash_ui_tutorials/runbooks_and_attachments.ex)
- main checkpoint module: `AshUITutorials.RunbooksAndAttachments`
- runtime state resource: `AshUITutorials.RunbooksAndAttachments.Runtime.WorkspaceState`
- persisted UI resources: `AshUITutorials.RunbooksAndAttachments.UiScreen`, `AshUITutorials.RunbooksAndAttachments.UiElement`, `AshUITutorials.RunbooksAndAttachments.UiBinding`
- authoritative screen builders: `AshUITutorials.RunbooksAndAttachments.Examples.ServicesScreen`, `AshUITutorials.RunbooksAndAttachments.Examples.IncidentsScreen`
- runbook and evidence surfaces: `AshUITutorials.RunbooksAndAttachments.Examples.RunbookReviewPanelElement`, `AshUITutorials.RunbooksAndAttachments.Examples.RunbookSplitPaneElement`, `AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement`, `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentEvidenceCardElement`
- attachment resources: `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileFieldElement`, `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileInputElement`, `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentReferenceLinkElement`, `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentImageElement`
- runbook selectors: `AshUITutorials.RunbooksAndAttachments.Examples.LoadGatewayRunbookButtonElement`, `AshUITutorials.RunbooksAndAttachments.Examples.LoadRollbackRunbookButtonElement`
- LiveView hosts: `AshUITutorials.RunbooksAndAttachments.Web.ServicesLive`, `AshUITutorials.RunbooksAndAttachments.Web.IncidentsLive`

## Run The Checkpoint

From
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`.

Use:

- `/` for the services workspace
- `/incidents` for the incidents workspace with the runbook review lane

Alternate runtime previews remain available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

They all use the same authored screens and the same runtime-backed runbook
story.

## What To Carry Into Chapter 7

Chapter 6 proves that operator guidance and evidence review can live inside the
same persisted state model as filters, workflows, and guard rails.

Chapter 7 builds directly on that incidents workspace by adding the first
live-shaped diagnostics surfaces, while staying explicit about transport and
freshness limits.
