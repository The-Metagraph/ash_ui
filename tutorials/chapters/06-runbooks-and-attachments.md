# Chapter 6 - Runbooks and Attachments

## Code For This Chapter

Checkpoint app: `tutorials/code/06-runbooks-and-attachments/`

Previous checkpoint: `tutorials/code/05-safe-overlays-and-guards/`

Supporting examples: `examples/file_input`, `examples/image`, `examples/link`, `examples/markdown_viewer`

This chapter extends the guarded incident workspace from
[`tutorials/code/05-safe-overlays-and-guards/`](../code/05-safe-overlays-and-guards/)
with the first runbook and artifact-review surfaces.

## What You Build

The checkpoint app at
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/)
keeps the same two authoritative screens from Chapter 5 and extends the
incidents workspace with a persisted runbook-review panel.

That panel uses:

- `custom:split_pane` to keep guide review and artifact review visible at the
  same time
- `custom:markdown_viewer` for the active runbook body
- `input` with `type="file"` for filename-only evidence capture
- `custom:link` for an explicit external reference
- `image` for a durable evidence preview card

The key design constraint in this chapter is honesty: the tutorial can expose a
file input, a markdown surface, and an external reference, but it must say
plainly that upload transport and maintained markdown/link semantics are still
narrower than the visual vocabulary might suggest.

## Modules and Resources Introduced

- Main checkpoint module:
  [`AshUITutorials.RunbooksAndAttachments`](../code/06-runbooks-and-attachments/lib/ash_ui_tutorials/runbooks_and_attachments.ex)
- Runtime state resource:
  `AshUITutorials.RunbooksAndAttachments.Runtime.WorkspaceState`
- Persisted UI resources:
  `AshUITutorials.RunbooksAndAttachments.UiScreen`,
  `AshUITutorials.RunbooksAndAttachments.UiElement`, and
  `AshUITutorials.RunbooksAndAttachments.UiBinding`
- Existing authoritative screen builders:
  `AshUITutorials.RunbooksAndAttachments.Examples.ServicesScreen` and
  `AshUITutorials.RunbooksAndAttachments.Examples.IncidentsScreen`
- New authored runbook surfaces:
  `AshUITutorials.RunbooksAndAttachments.Examples.RunbookReviewPanelElement`,
  `AshUITutorials.RunbooksAndAttachments.Examples.RunbookSplitPaneElement`,
  `AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement`,
  and `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentEvidenceCardElement`
- New authored artifact resources:
  `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileFieldElement`,
  `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileInputElement`,
  `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentReferenceLinkElement`,
  and `AshUITutorials.RunbooksAndAttachments.Examples.AttachmentImageElement`
- New authored runbook selectors:
  `AshUITutorials.RunbooksAndAttachments.Examples.LoadGatewayRunbookButtonElement`
  and
  `AshUITutorials.RunbooksAndAttachments.Examples.LoadRollbackRunbookButtonElement`
- LiveView hosts:
  `AshUITutorials.RunbooksAndAttachments.Web.ServicesLive` and
  `AshUITutorials.RunbooksAndAttachments.Web.IncidentsLive`

The runbook path stays centered on
`AshUITutorials.RunbooksAndAttachments.Runtime.WorkspaceState.update`. The
buttons swap authored markdown, filename-only evidence state, shared detail
copy, and the panel support notice in one resource-backed update instead of
inventing an ad hoc document store in the LiveView host.

## Run The Checkpoint

From
[`tutorials/code/06-runbooks-and-attachments/`](../code/06-runbooks-and-attachments/):

```bash
mix deps.get
mix example.start
```

The default command starts `live_ui` through the Phoenix LiveView host at
`http://127.0.0.1:5000/`. Visit `/` for the services workspace and
`/incidents` for the incidents workspace with the runbook-review panel active.

Alternate runtime previews are still available:

```bash
mix example.start elm_ui
mix example.start desktop_ui
```

Those modes keep the same authoritative screen graph and the same filename-only
attachment contract, so later chapters can add richer diagnostics without
rewriting the Chapter 6 review model.
