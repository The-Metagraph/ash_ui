# Phase 11 - Upstream Compiler Delegation

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `AshUI.Compiler`
- upstream `UnifiedUI.Compiler`
- `unified_iur`
- Ash UI runtime binding and hydration layers

## Relevant Assumptions / Defaults
- upstream `UnifiedUI.Compiler` owns authoring-level parsing and compilation
- Ash UI must preserve current binding, runtime, and caching semantics
- canonical `unified_iur` remains the renderer boundary
- Ash UI may still maintain an internal runtime shape, but it must be derived from upstream compiler output

[ ] 11 Phase 11 - Upstream Compiler Delegation
  Delegate DSL parsing and compilation to upstream `unified_ui` while preserving Ash UI bindings, runtime hydration, and canonical conversion.

  [X] 11.1 Section - Compiler Handoff
    Replace the Ash UI-owned authoring compilation path with upstream compiler delegation.

    [X] 11.1.1 Task - Load and hand off persisted DSL to upstream compiler
    Make upstream compilation the primary path in `AshUI.Compiler`.

      [X] 11.1.1.1 Subtask - Load serialized upstream documents from `Screen.unified_dsl`
      [X] 11.1.1.2 Subtask - Call upstream `UnifiedUI.Compiler` from `AshUI.Compiler`
      [X] 11.1.1.3 Subtask - Normalize and surface upstream compile errors through Ash UI
      [X] 11.1.1.4 Subtask - Remove builder-first compilation as the default code path

    [X] 11.1.2 Task - Define the Ash UI runtime compilation boundary
    Clarify what Ash UI adds after upstream compilation returns.

      [X] 11.1.2.1 Subtask - Define the shape Ash UI expects from upstream compiler output
      [X] 11.1.2.2 Subtask - Attach Ash binding metadata without mutating upstream widget semantics
      [X] 11.1.2.3 Subtask - Preserve screen metadata and runtime context required by LiveView
      [X] 11.1.2.4 Subtask - Document the post-compile augmentation boundary

  [X] 11.2 Section - Runtime Hydration Alignment
    Keep LiveView and action/value/list binding behavior working against upstream-compiled trees.

    [X] 11.2.1 Task - Rework hydration around upstream output
    Ensure dynamic values continue to flow into rendered screens correctly.

      [X] 11.2.1.1 Subtask - Update runtime hydration to target upstream-compiled node shapes
      [X] 11.2.1.2 Subtask - Preserve bidirectional input binding semantics
      [X] 11.2.1.3 Subtask - Preserve action binding semantics and transform handling
      [X] 11.2.1.4 Subtask - Preserve list binding semantics and reactivity

    [X] 11.2.2 Task - Realign incremental compilation and cache invalidation
    Keep performance work valid after the compiler boundary moves upstream.

      [X] 11.2.2.1 Subtask - Add upstream document hash and compiler version to cache keys
      [X] 11.2.2.2 Subtask - Revisit dependency graph construction around upstream-authored documents
      [X] 11.2.2.3 Subtask - Verify cache invalidation still tracks screen/resource changes correctly
      [X] 11.2.2.4 Subtask - Measure cache hit/miss behavior for the delegated compiler path

  [ ] 11.3 Section - Canonical Conversion And Renderer Stability
    Keep renderer contracts stable while the compiler boundary changes.

    [ ] 11.3.1 Task - Preserve canonical `unified_iur` output contracts
    Ensure renderer packages continue to receive the same canonical boundary.

      [ ] 11.3.1.1 Subtask - Verify upstream compiler output remains convertible to canonical `unified_iur`
      [ ] 11.3.1.2 Subtask - Verify renderer adapters do not need Ash UI-specific authoring assumptions
      [ ] 11.3.1.3 Subtask - Verify semantic widgets survive compile and render paths intact
      [ ] 11.3.1.4 Subtask - Document any remaining Ash UI runtime annotations on canonical output

  [ ] 11.4 Section - Phase 11 Integration Tests
    Validate delegated compilation end to end.

    [ ] 11.4.1 Task - Compiler delegation scenarios
    Verify screens compile and render correctly through the upstream compiler path.

      [ ] 11.4.1.1 Subtask - Verify an upstream-authored screen compiles through `AshUI.Compiler`
      [ ] 11.4.1.2 Subtask - Verify live bindings hydrate correctly after upstream compilation
      [ ] 11.4.1.3 Subtask - Verify canonical renderer output is unchanged for equivalent screens
      [ ] 11.4.1.4 Subtask - Verify cache and incremental recompilation still behave correctly
