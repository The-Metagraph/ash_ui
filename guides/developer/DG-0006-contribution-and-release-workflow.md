# DG-0006: Contribution and Release Workflow

---
id: DG-0006
title: Contribution and Release Workflow
audience: Framework Developers
status: Active
owners: Ash UI Team
last_reviewed: 2026-04-25
next_review: 2026-10-25
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
mix ash_ui.examples.validate
mix ash_ui.examples.report
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

## Example-Suite Change Workflow

Changes to `examples/` have an extra contract because the suite is both public
documentation and a maintained review surface.

When you add or update an example app:

1. preserve the sibling `unified_ui/examples` directory name as the stable
   review handle
2. choose the honest Ash UI canonical subject classification:
   `exact`, `normalized`, `composed`, or `custom`
3. author the app through one screen resource plus related element resources
4. keep bindings and actions on the resource that owns the visible interaction
5. vendor the shared Ash HQ shell locally through `assets/css/app.css`
6. update the root suite metadata and docs so discovery, preview, and report
   output stay synchronized

The suite is not allowed to fake parity by quietly renaming directories to the
current canonical Ash UI type. Stable directory parity matters for cross-package
review and migration notes even when Ash UI normalizes the authored subject.

## Example-Suite Theming and Review Rules

Every checked-in example app should preserve the normative shell documented in
[examples/ash_hq_theme_baseline.md](../../examples/ash_hq_theme_baseline.md):

- keep the shared dark slate backdrop, warm gradient accents, glass panels, and
  pill CTA language
- keep the three reviewer-visible zones: demo, `Meaningful Interaction Story`,
  and `Canonical Signal Preview`
- keep subject emphasis inside the shared shell rather than replacing the shell
  with a new visual system
- keep unsupported or partial surfaces called out explicitly in app-local docs
  and review metadata

## Future Widget Additions

When the sibling `unified_ui` package gains a new example directory, Ash UI
should either add the mirrored directory or document why parity is temporarily
blocked. The default maintenance path is:

1. add the directory to `examples/catalog.tsv`
2. classify the Ash UI canonical subject and support status
3. add the standalone example app and its phase definition
4. update root suite docs, metadata snapshots, and traceability
5. run the example-suite validation and representative integration coverage

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

- [examples/README.md](../../examples/README.md)
- [DG-0005: Testing, Conformance, and Governance](./DG-0005-testing-conformance-and-governance.md)
- [UG-0008: Migration from Older AshUI Models](../user/UG-0008-migration-from-older-ash-ui-models.md)
- [release/README.md](../../release/README.md)
- [phase-08-governance-gates-and-release-readiness.md](../../specs/planning/phase-08-governance-gates-and-release-readiness.md)
