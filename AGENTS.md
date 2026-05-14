# Ash UI Agent Guide

Use this guide for repository-wide work. The package-local Spec Led Development
workspace in `.spec/` is the current-truth source for intent, requirements, and
verification targets.

## First Read

1. Read `.spec/README.md`.
2. Read `.spec/AGENTS.md` before editing `.spec/`.
3. Read the subject specs under `.spec/specs/` that match the files you are
   changing.
4. Read `README.md` for the public package shape.
5. For example-suite work, also read `examples/README.md`,
   `examples/scaffold_contract.md`, and `examples/ash_hq_theme_baseline.md`.

## Project Shape

- Ash UI is resource-first. Screen and element Ash resources using
  `AshUI.Resource.DSL.Screen` and `AshUI.Resource.DSL.Element` are the
  authoritative authoring units.
- `AshUI.Resource.Authority` derives and persists the `Screen.unified_dsl`
  snapshot from the resource graph. Do not ask applications to hand-author
  runtime snapshots when resource authority can produce them.
- Relationships define UI composition. Preserve relationship order, kind, slot,
  placement, inline fragments, and screen-scoped bindings.
- `AshUI.Compiler` compiles persisted screens and resource-authority payloads to
  `AshUI.Compilation.IUR`; `AshUI.Rendering.IURAdapter` converts internal IUR to
  `%UnifiedIUR.Element{}` canonical renderer-facing IUR.
- Navigation intent is semantic and host-independent. Resource-authored
  `navigation` declarations may use symbolic screens, destinations, modals,
  params, metadata, payload mappings, and binding refs, but must not include
  route/path/URL/helper/module/runtime stack fields.
- Styling intent is semantic. Resources may declare class hooks, variants,
  renderer-read props, and dynamic inline style values; host apps own concrete
  theme tokens, CSS, shell treatment, and responsive layout.
- Runtime work is actor-aware. Binding evaluation, LiveView events, screen
  mounts, actions, and resource access must pass through the authorization and
  policy surfaces when applicable.
- Legacy builder/document support is migration-only. Do not reopen builder-first
  or document-first payloads as supported runtime compiler inputs.

## Spec Led Workflow

- At session start, try `mix spec.prime --base HEAD`.
- After code, docs, or tests change, try `mix spec.next`; use
  `mix spec.next --bugfix` for bug fixes.
- If `mix spec.next` reports subject updates, update the named
  `.spec/specs/*.spec.md` file before finishing.
- When the spec loop says ready, run `mix spec.check --base HEAD` or the base
  requested by the task.
- In this checkout, the `spec.*` Mix tasks may not be wired into `mix.exs`. If a
  spec task is unavailable, record that fact in your handoff and run the
  closest targeted verification from the relevant spec instead.
- Keep `.spec` files as current-state documents. Use Git history and PRs for the
  change log.

## Implementation Rules

- Prefer existing `AshUI.Resource.DSL.*`, `AshUI.Resource.Info`,
  `AshUI.Resource.Authority`, `AshUI.Config`, runtime, compiler, rendering, and
  telemetry modules over new parallel abstractions.
- Keep storage boundaries configurable through `AshUI.Config`; do not hard-code
  the default domain, resources, repo, or runtime domain into shared logic.
- Keep bindings typed as value, list, or action flows with structured source
  maps and explicit targets. Preserve transform, bidirectional write, list
  paging/update, and action execution semantics.
- Preserve renderer selection semantics: registry availability is not the same
  as adapter fallback renderability.
- Preserve canonical navigation transport. Use `AshUI.Navigation.Intent`,
  `AshUI.Rendering.CanonicalIUR`, and `AshUI.Runtime.Navigation` instead of
  adding route-specific or renderer-specific navigation fields to resources.
- Emit or preserve canonical `ash_ui` telemetry events for authoring, screen,
  binding, compilation, rendering, authorization, and migration flows when those
  paths change.
- Return structured errors for authorization, compilation, binding, rendering,
  and LiveView runtime failures rather than crashing sessions.

## Example Suite Rules

- Every checked-in example under `examples/<directory>/` is a standalone Mix
  project.
- Preserve sibling `unified_ui/examples` directory names as stable review
  handles, even when Ash UI normalizes the canonical subject type.
- Author examples as one screen resource plus related element resources, with
  app-local UI storage resources and persistence through
  `AshUI.Resource.Authority.create/2`.
- Keep the shared Ash HQ baseline in sync across `examples/ash_hq_theme_*` and
  app-local shell hooks.
- Every example must expose a reviewer-visible Meaningful Interaction Story and
  Canonical Signal Preview.

## Verification

- Use the exact targeted `mix test ...` commands listed in the relevant
  `.spec/specs/*.spec.md` verification block when behavior changes.
- Useful root commands include `mix test`, `mix format --check-formatted`,
  `mix ash_ui.examples.validate`, `mix ash_ui.examples.report`, and
  `bash ./scripts/validate_specs_governance.sh`.
- For example review workflows, use `mix ash_ui.examples.list`,
  `mix ash_ui.examples.preview <directory>`, and
  `mix ash_ui.examples.start <directory> --dry-run`.
- Treat generated `_build/`, `deps/`, tutorial dependency, and report artifacts
  as unrelated unless the task explicitly targets them.
