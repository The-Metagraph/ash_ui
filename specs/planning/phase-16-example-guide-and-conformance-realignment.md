# Phase 16 - Example, Guide, And Conformance Realignment

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- example applications
- public guides and README paths
- governance validation scripts
- conformance matrices and scenario catalogs

## Relevant Assumptions / Defaults
- public examples must demonstrate the intended architecture
- governance must reject examples and docs that drift back to the superseded
  model
- no backward compatibility is required for the old screen-monolith examples

[ ] 16 Phase 16 - Example, Guide, And Conformance Realignment
  Realign examples, guides, and governance so the repo demonstrates the restored
  resource-first architecture instead of the superseded screen-document model.

  [x] 16.1 Section - Example Application Realignment
    Rebuild demo apps around screen and element resources using the `AshUI`
    extension.

    [x] 16.1.1 Task - Rebuild `basic_dashboard`
    Make the flagship example demonstrate the intended architecture.

      [x] 16.1.1.1 Subtask - Define the dashboard screen as a screen resource using the `AshUI` extension
      [x] 16.1.1.2 Subtask - Break the dashboard into element resources with local DSL, bindings, and actions
      [x] 16.1.1.3 Subtask - Express the dashboard structure through Ash relationships
      [x] 16.1.1.4 Subtask - Retain only minimal inline screen DSL where another resource would be noise

    [x] 16.1.2 Task - Adapter tooling parity
    Keep example tooling aligned with the restored authoring model.

      [x] 16.1.2.1 Subtask - Update adapter runner tooling to compile from resource graphs
      [x] 16.1.2.2 Subtask - Update mix tasks and example READMEs
      [x] 16.1.2.3 Subtask - Preserve liveview and elm parity coverage
      [x] 16.1.2.4 Subtask - Keep desktop and terminal_ui expectations honest in docs/tests

  [ ] 16.2 Section - Guide And API Documentation Realignment
    Remove public teaching material that points contributors at the wrong model.

    [ ] 16.2.1 Task - Rewrite public guidance
    Make the resource-first model the only documented happy path.

      [ ] 16.2.1.1 Subtask - Rewrite README and user guides around screen and element resources
      [ ] 16.2.1.2 Subtask - Remove builder-first and screen-monolith-first examples
      [ ] 16.2.1.3 Subtask - Document element-local bindings and action declarations
      [ ] 16.2.1.4 Subtask - Document the limited role of inline screen DSL and upstream `unified_ui`

  [ ] 16.3 Section - Governance And Conformance Reset
    Prevent drift back to the superseded architecture.

    [ ] 16.3.1 Task - Governance enforcement
    Add gates that reject the wrong architectural signals in docs and examples.

      [ ] 16.3.1.1 Subtask - Reject new public examples centered on monolithic screen-document authority
      [ ] 16.3.1.2 Subtask - Reject public guides that present detached screen documents as the preferred model
      [ ] 16.3.1.3 Subtask - Add review checklists for element-resource authority and relationship-driven composition
      [ ] 16.3.1.4 Subtask - Update release readiness docs for the hard architectural cut

    [ ] 16.3.2 Task - Conformance traceability
    Realign the scenario catalog and conformance matrix with the restored model.

      [ ] 16.3.2.1 Subtask - Add scenarios for element-resource-first authoring
      [ ] 16.3.2.2 Subtask - Add scenarios for relationship-driven composition
      [ ] 16.3.2.3 Subtask - Remove or downgrade scenarios that only validate the superseded model
      [ ] 16.3.2.4 Subtask - Add final integration coverage for examples, governance, and compiler/runtime parity

  [ ] 16.4 Section - Phase 16 Integration Tests
    Validate the restored model in public-facing repo surfaces.

    [ ] 16.4.1 Task - Public surface scenarios
    Verify the examples, guides, and governance all point at the same
    architecture.

      [ ] 16.4.1.1 Subtask - Verify the flagship example compiles from screen and element resources
      [ ] 16.4.1.2 Subtask - Verify public docs describe resource-local authoring and relationship-driven composition
      [ ] 16.4.1.3 Subtask - Verify governance rejects reintroduction of the superseded model
      [ ] 16.4.1.4 Subtask - Verify conformance traces to the restored architecture
