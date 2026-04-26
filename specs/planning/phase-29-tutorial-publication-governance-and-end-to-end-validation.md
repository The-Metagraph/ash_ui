# Phase 29 - Tutorial Publication, Governance, and End-to-End Validation

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `tutorials/README.md`
- `tutorials/chapters/*`
- `tutorials/code/*`
- `tutorials/operations_control_center/*`
- root `README.md`
- user and developer guides
- release, governance, and conformance scripts

## Relevant Assumptions / Defaults
- the Chapter 1 through 12 checkpoints and the maintained final tutorial app
  exist or are close to complete before this phase begins
- tutorial publication should keep chapter prose, checkpoint code, and the
  maintained final app synchronized rather than letting one become the hidden
  source of truth
- the tutorial should be clearly distinguished from the `examples/` suite while
  still reusing the same resource-first architectural contract

[ ] 29 Phase 29 - Tutorial Publication, Governance, and End-to-End Validation
  Publish the Operations Control Center tutorial as a maintained repo surface
  with explicit chapter-to-code validation, governance, release readiness, and
  end-to-end proof.

  [ ] 29.1 Section - Tutorial Public Documentation Surface
    Make the tutorial visible and understandable from the repo's public docs
    instead of leaving it discoverable only by directory browsing.

    [ ] 29.1.1 Task - Publish the tutorial landing page and chapter index
    Turn the tutorial into a coherent reading path.

      [ ] 29.1.1.1 Subtask - Finalize `tutorials/README.md` as the landing page for the Operations Control Center series, including chapter order and expected learning outcomes.
      [ ] 29.1.1.2 Subtask - Add navigation and index material that links every chapter document to its checkpoint directory under `tutorials/code/`.
      [ ] 29.1.1.3 Subtask - Add a widget-coverage and screen-coverage summary so readers understand which parts of the Ash UI surface the tutorial exercises.
      [ ] 29.1.1.4 Subtask - Update the root `README.md` and relevant guides to point readers at the new tutorial surface and explain how it differs from the example suite.

  [ ] 29.2 Section - Tutorial Governance and Checkpoint Validation
    Keep the tutorial maintainable once it lands by rejecting drift between
    prose, checkpoint code, and the final app.

    [ ] 29.2.1 Task - Implement tutorial-specific validation rules
    Make chapter/code synchronization part of the normal quality bar.

      [ ] 29.2.1.1 Subtask - Add validation that every chapter document has a corresponding checkpoint directory under `tutorials/code/`.
      [ ] 29.2.1.2 Subtask - Add validation that every checkpoint directory is a runnable standalone Mix project and still uses the resource-authority authoring path.
      [ ] 29.2.1.3 Subtask - Add validation that every chapter includes the required checkpoint-reference block and any required previous-checkpoint reference.
      [ ] 29.2.1.4 Subtask - Add validation that `tutorials/operations_control_center/` remains aligned with the final chapter checkpoint within the documented allowed differences.

  [ ] 29.3 Section - Tutorial Traceability and Release Readiness
    Integrate the tutorial into the repo's broader proof and release surfaces
    rather than treating it as optional supporting material.

    [ ] 29.3.1 Task - Extend release and traceability surfaces for tutorials
    Ensure the tutorial is represented in conformance, governance, and release
    reviews.

      [ ] 29.3.1.1 Subtask - Add or update release-readiness checklists to include tutorial chapter completeness, checkpoint-app health, and maintained final-app health.
      [ ] 29.3.1.2 Subtask - Add traceability for the tutorial phases, chapter checkpoints, and the maintained final app so tutorial coverage is discoverable during review.
      [ ] 29.3.1.3 Subtask - Add governance checks that reject stale chapter links, partially removed checkpoints, or hidden divergence between the tutorial and the published docs.
      [ ] 29.3.1.4 Subtask - Define the maintenance policy for future widget or domain-scope additions so the tutorial evolves intentionally instead of accreting ad hoc chapters.

  [ ] 29.4 Section - Phase 29 Integration Tests
    Validate the published tutorial as one coherent product surface from public
    docs through runnable checkpoint apps.

    [ ] 29.4.1 Task - End-to-end tutorial scenarios
    Prove the tutorial can be trusted as a maintained teaching path.

      [ ] 29.4.1.1 Subtask - Verify every chapter document resolves to a valid checkpoint directory and that representative checkpoints across the series boot successfully.
      [ ] 29.4.1.2 Subtask - Verify the root tutorial landing page, chapter index, and maintained final app references remain synchronized.
      [ ] 29.4.1.3 Subtask - Verify tutorial governance fails clearly when a chapter, checkpoint, or final-app reference drifts apart.
      [ ] 29.4.1.4 Subtask - Verify the published tutorial still presents one coherent Operations Control Center story rather than disconnected per-widget exercises.
