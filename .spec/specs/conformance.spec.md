# Conformance Governance

Guide governance, explicit traceability documents, and the conformance harness that keeps Ash UI specs, guides, and tagged tests aligned.

## Intent

Define the repository-level governance boundary for guide metadata, requirement and scenario traceability, and generated conformance reporting.

```spec-meta
id: ash_ui.conformance
kind: policy
status: active
summary: Maintains guide governance, requirement and scenario traceability, and the conformance harness/reporting workflow.
surface:
  - guides/README.md
  - guides/developer/README.md
  - guides/developer/DG-0005-testing-conformance-and-governance.md
  - guides/developer/DG-0006-contribution-and-release-workflow.md
  - guides/user/README.md
  - guides/contracts/guide_contract.md
  - guides/contracts/guide_traceability_contract.md
  - guides/conformance/guide_conformance_matrix.md
  - guides/conformance/guide_scenario_catalog.md
  - guides/templates/user-guide-template.md
  - guides/templates/developer-guide-template.md
  - specs/conformance/scenario_catalog.md
  - specs/conformance/spec_conformance_matrix.md
  - specs/conformance/scenario_test_matrix.md
  - scripts/validate_authoring_governance.sh
  - scripts/validate_guides_governance.sh
  - scripts/run_conformance.sh
  - scripts/generate_conformance_report.sh
```

## Requirements

```spec-requirements
- id: ash_ui.conformance.spec_traceability
  statement: The repository shall maintain explicit conformance traceability from contract REQ entries to SCN scenarios to conformance-tagged test files through the spec conformance matrix, scenario catalog, and scenario test matrix.
  priority: must
  stability: stable
- id: ash_ui.conformance.guide_governance
  statement: The guides workspace shall preserve the required guide directories, indexes, templates, contracts, conformance documents, and per-guide metadata and section conventions so published UG and DG guides remain discoverable and traceable.
  priority: must
  stability: evolving
- id: ash_ui.conformance.harness_and_reporting
  statement: Governance scripts shall validate public authoring and guide policy, run the conformance-tagged test harness, and generate reports summarizing matrix, catalog, traceability, and tagged-test coverage.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: command
  target: mix test test/ash_ui/conformance_traceability_test.exs test/ash_ui/phase_8_integration_test.exs
  execute: true
  covers:
    - ash_ui.conformance.spec_traceability
    - ash_ui.conformance.harness_and_reporting
- kind: command
  target: bash ./scripts/validate_guides_governance.sh
  execute: true
  covers:
    - ash_ui.conformance.guide_governance
    - ash_ui.conformance.harness_and_reporting
```
