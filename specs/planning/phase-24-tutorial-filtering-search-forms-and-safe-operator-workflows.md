# Phase 24 - Tutorial Filtering, Search, Forms, and Safe Operator Workflows

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- `AshUI.Resource.DSL.Binding`
- `AshUI.LiveView.EventHandler`
- `AshUI.Runtime.*`
- command and form examples from the checked-in `examples/*` suite

## Relevant Assumptions / Defaults
- Phase 23 has already established the tutorial directory contract, final app,
  and the first two checkpoints
- tutorial chapters in this phase should keep the story centered on realistic
  operational workflows, not on disconnected widget tours
- every new chapter checkpoint remains independently runnable under
  `tutorials/code/`
- chapter prose must continue to reference the exact checkpoint directory it
  explains

[ ] 24 Phase 24 - Tutorial Filtering, Search, Forms, and Safe Operator Workflows
  Implement the tutorial milestones that add search, filtering, operator forms,
  and guarded overlay flows to the Operations Control Center application.

  [x] 24.1 Section - Chapter 3 Filtering, Search, and Command Navigation
    Add the discovery and query tools that make the workspace usable once the
    baseline services and incidents views exist.

    [x] 24.1.1 Task - Implement query and command workflows
    Teach stateful filtering and quick navigation through explicit bindings and
    resource-backed screen state.

      [x] 24.1.1.1 Subtask - Implement `tutorials/code/03-filtering-and-search/` with `text_input`, `select`, `checkbox`, `radio_group`, and `toggle` controls bound to persisted filter state.
      [x] 24.1.1.2 Subtask - Introduce `command_palette`, `menu`, and supporting navigation surfaces for quick jumps between services, incidents, and operator views.
      [x] 24.1.1.3 Subtask - Ensure filter updates drive meaningful changes in `list` and `table` views through resource-authority bindings or actions rather than ad hoc host-side state.
      [x] 24.1.1.4 Subtask - Add `tutorials/chapters/03-filtering-and-search.md` with exact references to `tutorials/code/03-filtering-and-search/` and the previous Chapter 2 checkpoint.

  [x] 24.2 Section - Chapter 4 Forms and Operator Actions
    Add the first write workflows so the tutorial moves beyond read-only
    monitoring.

    [x] 24.2.1 Task - Implement incident and maintenance form flows
    Teach resource-first forms, validation, and update actions in the context
    of operations work.

      [x] 24.2.1.1 Subtask - Implement `tutorials/code/04-operator-actions-and-forms/` with `form_builder`, `field_group`, and `field` scaffolds for acknowledge, assign, annotate, and maintenance-window flows.
      [x] 24.2.1.2 Subtask - Use `numeric_input`, `date_input`, `time_input`, `pick_list`, and related supporting controls where they clarify real operator actions instead of being inserted only for coverage.
      [x] 24.2.1.3 Subtask - Show validation, disabled states, and success/error feedback through resource-backed actions rather than host-only form simulations.
      [x] 24.2.1.4 Subtask - Add `tutorials/chapters/04-operator-actions-and-forms.md` with exact references to `tutorials/code/04-operator-actions-and-forms/`.

  [x] 24.3 Section - Chapter 5 Safe Overlays and Guarded Actions
    Add the safety rails that a real operations console needs for sensitive
    commands.

    [x] 24.3.1 Task - Implement dialogs, alerts, and transient feedback
    Teach confirmation and escalation flows without detaching them from the
    underlying resource model.

      [x] 24.3.1.1 Subtask - Implement `tutorials/code/05-safe-overlays-and-guards/` with `dialog`, `alert_dialog`, `overlay`, `context_menu`, and `toast` flows for restart, resolve, silence, and delete-style operations.
      [x] 24.3.1.2 Subtask - Ensure guarded actions show clear preconditions, destructive-action confirmations, and post-action feedback inside the shared Ash HQ shell.
      [x] 24.3.1.3 Subtask - Keep overlay state, action intent, and result summaries traceable to persisted tutorial resources or explicit runtime signals rather than invisible host-side shortcuts.
      [x] 24.3.1.4 Subtask - Add `tutorials/chapters/05-safe-overlays-and-guards.md` with exact references to `tutorials/code/05-safe-overlays-and-guards/`.

  [x] 24.4 Section - Phase 24 Integration Tests
    Validate the interaction-heavy middle tutorial checkpoints through one
    coherent maintainer path.

    [x] 24.4.1 Task - Filtering, form, and overlay scenarios
    Prove the tutorial can now handle realistic operator workflows.

      [x] 24.4.1.1 Subtask - Verify the Chapter 3, 4, and 5 checkpoint apps boot independently and preserve the shared shell and navigation contract.
      [x] 24.4.1.2 Subtask - Verify filters, command navigation, and resource-backed form actions update the visible workspace state predictably.
      [x] 24.4.1.3 Subtask - Verify guarded overlay flows reject unsafe or incomplete actions clearly and surface success/error feedback explicitly.
      [x] 24.4.1.4 Subtask - Verify Chapters 3, 4, and 5 each reference the correct checkpoint directory and previous checkpoint path in their prose.
