# Repository Governance

Ash UI uses Spec Led Development for current-truth architecture governance while
keeping public docs and examples aligned with the resource-first model.

## Intent

Capture the repository-level governance contract that replaces the older
`specs/` directory and keeps validation, release checks, and public docs aligned
with current code.

```spec-meta
id: ashui.governance
kind: policy
status: active
summary: Repository governance uses the .spec workspace, validates it through Spec Led tooling, and keeps public docs/examples aligned with the resource-first architecture.
surface:
  - .spec/README.md
  - .spec/specs/*.spec.md
  - .spec/decisions/*.md
  - scripts/validate_specs_governance.sh
  - scripts/validate_authoring_governance.sh
  - scripts/run_conformance.sh
  - scripts/generate_conformance_report.sh
  - .github/workflows/specs-governance.yml
  - .github/workflows/ci.yml
  - release/RELEASE_CHECKLIST.md
decisions:
  - ashui.decision.control_plane_authority
  - ashui.decision.element_resource_authority
```

## Requirements

```spec-requirements
- id: ashui.governance.specled_workspace
  statement: The repository shall keep current architectural truth in .spec/specs/*.spec.md and durable ADRs in .spec/decisions/*.md instead of the removed top-level specs/ tree.
  priority: must
  stability: stable
- id: ashui.governance.validation_entrypoint
  statement: Repository governance validation shall use Spec Led tooling to validate the .spec workspace and write .spec/state.json.
  priority: must
  stability: stable
- id: ashui.governance.resource_first_public_surface
  statement: Public docs and examples shall present resource-first authoring as the default model and confine historical document-first references to explicitly approved historical materials.
  priority: must
  stability: stable
- id: ashui.governance.release_and_conformance_reporting
  statement: Release and conformance automation shall report against the current .spec workspace rather than the removed specs/ matrices.
  priority: should
  stability: evolving
```

## Verification

```spec-verification
- kind: command
  target: >-
    rg -n "\.spec/|mix spec\.validate|mix spec\.check|state\.json" .spec scripts/validate_specs_governance.sh .github/workflows/specs-governance.yml .github/workflows/ci.yml
  covers:
    - ashui.governance.specled_workspace
    - ashui.governance.validation_entrypoint
- kind: command
  target: >-
    rg -n "AshUI\.Resource\.DSL\.Screen|AshUI\.Resource\.DSL\.Element|ui_relationships|ui_bindings|ui_actions" README.md guides examples scripts/validate_authoring_governance.sh release/RELEASE_CHECKLIST.md
  covers:
    - ashui.governance.resource_first_public_surface
- kind: command
  target: >-
    rg -n "\.spec/README\.md|\.spec/specs|\.spec/state\.json|Conformance Report" scripts/run_conformance.sh scripts/generate_conformance_report.sh release/RELEASE_CHECKLIST.md
  covers:
    - ashui.governance.release_and_conformance_reporting
- kind: command
  target: bash ./scripts/validate_specs_governance.sh
  covers:
    - ashui.governance.validation_entrypoint
```
