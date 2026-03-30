# Phase 15 - Compiler And Runtime Graph Realignment

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `AshUI.Compiler`
- `AshUI.LiveView.Integration`
- runtime binding evaluators
- canonical `unified_iur` conversion

## Relevant Assumptions / Defaults
- compilation starts from the screen resource and traverses relationships
- element resources own their DSL, bindings, and actions
- no backward compatibility is required for the superseded document-first path

[x] 15 Phase 15 - Compiler And Runtime Graph Realignment
  Rebuild compiler and runtime behavior around the screen/element resource graph
  rather than monolithic screen-document authority.

  [x] 15.1 Section - Graph Compiler Refactor
    Change the compiler's primary inputs back to screen and element resources.

    [x] 15.1.1 Task - Screen-root graph traversal
    Make graph traversal the primary compilation entry path.

      [x] 15.1.1.1 Subtask - Load the screen resource as the root node
      [x] 15.1.1.2 Subtask - Traverse related element resources and ordering metadata
      [x] 15.1.1.3 Subtask - Collect inline screen DSL only as a secondary fragment source
      [x] 15.1.1.4 Subtask - Remove assumptions that the full UI tree is already serialized on the screen

    [x] 15.1.2 Task - Embedded DSL lowering
    Lower resource-local DSL fragments through upstream construct semantics.

      [x] 15.1.2.1 Subtask - Lower element-local DSL fragments through upstream `unified_ui`
      [x] 15.1.2.2 Subtask - Lower inline screen fragments through the same path
      [x] 15.1.2.3 Subtask - Merge lowered fragments back into one resource-derived graph
      [x] 15.1.2.4 Subtask - Add deterministic IDs and stable cache keys for graph-derived nodes

  [x] 15.2 Section - Binding And Runtime Refactor
    Align runtime hydration and event handling with resource-local authorship.

    [x] 15.2.1 Task - Resource-local binding extraction
    Hydrate bindings from the owning resources instead of detached monoliths.

      [x] 15.2.1.1 Subtask - Extract element-local bindings with their owning element identity
      [x] 15.2.1.2 Subtask - Extract screen-scoped bindings separately
      [x] 15.2.1.3 Subtask - Preserve signal/action locality through hydration
      [x] 15.2.1.4 Subtask - Remove runtime assumptions tied to screen-document binding metadata

    [x] 15.2.2 Task - Event routing realignment
    Route events back to the owning element or screen resource context.

      [x] 15.2.2.1 Subtask - Route user events through graph-derived ownership metadata
      [x] 15.2.2.2 Subtask - Execute declared actions against the owning resource/action boundary
      [x] 15.2.2.3 Subtask - Preserve authorization and error handling in the new routing path
      [x] 15.2.2.4 Subtask - Add integration tests for event locality and ownership

  [x] 15.3 Section - Hard Removal Of Superseded Compiler Paths
    Remove or rewrite compiler paths that only exist for the detour architecture.

    [x] 15.3.1 Task - Remove screen-document authority assumptions
    Strip out the dead-end architecture rather than carrying it forever.

      [x] 15.3.1.1 Subtask - Identify compiler entry points that assume monolithic screen documents
      [x] 15.3.1.2 Subtask - Remove or rewrite those entry points without compatibility shims
      [x] 15.3.1.3 Subtask - Update caching, telemetry, and conformance expectations
      [x] 15.3.1.4 Subtask - Document the hard break in release notes and migration guidance

  [x] 15.4 Section - Phase 15 Integration Tests
    Validate compilation and runtime behavior end to end under the restored
    resource-first model.

    [x] 15.4.1 Task - Graph-derived runtime scenarios
    Verify the runtime works from the resource graph through renderer output.

      [x] 15.4.1.1 Subtask - Verify a relationally composed screen compiles to stable canonical IUR
      [x] 15.4.1.2 Subtask - Verify element-local bindings hydrate and react correctly
      [x] 15.4.1.3 Subtask - Verify element-local actions execute through event handling
      [x] 15.4.1.4 Subtask - Verify superseded screen-document compiler paths are removed or rejected
