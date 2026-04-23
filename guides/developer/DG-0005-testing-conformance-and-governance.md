# DG-0005: Testing, Conformance, and Governance

---
id: DG-0005
title: Testing, Conformance, and Governance
audience: Framework Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-COMP-001, REQ-BIND-010, REQ-RENDER-012, REQ-AUTH-012, REQ-OBS-001]
related_scns: [SCN-041, SCN-061, SCN-081, SCN-101]
related_guides: [DG-0001, DG-0003, DG-0004, DG-0006, UG-0004]
diagram_required: false
---

## Overview

This guide explains how AshUI validates changes locally: test layers, reusable
fixtures, guide/spec governance, and the Spec Led workflow used in this repo.
It replaces the older split between a narrow testing guide and an implicit
governance checklist.

## Prerequisites

Before reading this guide, you should:

- Know which subsystem you are changing.
- Be comfortable with focused `mix test` commands.
- Have read [DG-0001](./DG-0001-architecture-and-control-planes.md).

## Test Layers

The test suite is organized by subsystem:

- `test/ash_ui/resources/` for resource behavior and validations
- `test/ash_ui/compiler*` and `test/ash_ui/dsl*` for compilation and authoring
- `test/ash_ui/liveview/` for mount, event, hook, and update flows
- `test/ash_ui/runtime/` for bindings and actions
- `test/ash_ui/rendering/` for canonical conversion and adapter output
- `test/ash_ui/authorization/` for policy and runtime enforcement
- `test/ash_ui/*phase*_integration_test.exs` for phase and cross-subsystem integration
- `test/ash_ui/conformance_traceability_test.exs` for repo traceability checks

## Shared Test Harness

High-signal support modules live under `test/support/`.

The main fixture families are:

- `data_case.ex` for repo-backed tests
- `resource_authority_modules.ex` for authored screen and element resource fixtures
- `runtime_test_resources.ex` for runtime-domain and binding scenarios
- `screen_document_fixtures.ex` for persisted screen payload helpers
- `ui_storage_test_resources.ex` for configurable storage boundary tests
- `unified_ui_authoring_modules.ex` for broader authoring fixture coverage

If a change needs several copy-pasted setup blocks, there is usually a support
module that should be extended instead.

## Focused Verification Strategy

Start with the smallest slice that matches the change:

```bash
mix test test/ash_ui/compiler_test.exs
mix test test/ash_ui/liveview/liveview_integration_test.exs
mix test test/ash_ui/runtime/action_binding_test.exs
mix test test/ash_ui/rendering/live_ui_adapter_test.exs
mix test test/ash_ui/authorization/runtime_test.exs
```

Then add the smallest integration proof that crosses the changed boundary.

## Governance Validation

When you touch docs, specs, or conformance material, also run:

```bash
bash ./scripts/validate_guides_governance.sh
mix spec.next
mix spec.validate
mix spec.status --no-run-commands
```

And if the branch is ready for the stricter Spec Led check:

```bash
mix spec.check --base HEAD
```

## How to Read `mix spec.next`

- `needs subject updates` means the current-truth `.spec/specs/*.spec.md` files are stale
- `needs decision update` means the branch may have changed a durable cross-cutting rule
- `ready for check` means the current subject and decision layer is aligned enough to run `mix spec.check`

Do not treat `.spec` as optional paperwork. In this repo it is part of the
working definition of done for cross-cutting changes.

## Common Pitfalls

### Shared ETS state

Compiler and authorization caches use ETS. Tests that manipulate global cache
state should avoid `async: true` unless isolation is explicit.

### Storage-backend confusion

Some tests exercise the default Postgres-backed storage boundary while others
use ETS-backed authoring or runtime resources. Confirm which side you are
actually changing before trusting a passing test.

### Docs without traceability updates

Guide or spec changes are incomplete if the indexes, conformance matrix, or
relevant `.spec` surfaces still point to removed files.

## See Also

- [DG-0004: Runtime, Bindings, and Authorization](./DG-0004-runtime-bindings-and-authorization.md)
- [DG-0006: Contribution and Release Workflow](./DG-0006-contribution-and-release-workflow.md)
- [UG-0004: Bindings, Actions, and Forms](../user/UG-0004-bindings-actions-and-forms.md)
- [spec_conformance_matrix.md](../../specs/conformance/spec_conformance_matrix.md)
