# Maintainer Workflows

This guide is the operational checklist for changing `UnifiedUi` safely.

## Add a New Canonical Authored Construct

When adding a new canonical authored construct family:

1. Update the package specs under `.spec/specs/unified-ui`.
2. Extend the authored DSL entities and placement validation if needed.
3. Extend compiler lowering into canonical `UnifiedIUR`.
4. Update `UnifiedUi.Reference` and `UnifiedUi.Parity` if the canonical catalog changed.
5. Add or update a maintained example that proves the new authored surface.
6. Inspect compiled output with the package tooling.

Do not add runtime-local authoring concepts here. If a change needs renderer
knowledge to make sense, it belongs in a runtime package instead.

## Evaluate Signal Changes

When changing bindings or interactions:

1. Update or add an authored example that uses the signal change.
2. Inspect the signal summary:

```bash
mix unified_ui.inspect --example themed_signal_workspace --format signals
```

3. Confirm there are no renderer-local keys or semantics.
4. Confirm binding references, target bindings, and interaction families remain canonical.

## Evaluate Canonical Output Changes

When authored composition, theme, or signal changes affect compiled output:

1. Export a review-friendly snapshot:

```bash
mix unified_ui.export --example operations_dashboard --format snapshot
```

2. Compare the change against a maintained example or a previous reference
   module using `UnifiedUi.Tooling.diff_examples/2`.
3. Review the parity surface through `mix unified_ui.validate`.

## Runtime Impact Assessment

`UnifiedUi` does not implement `live_ui`, `elm_ui`, or `desktop_ui`, but
maintainers still need to think about them when the authored boundary changes.

When canonical constructs change, review:

- whether `UnifiedIUR` catalogs changed
- whether maintained examples cover the new authored surface
- whether signal meaning changed in a way runtime libraries must translate

The goal is not to implement the runtime packages here. The goal is to leave
the canonical boundary unambiguous for those downstream packages.

## Release-Readiness Pass

Before treating a `UnifiedUi` change as stable:

```bash
mix test
mix unified_ui.validate
```

If strict release-readiness is desired:

```bash
mix unified_ui.validate --strict
```

That workflow should only pass when examples, parity, signal coverage, and
documentation are all in a healthy state.
