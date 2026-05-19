# ADR-0009: Canonical Workflow Progress And Status Component Adoption

## Status

Accepted for planning.

This decision is implemented by the public architecture record
`specs/adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md`,
the contract
`specs/contracts/canonical_workflow_progress_status_component_contract.md`, and
Phase 33.

## Context

PR #123 proposes `repo_progress_card` as a reusable widget for repository
progress, activity, blockers, and dependency state. The current branch is a
draft and conflicts with main, and its implementation mixes canonical package
changes with LiveView-specific event transport and app-specific map-surface
language.

The component affects multiple package boundaries: Unified UI catalog metadata,
Unified IUR constructors and validation, Live UI widget discovery and native
rendering, Ash UI canonical conversion, and renderer fallback behavior.

## Decision

Ash UI will land `repo_progress_card` only as a first-class canonical
`:workflow_progress_and_status` component.

The canonical contract must:

- use `repo_progress_card` as the canonical kind;
- use `:workflow_progress_and_status` consistently across Unified UI,
  Unified IUR, Live UI, and Ash UI;
- represent repository status, progress, counts, dependencies, and optional
  actions as structured canonical attributes;
- keep LiveView event names, `phx-*` fields, routes, helpers, runtime modules,
  app map placement, and concrete CSS out of canonical data;
- model dependency edges as ordered descriptors, with optional semantic
  interactions per edge;
- omit unavailable actions instead of using `nil` as an action visibility
  state;
- require Unified IUR validation and package-boundary drift tests before Ash UI
  marks the kind supported.

## Consequences

PR #123 cannot land as-is. It must be rebased onto current main, scope-cleaned,
and realigned with the canonical workflow progress and status contract before
implementation is considered complete.

The accepted implementation path is Phase 33.

## Related

- `specs/adr/ADR-0009-canonical-workflow-progress-status-component-adoption.md`
- `specs/contracts/canonical_workflow_progress_status_component_contract.md`
- `specs/planning/phase-33-canonical-workflow-progress-status-component-adoption.md`
- `.spec/specs/canonical_workflow_progress_status.spec.md`
