# Phase 10 - Persisted DSL Migration

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `AshUI.Resources.Screen`
- `Screen.unified_dsl`
- upstream `unified_ui` serialized document format
- Ash UI resource validations and storage helpers

## Relevant Assumptions / Defaults
- `Screen.unified_dsl` remains the durable persistence field
- the stored format must be owned by upstream `unified_ui`
- existing screens and examples still contain builder-shaped documents today
- migration safety matters more than preserving the builder as a public API

[ ] 10 Phase 10 - Persisted DSL Migration
  Migrate stored screen definitions from Ash UI-owned builder maps to serialized upstream `unified_ui` documents while keeping persisted screens readable and upgradable.

  [x] 10.1 Section - Stored Format Contract
    Define the durable serialized format that `Screen.unified_dsl` is allowed to hold.

    [x] 10.1.1 Task - Specify the persisted document boundary
    Make the storage contract explicit before implementation work lands.

      [x] 10.1.1.1 Subtask - Define the serialized `unified_ui` document shape accepted by Ash UI
      [x] 10.1.1.2 Subtask - Define document versioning and compatibility metadata
      [x] 10.1.1.3 Subtask - Define where Ash-specific binding and runtime annotations are stored
      [x] 10.1.1.4 Subtask - Document the persisted contract in resource and screen specs

    [x] 10.1.2 Task - Align resource validations to the new contract
    Make write-time validation match the upstream authoring model.

      [x] 10.1.2.1 Subtask - Replace builder-specific write validation with upstream document validation
      [x] 10.1.2.2 Subtask - Reject new writes that use unsupported builder-only structures
      [x] 10.1.2.3 Subtask - Translate upstream validation failures into Ash-friendly resource errors
      [x] 10.1.2.4 Subtask - Add coverage for invalid persisted document writes

  [x] 10.2 Section - Legacy Screen Migration
    Provide a deterministic rewrite path for existing screens to move into the new storage contract without keeping the legacy storage shape alive at runtime.

    [x] 10.2.1 Task - Build the migration transformer
    Convert existing builder-shaped documents into serialized upstream documents.

      [x] 10.2.1.1 Subtask - Audit the current builder storage shape used in persisted screens
      [x] 10.2.1.2 Subtask - Implement a deterministic builder-map to `unified_ui` document transformer
      [x] 10.2.1.3 Subtask - Preserve binding, metadata, and version information during transformation
      [x] 10.2.1.4 Subtask - Add dry-run reporting for screens that cannot be migrated automatically

    [x] 10.2.2 Task - Roll the migration through examples and shipped seeds
    Ensure the repo no longer ships or persists builder-shaped screen documents.

      [x] 10.2.2.1 Subtask - Migrate example screen seeds to the serialized upstream format
      [x] 10.2.2.2 Subtask - Migrate test fixtures and seeded screens used in integration coverage
      [x] 10.2.2.3 Subtask - Update example storage docs to describe the new persisted format
      [x] 10.2.2.4 Subtask - Verify no new builder-shaped documents are introduced in repo-owned seeds

  [ ] 10.3 Section - Read/Write Compatibility Window
    Keep the system operable during migration without leaving the old format as a permanent API.

    [ ] 10.3.1 Task - Define temporary compatibility rules
    Control how long legacy documents remain readable.

      [ ] 10.3.1.1 Subtask - Support reading legacy builder-shaped documents during the migration window
      [ ] 10.3.1.2 Subtask - Support explicit rewrite or backfill paths for legacy screens
      [ ] 10.3.1.3 Subtask - Block legacy-format writes once upstream authoring is available
      [ ] 10.3.1.4 Subtask - Document the cutoff for removing legacy read compatibility

  [ ] 10.4 Section - Phase 10 Integration Tests
    Validate that persisted screens survive the migration safely.

    [ ] 10.4.1 Task - Stored document migration scenarios
    Verify new and old documents behave correctly through the migration window.

      [ ] 10.4.1.1 Subtask - Verify a new upstream-authored screen persists successfully
      [ ] 10.4.1.2 Subtask - Verify a legacy builder-authored screen can be migrated
      [ ] 10.4.1.3 Subtask - Verify unsupported legacy shapes are reported clearly
      [ ] 10.4.1.4 Subtask - Verify migrated screens retain metadata, bindings, and versions
