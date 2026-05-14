# Styling And Inspection

`elm_ui` keeps theme meaning and style resolution server-authoritative while
still producing deterministic browser-facing realization.

## Styling Surface

- `ElmUi.Style`
  - style primitives
  - widget style hooks
  - state variants
- `ElmUi.Theme`
  - theme catalogs
  - token resolution
  - continuity rules

## Cross-Runtime Styling

- `ElmUi.ServerRuntime.StyleResolver` computes resolved style meaning.
- `ElmUi.FrontendRuntime.StyleRealization` computes browser-facing class,
  variable, transition, and responsive payloads.

## Inspection And Continuity

- `ElmUi.Inspection.runtime_snapshot/2` exposes server and frontend style state.
- `ElmUi.Continuity.compare/3` compares native and canonical runtime behavior.
- `ElmUi.Examples.styling_comparison/0` provides a maintained styling-heavy
  review artifact.

Use these when reviewing:

- unresolved theme tokens
- invalid state-variant wiring
- incompatible style combinations
- theme propagation drift
- frontend realization drift
