# Phase 14 - Relational Screen Composition

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- screen resource modules
- element resource relationships
- ordering and placement metadata
- optional inline screen DSL

## Relevant Assumptions / Defaults
- screens compose primarily through related element resources
- inline screen DSL is allowed, but subordinate
- Ash relationships are the primary UI composition language

[ ] 14 Phase 14 - Relational Screen Composition
  Restore screen composition through Ash relationships while retaining optional
  inline DSL for glue and layout scaffolding.

  [x] 14.1 Section - Screen Resource Composition Model
    Define the screen as a relationship-driven composition root.

    [x] 14.1.1 Task - Define primary screen-to-element composition
    Make the screen/resource graph the normative source of composition.

      [x] 14.1.1.1 Subtask - Define how screens reference primary child element resources
      [x] 14.1.1.2 Subtask - Define ordering and placement semantics on those relationships
      [x] 14.1.1.3 Subtask - Define how nested element relationships contribute to screen composition
      [x] 14.1.1.4 Subtask - Add validation rules for illegal composition graphs

    [x] 14.1.2 Task - Define inline screen composition
    Preserve direct screen DSL for cases where another resource would be noise.

      [x] 14.1.2.1 Subtask - Define allowed inline screen DSL use cases
      [x] 14.1.2.2 Subtask - Define merge semantics between inline fragments and related element resources
      [x] 14.1.2.3 Subtask - Define precedence and conflict rules
      [x] 14.1.2.4 Subtask - Add tests for mixed relational and inline composition

  [ ] 14.2 Section - Relationship Semantics
    Ensure Ash relationships are rich enough to describe the UI tree.

    [ ] 14.2.1 Task - Parent/child and companion semantics
    Model composition explicitly in resource relationships.

      [ ] 14.2.1.1 Subtask - Define parent/child nesting semantics
      [ ] 14.2.1.2 Subtask - Define sibling/companion element semantics
      [ ] 14.2.1.3 Subtask - Define optional slot or placement semantics where needed
      [ ] 14.2.1.4 Subtask - Validate cycles, duplicates, and illegal placements

    [ ] 14.2.2 Task - Screen-scoped overlays
    Allow screen-local wrappers without collapsing the whole screen into one
    authored document.

      [ ] 14.2.2.1 Subtask - Define screen-local wrappers and layout shell semantics
      [ ] 14.2.2.2 Subtask - Define how screen-scoped bindings participate in the composed graph
      [ ] 14.2.2.3 Subtask - Define how screen metadata flows into the composed output
      [ ] 14.2.2.4 Subtask - Add parity tests for relational and mixed composition

  [ ] 14.3 Section - Removal Of Screen-Monolith Assumptions
    Clear out the assumptions introduced by the superseded document-first model.

    [ ] 14.3.1 Task - Remove monolithic composition as the preferred path
    Make sure the project no longer teaches or optimizes for screen-authority
    monoliths first.

      [ ] 14.3.1.1 Subtask - Remove examples that primarily compose the whole UI inside one screen document
      [ ] 14.3.1.2 Subtask - Update compiler assumptions that treat the screen document as the full tree
      [ ] 14.3.1.3 Subtask - Update docs to present inline screen DSL as a secondary escape hatch
      [ ] 14.3.1.4 Subtask - Add governance checks that reject new monolithic-authority examples

  [ ] 14.4 Section - Phase 14 Integration Tests
    Validate relational screen composition end to end.

    [ ] 14.4.1 Task - Relationship-driven composition scenarios
    Verify screens compile primarily from related element resources.

      [ ] 14.4.1.1 Subtask - Verify a screen with related element resources compiles in relationship order
      [ ] 14.4.1.2 Subtask - Verify nested element relationships produce nested IUR output
      [ ] 14.4.1.3 Subtask - Verify mixed relational plus inline composition works
      [ ] 14.4.1.4 Subtask - Verify illegal graphs fail fast and descriptively
