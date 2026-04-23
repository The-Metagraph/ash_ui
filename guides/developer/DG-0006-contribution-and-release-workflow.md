# DG-0006: Contribution and Release Workflow

---
id: DG-0006
title: Contribution and Release Workflow
audience: Framework Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-23
next_review: 2026-10-23
related_reqs: [REQ-FRAMEWORK-001, REQ-COMP-001, REQ-OBS-001]
related_scns: [SCN-041, SCN-061, SCN-101]
related_guides: [DG-0001, DG-0005, UG-0008]
diagram_required: false
---

## Overview

This guide explains how to package a coherent AshUI change from first inspection
through release-readiness. It combines the practical contributor workflow with
the checks expected before a release candidate or externally visible change is
treated as complete.

## Prerequisites

Before reading this guide, you should:

- Have contributor access to the repository.
- Understand the main subsystem you are changing.
- Have read [DG-0005](./DG-0005-testing-conformance-and-governance.md).

## Normal Change Workflow

The usual loop is:

1. inspect the relevant modules, tests, guides, and specs
2. make the smallest coherent implementation change
3. run the smallest focused verification that proves the change
4. update docs, specs, or conformance material if the public or internal contract moved
5. check for stale paths or renamed files before finishing

Useful baseline commands:

```bash
mix test test/ash_ui/compiler_test.exs
mix test test/ash_ui/liveview/liveview_integration_test.exs
bash ./scripts/validate_guides_governance.sh
mix spec.validate
```

## Expectations for a Good Change

- one clear purpose
- one coherent verification story
- docs that describe current behavior honestly
- no stale references to removed files or superseded public guidance

If a change touches a cross-cutting internal boundary, expect to update more
than code. In this repo that often includes:

- user guides
- developer guides
- `.spec/specs/*.spec.md`
- README or conformance documents

## PR and Commit Shape

AshUI reviews cleanly when changes are grouped by one boundary at a time:

- one subsystem fix
- one guide rewrite
- one conformance or governance cleanup

Avoid bundling unrelated build output, cache files, or exploratory edits with
the logical change.

## Release-Readiness Expectations

Before release:

- guide indexes must match the actual guide files
- conformance and governance checks must pass
- README and guide language must describe the current architecture
- release notes must call out renderer fallback behavior or hard boundary changes when relevant
- migration guidance must exist for breaking public changes

If a full validation sweep is blocked, document exactly which focused suites
passed and what remains noisy or unavailable.

## Historical Authoring Material

Historical authoring material belongs only in the dedicated migration guidance
or other explicit historical records. New feature work, examples, and mainline
docs should continue to teach the current resource-first model.

## See Also

- [DG-0005: Testing, Conformance, and Governance](./DG-0005-testing-conformance-and-governance.md)
- [UG-0008: Migration from Older AshUI Models](../user/UG-0008-migration-from-older-ash-ui-models.md)
- [release/README.md](../../release/README.md)
- [phase-08-governance-gates-and-release-readiness.md](../../specs/planning/phase-08-governance-gates-and-release-readiness.md)
