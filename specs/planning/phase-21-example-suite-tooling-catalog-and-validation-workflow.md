# Phase 21 - Example Suite Tooling, Catalog, and Validation Workflow

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/README.md`
- `examples/catalog.tsv`
- per-app `mix example.start` workflows
- `scripts/*`
- conformance and governance validation surfaces
- Ash UI example metadata and suite discovery helpers

## Relevant Assumptions / Defaults
- most or all mirrored example directories now exist before this phase begins
- maintainers need one coherent way to discover, run, preview, and validate the
  suite rather than manually navigating dozens of standalone apps
- validation should focus on catalog completeness, resource-authority continuity,
  shared-theme continuity, and governance against superseded authoring
- the example suite should remain honest about unsupported widgets and runtime
  limits rather than silently masking them

[ ] 21 Phase 21 - Example Suite Tooling, Catalog, and Validation Workflow
  Implement the discovery, launcher, validation, and governance workflows that
  turn the mirrored Ash UI example catalog into a maintainable review surface.

  [ ] 21.1 Section - Root Suite Index and Catalog Discovery
    Provide one authoritative way to map the example suite quickly.

    [ ] 21.1.1 Task - Implement the root example-suite index
    Make the root `examples/` directory readable as a product surface rather
    than only a filesystem tree.

      [ ] 21.1.1.1 Subtask - Implement the root `examples/README.md` as the landing page for the mirrored Ash UI example suite.
      [ ] 21.1.1.2 Subtask - Add machine-readable catalog metadata that maps example directory names to widget family, canonical Ash UI type, and runtime notes.
      [ ] 21.1.1.3 Subtask - Add discovery metadata that records where catalog parity is exact versus normalized through canonical type mappings.
      [ ] 21.1.1.4 Subtask - Add tests that prove the root index stays synchronized with the machine-readable example catalog.

  [ ] 21.2 Section - Independent App Run and Preview Tooling
    Give maintainers one repeatable path for launching and reviewing any app.

    [ ] 21.2.1 Task - Implement per-app launcher workflows
    Make app startup and previewing routine instead of bespoke.

      [ ] 21.2.1.1 Subtask - Implement and standardize `mix example.start` or an equivalent maintained launcher surface for each app.
      [ ] 21.2.1.2 Subtask - Add helper workflows for selecting representative actor, seed, and runtime mode where an example supports more than one review path.
      [ ] 21.2.1.3 Subtask - Add preview surfaces that foreground the shared Ash HQ shell, the primary interaction story, and the canonical signal preview consistently.
      [ ] 21.2.1.4 Subtask - Add tests that prove maintainers can discover and launch representative apps from multiple families through one workflow.

  [ ] 21.3 Section - Validation and Governance Checks
    Prevent the suite from drifting away from the architecture it is supposed to
    teach.

    [ ] 21.3.1 Task - Implement suite validation checks
    Ensure the mirrored catalog remains complete, honest, and resource-first.

      [ ] 21.3.1.1 Subtask - Implement validation that every catalog entry has a corresponding example-app directory and expected app metadata.
      [ ] 21.3.1.2 Subtask - Implement validation that every example app persists screens through `AshUI.Resource.Authority` and uses `AshUI.Resource.DSL.*` instead of superseded authoring paths.
      [ ] 21.3.1.3 Subtask - Implement validation that every example app uses the shared Ash HQ theme contract and shared review surfaces.
      [ ] 21.3.1.4 Subtask - Add governance checks that reject builder-first, monolithic screen-document-first, or stale example-only runtime shortcuts in the suite.

  [ ] 21.4 Section - Review Metadata and Reporting
    Make the suite useful during package review, not only during app-level
    experimentation.

    [ ] 21.4.1 Task - Implement review metadata and suite reporting
    Give maintainers a clear way to assess catalog completeness and quality.

      [ ] 21.4.1.1 Subtask - Implement per-app metadata for family, canonical type mapping, shared-theme usage, and interaction-story status.
      [ ] 21.4.1.2 Subtask - Implement suite-level reporting for catalog completeness, resource-authority continuity, and theme-contract continuity.
      [ ] 21.4.1.3 Subtask - Implement reporting that calls out apps relying on `custom:*` or partial runtime support explicitly.
      [ ] 21.4.1.4 Subtask - Add tests that prove review metadata stays traceable to the suite catalog and root index.

  [ ] 21.5 Section - Phase 21 Integration Tests
    Validate the suite discovery, launcher, and validation workflows through one
    maintainer path.

    [ ] 21.5.1 Task - Tooling and validation integration scenarios
    Verify the example suite behaves like one coherent maintainer surface.

      [ ] 21.5.1.1 Subtask - Verify maintainers can discover, launch, and preview representative apps from multiple families through the maintained workflow.
      [ ] 21.5.1.2 Subtask - Verify validation catches catalog drift, superseded authoring, and shared-theme divergence reliably.
      [ ] 21.5.1.3 Subtask - Verify review metadata remains aligned with the machine-readable catalog and root index.
      [ ] 21.5.1.4 Subtask - Verify unsupported-surface annotations stay visible instead of being silently dropped from suite reports.
