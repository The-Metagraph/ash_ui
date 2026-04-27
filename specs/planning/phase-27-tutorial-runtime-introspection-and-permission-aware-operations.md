# Phase 27 - Tutorial Runtime Introspection and Permission-Aware Operations

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- `Ash.Policy.Authorizer`
- `AshUI.Runtime.*`
- operational and authorization surfaces from the checked-in suite

## Relevant Assumptions / Defaults
- previous tutorial phases have already established a believable operational
  console with services, incidents, diagnostics, topology, and metrics
- this phase should deepen the tutorial into runtime-inspection and policy-aware
  behavior rather than adding more superficial UI coverage
- the actor profiles defined in Phase 23 remain the basis for permission-aware
  screens and actions

[ ] 27 Phase 27 - Tutorial Runtime Introspection and Permission-Aware Operations
  Implement the tutorial milestones that add deeper runtime inspection and
  role-aware operational behavior to the Operations Control Center application.

  [x] 27.1 Section - Chapter 10 Runtime Introspection and Process Views
    Add the lower-level runtime surfaces advanced operators need when higher
    level dashboards are not enough.

    [x] 27.1.1 Task - Implement runtime inspection checkpoints
    Teach deeper system introspection through explicit tutorial screens instead
    of burying it in auxiliary notes.

      [x] 27.1.1.1 Subtask - Implement `tutorials/code/10-runtime-introspection/` with `supervision_tree_viewer`, expanded process/runtime views, and the related navigation needed to move between incidents, services, and BEAM structures.
      [x] 27.1.1.2 Subtask - Use supporting surfaces such as `table`, `command_palette`, and summary panels where they clarify runtime drill-down workflows.
      [x] 27.1.1.3 Subtask - Keep the tutorial explicit about which runtime trees and process details are real, sampled, or tutorial-seeded.
      [x] 27.1.1.4 Subtask - Add `tutorials/chapters/10-runtime-introspection.md` with exact references to `tutorials/code/10-runtime-introspection/`.

  [ ] 27.2 Section - Chapter 11 Roles, Policies, and Permission-Aware Screens
    Add the authorization story that makes the tutorial usable for production
    architecture education rather than only local demos.

    [ ] 27.2.1 Task - Implement permission-aware tutorial flows
    Teach how resource policies and screen composition interact for different
    operators.

      [ ] 27.2.1.1 Subtask - Implement `tutorials/code/11-roles-and-policies/` with role-aware views for `admin`, `on_call_operator`, and `viewer`.
      [ ] 27.2.1.2 Subtask - Show how actions, overlays, forms, and navigation surfaces change when authorization removes or restricts capabilities.
      [ ] 27.2.1.3 Subtask - Ensure the chapter ties permission behavior back to Ash policies and the authoritative screen/element graph rather than only host-template conditionals.
      [ ] 27.2.1.4 Subtask - Add `tutorials/chapters/11-roles-and-policies.md` with exact references to `tutorials/code/11-roles-and-policies/`.

  [ ] 27.3 Section - Phase 27 Integration Tests
    Validate the runtime-inspection and permission-aware chapters through
    representative operator scenarios.

    [ ] 27.3.1 Task - Runtime and policy scenarios
    Prove the tutorial can now teach both deep operational visibility and safe
    access control.

      [ ] 27.3.1.1 Subtask - Verify the Chapter 10 and 11 checkpoint apps boot independently and preserve the tutorial shell and chapter-reference contract.
      [ ] 27.3.1.2 Subtask - Verify runtime introspection surfaces remain navigable and traceable to the seeded services, incidents, and clusters that lead into them.
      [ ] 27.3.1.3 Subtask - Verify role-aware screens and actions behave differently for the seeded actor profiles and fail clearly when policy denies access.
      [ ] 27.3.1.4 Subtask - Verify Chapters 10 and 11 each reference the correct checkpoint directory, actor profiles, and policy modules explicitly.
