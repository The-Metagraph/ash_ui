# Phase 12 - Example, Tooling, and Conformance Migration

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/basic_dashboard`
- `AshUI.DSL.Builder`
- `mix ash_ui.example.basic_dashboard`
- conformance and governance scripts

## Relevant Assumptions / Defaults
- public examples should demonstrate the intended architecture
- docs and guides must stop teaching the legacy builder-first path
- renderer parity remains important for `liveview` and `elm`
- `desktop` and `terminal_ui` status remain independently tracked

[ ] 12 Phase 12 - Example, Tooling, and Conformance Migration
  Move the public examples, tooling, docs, and governance checks to the upstream `unified_ui` authoring model and close the DSL authority gap.

  [x] 12.1 Section - Example Conversion
    Make shipped examples demonstrate the correct authoring surface.

    [x] 12.1.1 Task - Convert the dashboard example
    Ensure the main example no longer demonstrates builder-first authoring.

      [x] 12.1.1.1 Subtask - Rewrite `basic_dashboard` screen authoring through upstream `unified_ui`
      [x] 12.1.1.2 Subtask - Preserve ETS-backed example data and storage flows
      [x] 12.1.1.3 Subtask - Preserve `liveview` and `elm` adapter parity coverage
      [x] 12.1.1.4 Subtask - Keep the standalone example app runnable from its own directory

    [x] 12.1.2 Task - Update example tooling
    Keep developer workflows aligned with the new authoring model.

      [x] 12.1.2.1 Subtask - Update the dashboard adapter runner for upstream-authored screens
      [x] 12.1.2.2 Subtask - Update mix tasks and example output summaries
      [x] 12.1.2.3 Subtask - Update examples/README command docs
      [x] 12.1.2.4 Subtask - Add regression tests covering example CLI flows

  [x] 12.2 Section - Guide And API Migration
    Remove public guidance that points users toward the legacy builder path.

    [x] 12.2.1 Task - Rewrite user and developer guidance
    Make the documented path match the new architecture.

      [x] 12.2.1.1 Subtask - Update README examples to use upstream `unified_ui`
      [x] 12.2.1.2 Subtask - Update user guides and developer guides to remove builder-first instructions
      [x] 12.2.1.3 Subtask - Update API docs and module docs to mark `AshUI.DSL.Builder` as legacy
      [x] 12.2.1.4 Subtask - Add migration notes for applications using the old builder path

  [ ] 12.3 Section - Governance And Conformance Closeout
    Make the specs, tests, and review gates assert the new architecture directly.

    [ ] 12.3.1 Task - Add governance checks for the old names and APIs
    Prevent the repo from silently drifting back to the builder-first model.

      [ ] 12.3.1.1 Subtask - Add grep-style review or CI checks for builder-first usage in public examples and docs
      [ ] 12.3.1.2 Subtask - Update governance scripts to allow historical mentions only in ADRs, changelog, and migration notes
      [ ] 12.3.1.3 Subtask - Add review checklist guidance for upstream DSL authority
      [ ] 12.3.1.4 Subtask - Document the remaining migration-only exceptions allowed in historical code paths

    [ ] 12.3.2 Task - Refresh conformance coverage
    Make scenario coverage prove the upstream authoring path actually works.

      [ ] 12.3.2.1 Subtask - Add conformance scenarios for persisted upstream DSL screens
      [ ] 12.3.2.2 Subtask - Add scenarios for upstream compiler delegation and renderer parity
      [ ] 12.3.2.3 Subtask - Update the conformance matrix and scenario traceability docs
      [ ] 12.3.2.4 Subtask - Re-baseline release-readiness gates around the new architecture

  [ ] 12.4 Section - Phase 12 Integration Tests
    Validate that public examples and repo governance now reflect the intended architecture.

    [ ] 12.4.1 Task - Example and governance scenarios
    Verify the repo demonstrates and enforces the upstream DSL model.

      [ ] 12.4.1.1 Subtask - Verify the standalone example app runs with upstream-authored screens
      [ ] 12.4.1.2 Subtask - Verify adapter tooling works against upstream-authored screens
      [ ] 12.4.1.3 Subtask - Verify governance checks reject builder-first public examples
      [ ] 12.4.1.4 Subtask - Verify conformance coverage documents the new architecture accurately
