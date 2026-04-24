# Phase 16 - Example, Guide, And Conformance Realignment

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/README.md`
- checked-in public example surfaces
- public guides and README paths
- governance validation scripts
- conformance matrices and scenario catalogs

## Relevant Assumptions / Defaults
- the repository may temporarily ship no runnable public examples
- any future public examples must demonstrate the intended architecture
- governance must reject examples and docs that drift back to the superseded
  model
- no backward compatibility is required for the old screen-monolith examples

[ ] 16 Phase 16 - Example, Guide, And Conformance Realignment
  Realign examples, guides, governance, and conformance so the repo reflects
  the restored resource-first architecture after removal of the checked-in
  flagship example.

  [x] 16.1 Section - Example Surface Reset
    Remove the stale checked-in flagship example and leave the public example
    surface explicit about its temporary absence.

    [x] 16.1.1 Task - Remove the checked-in flagship example app
    Keep the repo from advertising a public example that no longer matches the
    maintained surface area.

      [x] 16.1.1.1 Subtask - Remove the checked-in flagship example app from `examples/`
      [x] 16.1.1.2 Subtask - Remove example-specific adapter tooling and compile-path wiring
      [x] 16.1.1.3 Subtask - Remove example-specific tests and conformance references
      [x] 16.1.1.4 Subtask - Update `examples/README.md` to state that no checked-in examples currently ship

    [x] 16.1.2 Task - Keep the public example surface honest
    Avoid leaving stale docs or commands behind after the example removal.

      [x] 16.1.2.1 Subtask - Remove stale example mix tasks and command docs
      [x] 16.1.2.2 Subtask - Remove stale references from planning and conformance docs
      [x] 16.1.2.3 Subtask - Keep renderer parity claims scoped to maintained test surfaces only
      [x] 16.1.2.4 Subtask - Avoid implying runnable example support where none is checked in

  [x] 16.2 Section - Guide And API Documentation Realignment
    Remove public teaching material that points contributors at the wrong model.

    [x] 16.2.1 Task - Rewrite public guidance
    Make the resource-first model the only documented happy path.

      [x] 16.2.1.1 Subtask - Rewrite README and user guides around screen and element resources
      [x] 16.2.1.2 Subtask - Remove builder-first and screen-monolith-first examples
      [x] 16.2.1.3 Subtask - Document element-local bindings and action declarations
      [x] 16.2.1.4 Subtask - Document the limited role of inline screen DSL and upstream `unified_ui`

  [x] 16.3 Section - Governance And Conformance Reset
    Prevent drift back to the superseded architecture.

    [x] 16.3.1 Task - Governance enforcement
    Add gates that reject the wrong architectural signals in docs and examples.

      [x] 16.3.1.1 Subtask - Reject new public examples centered on monolithic screen-document authority
      [x] 16.3.1.2 Subtask - Reject public guides that present detached screen documents as the preferred model
      [x] 16.3.1.3 Subtask - Add review checklists for element-resource authority and relationship-driven composition
      [x] 16.3.1.4 Subtask - Update release readiness docs for the hard architectural cut

    [x] 16.3.2 Task - Conformance traceability
    Realign the scenario catalog and conformance matrix with the restored model
    and the now-empty checked-in example surface.

      [x] 16.3.2.1 Subtask - Add scenarios for element-resource-first authoring
      [x] 16.3.2.2 Subtask - Add scenarios for relationship-driven composition
      [x] 16.3.2.3 Subtask - Remove or downgrade scenarios that only validate the superseded model
      [x] 16.3.2.4 Subtask - Remove example-only traceability rows and keep the matrices aligned with maintained public surfaces

  [ ] 16.4 Section - Phase 16 Integration Tests
    Validate the restored model in the remaining public-facing repo surfaces.

  [ ] 16.4.1 Task - Public surface scenarios
    Verify the remaining public docs, governance, and examples index all point
    at the same architecture.

      [ ] 16.4.1.1 Subtask - Verify the repo does not ship stale example app wiring or commands
      [ ] 16.4.1.2 Subtask - Verify public docs describe resource-local authoring and the current example surface accurately
      [ ] 16.4.1.3 Subtask - Verify governance rejects reintroduction of the superseded model
      [ ] 16.4.1.4 Subtask - Verify conformance traces to the restored architecture without example-only scenarios
