# Phase 25 - Tutorial Runbooks, Attachments, and Live Diagnostics

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- `AshUI.Resource.Authority`
- `AshUI.LiveView.Integration`
- data, feedback, and operational examples from `examples/*`

## Relevant Assumptions / Defaults
- Phases 23 and 24 have already established the core dashboard, filters, and
  operator-action flows
- this phase should make the tutorial feel operationally credible by combining
  documents, attachments, and live diagnostic surfaces around the same incident
  stories
- every checkpoint in this phase remains a full standalone app snapshot under
  `tutorials/code/`

[x] 25 Phase 25 - Tutorial Runbooks, Attachments, and Live Diagnostics
  Implement the tutorial milestones that add runbooks, attachments, rich detail
  views, and live diagnostic surfaces to the Operations Control Center app.

  [x] 25.1 Section - Chapter 6 Runbooks, Attachments, and Rich Detail Views
    Add the documentation and attachment workflows operators use while
    responding to incidents.

    [x] 25.1.1 Task - Implement runbook and attachment surfaces
    Teach document-backed guidance and evidence capture inside the same
    resource-first app.

      [x] 25.1.1.1 Subtask - Implement `tutorials/code/06-runbooks-and-attachments/` with incident detail views that incorporate `markdown_viewer`, `file_input`, `link`, and `image` where they support a believable runbook story.
      [x] 25.1.1.2 Subtask - Introduce richer detail composition, including `split_pane`, `content`, and `box` patterns where they improve side-by-side operational review.
      [x] 25.1.1.3 Subtask - Ensure uploaded or referenced artifacts are represented honestly, including any runtime constraints that remain narrower than the UI vocabulary suggests.
      [x] 25.1.1.4 Subtask - Add `tutorials/chapters/06-runbooks-and-attachments.md` with exact references to `tutorials/code/06-runbooks-and-attachments/`.

  [x] 25.2 Section - Chapter 7 Live Monitoring and Streaming Diagnostics
    Add the first truly live operational review surfaces around logs, streams,
    and process-level health.

    [x] 25.2.1 Task - Implement live diagnostics checkpoints
    Teach operational telemetry and runtime review without leaving the tutorial
    application.

      [x] 25.2.1.1 Subtask - Implement `tutorials/code/07-live-diagnostics/` with `log_viewer`, `stream_widget`, and `process_monitor` surfaces tied to seeded service and incident contexts.
      [x] 25.2.1.2 Subtask - Use `inline_feedback`, `status`, and related support surfaces to show stream health, stale data, and transient diagnostic warnings clearly.
      [x] 25.2.1.3 Subtask - Keep the diagnostic chapter explicit about what is real streaming/runtime behavior versus what is seeded or simulated for tutorial clarity.
      [x] 25.2.1.4 Subtask - Add `tutorials/chapters/07-live-diagnostics.md` with exact references to `tutorials/code/07-live-diagnostics/`.

  [x] 25.3 Section - Phase 25 Integration Tests
    Validate the richer detail and live-diagnostics chapters through one
    coherent tutorial path.

    [x] 25.3.1 Task - Runbook and diagnostics scenarios
    Prove the tutorial now covers both operator guidance and live runtime
    observation responsibly.

      [x] 25.3.1.1 Subtask - Verify the Chapter 6 and 7 checkpoint apps boot independently and preserve the tutorial shell and code-reference contract.
      [x] 25.3.1.2 Subtask - Verify runbook, attachment, and detail surfaces compile from resource-authority screens and related elements rather than detached documents.
      [x] 25.3.1.3 Subtask - Verify representative live diagnostics mount with seeded data, honest support notices, and visible stale/error handling.
      [x] 25.3.1.4 Subtask - Verify Chapters 6 and 7 each point to the correct checkpoint directory and supporting modules/resources.
