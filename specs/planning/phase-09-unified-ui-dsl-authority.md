# Phase 9 - Unified UI DSL Authority

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `unified_ui` DSL and extension surface
- `AshUI.Compiler`
- `AshUI.Resources.Screen`
- `AshUI.DSL.Builder`

## Relevant Assumptions / Defaults
- upstream `unified_ui` owns the authoritative UI DSL
- Ash UI persists screen definitions in Ash resources
- Ash UI remains responsible for bindings, runtime orchestration, and canonical `unified_iur` conversion
- `AshUI.DSL.Builder` is a migration concern, not the target authoring API

[ ] 9 Phase 9 - Unified UI DSL Authority
  Make upstream `unified_ui` the authoritative authoring surface for persisted screen definitions and stop treating the in-repo builder as the public DSL.

  [X] 9.1 Section - Dependency And Boundary Alignment
    Establish the upstream package as the normative authoring dependency and define the Ash UI boundary around it.

    [X] 9.1.1 Task - Require `unified_ui` for authoring
    Make the upstream authoring package part of the supported Ash UI surface.

      [X] 9.1.1.1 Subtask - Add and require the upstream `unified_ui` dependency where Ash UI authoring occurs
      [X] 9.1.1.2 Subtask - Verify dependency/version compatibility with `unified_iur`, `live_ui`, `elm_ui`, and `desktop_ui`
      [X] 9.1.1.3 Subtask - Document the dependency as part of the Ash UI authoring contract
      [X] 9.1.1.4 Subtask - Update release/readiness docs to treat missing `unified_ui` as a configuration error

    [X] 9.1.2 Task - Define authoring ownership boundaries
    Clarify what Ash UI owns and what upstream `unified_ui` owns.

      [X] 9.1.2.1 Subtask - Document that widgets, layouts, and authoring grammar are owned by `unified_ui`
      [X] 9.1.2.2 Subtask - Document that Ash UI owns persistence, bindings, runtime state, and renderer orchestration
      [X] 9.1.2.3 Subtask - Remove spec language that implies Ash UI owns a parallel DSL
      [X] 9.1.2.4 Subtask - Align public guides and examples with the new ownership model

  [ ] 9.2 Section - Authoring Surface Integration
    Introduce the upstream DSL as the supported way to define screens for persistence.

    [X] 9.2.1 Task - Add a persisted-screen authoring bridge
    Provide the Ash UI boundary that accepts upstream DSL definitions and prepares them for storage.

      [X] 9.2.1.1 Subtask - Define the module or API boundary for accepting `unified_ui` screen definitions
      [X] 9.2.1.2 Subtask - Support screen metadata, route metadata, and Ash-specific binding metadata alongside upstream DSL
      [X] 9.2.1.3 Subtask - Define how authoring-time semantic widgets flow through the persistence boundary
      [X] 9.2.1.4 Subtask - Document the persistence authoring workflow for application developers

    [X] 9.2.2 Task - Route widget and layout extension registration upstream
    Prevent Ash UI from becoming the long-term owner of widget semantics.

      [X] 9.2.2.1 Subtask - Audit current widget/layout registration APIs in `AshUI.Compiler.Extensions`
      [X] 9.2.2.2 Subtask - Redirect public extension registration toward upstream `unified_ui`
      [X] 9.2.2.3 Subtask - Define the Ash UI compatibility layer for Ash-specific metadata only
      [X] 9.2.2.4 Subtask - Add tests showing custom widgets flow through the upstream authoring pipeline

  [ ] 9.3 Section - Legacy Builder Containment
    Freeze the in-repo builder as migration-only instead of continuing to grow it as a public DSL.

    [ ] 9.3.1 Task - Reclassify `AshUI.DSL.Builder`
    Keep existing screens migratable without letting the builder remain the long-term primary API.

      [ ] 9.3.1.1 Subtask - Mark the builder as compatibility or migration-only in docs and module docs
      [ ] 9.3.1.2 Subtask - Stop using the builder in new public examples and guides
      [ ] 9.3.1.3 Subtask - Add warnings or telemetry when legacy builder auth flows are exercised
      [ ] 9.3.1.4 Subtask - Define the eventual removal criteria for builder-first authoring

  [ ] 9.4 Section - Phase 9 Integration Tests
    Validate that upstream authoring is the primary supported path.

    [ ] 9.4.1 Task - Authoring boundary scenarios
    Verify Ash UI accepts upstream DSL definitions for persistence.

      [ ] 9.4.1.1 Subtask - Verify a screen defined through upstream `unified_ui` can be persisted
      [ ] 9.4.1.2 Subtask - Verify invalid upstream DSL errors surface clearly through Ash UI
      [ ] 9.4.1.3 Subtask - Verify semantic widgets pass through the persisted-screen authoring path
      [ ] 9.4.1.4 Subtask - Verify builder-first authoring is documented or signaled as legacy
