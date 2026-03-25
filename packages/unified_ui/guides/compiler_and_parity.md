# Compiler and Parity

`UnifiedUi` is only useful if authored modules compile into stable canonical
`UnifiedIUR` and remain synchronized with the canonical construct catalogs.

## Compiler Model

The public compiler entrypoints live under `UnifiedUi.Compiler`:

- `compile/2` and `compile!/2`
- `iur/2` and `iur!/2`
- `summary/2`
- `listing/2`
- `inspection/2`
- `render_inspection/2`

These helpers lower authored modules into:

- canonical `UnifiedIUR` element trees
- compiled themes
- compiled bindings
- compiled interactions
- authored-to-compiled trace information

The compiler is expected to be deterministic. Equivalent repeated compilation of
the same module should produce the same canonical snapshot.

## Inspection Surface

Maintainers can inspect compiled output without any renderer runtime:

```bash
mix unified_ui.inspect --example operations_dashboard
mix unified_ui.export --example themed_signal_workspace --format snapshot
mix unified_ui.export --module UnifiedUi.Examples.ThemedSignalWorkspace --format signals
```

The inspection and export helpers are review-oriented. They exist so authored
changes can be assessed as canonical boundary changes before any runtime-library
implementation begins.

## Bilateral Parity

`UnifiedUi` must stay aligned with canonical `UnifiedIUR` catalogs. The parity
surface is maintained through `UnifiedUi.Parity` and checked by
`UnifiedUi.Tooling.validation_report/0`.

The parity workflow checks that:

- authored widget and construct families still map to canonical `UnifiedIUR`
- maintained examples compile and remain deterministic
- canonical obligations remain covered by the authored example catalog

If parity drifts, the package is no longer a trustworthy authored boundary.

## Review Expectations

When authored constructs change, maintainers should review:

- the compiled snapshot or inspection output of at least one maintained example
- the parity report against `UnifiedIUR`
- the signal summary if interactions or bindings changed

That keeps DSL changes grounded in canonical output rather than only in macro or
schema implementation details.
