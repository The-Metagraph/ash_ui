# Maintainer Workflows

This guide covers the repeatable maintainer workflow for evolving `LiveUi`.

## Daily Package Review Workflow

1. Start from the same focused example ids that the repository `examples/` suite exposes publicly.
2. Review native runtime output with `mix live_ui.preview button --format html`.
3. Inspect native and canonical behavior for the same id with `mix live_ui.inspect button --format comparison`.
4. Export diagnostics on the same id with `mix live_ui.export button --format diagnostics`.
5. Run `mix live_ui.validate` to review coverage, continuity, transport, and authority status.
6. Run `mix live_ui.validate --strict` before treating a runtime-boundary change as release ready.

## Adding a New Native Widget Family

When adding a new native widget family:

1. add the native widget component and tests
2. add or update the aligned focused example with the same widget-focused id used by the repository suite
3. add the canonical renderer mapping if the construct is part of canonical `UnifiedIUR`
4. add or update canonical review coverage on that same example id when native/canonical behavior should stay aligned
5. rerun `mix live_ui.validate --strict`

## Reviewing Boundary Changes

When a change affects transport or canonical rendering:

1. inspect the affected aligned example id with `mix live_ui.inspect ... --format comparison`
2. export diagnostics output for that same aligned example id
3. confirm local-only flows remain local where intended
4. confirm boundary-safe flows still produce canonical `Jido.Signal` values
5. confirm the release-readiness report still passes in strict mode

## Compatibility Questions

Before merging a package-boundary change, review:

- whether a native widget change also needs a canonical renderer update
- whether a transport change alters canonical event meaning
- whether the same aligned example id now reports drift between native and canonical behavior
- whether the package docs still describe the maintained workflow accurately
