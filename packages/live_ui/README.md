# LiveUi

`LiveUi` is the Phoenix LiveView runtime library for the unified ecosystem.

The package has two equally important roles:

- it is a directly usable native LiveView widget/runtime library
- it is the canonical `UnifiedIUR` renderer and boundary-transport layer for the LiveView runtime

`LiveUi` does not own the authored DSL or the canonical IUR data model. It owns
the server-authoritative runtime behavior that turns native screens and
canonical IUR values into one coherent LiveView-facing runtime.

## What This Package Owns

`LiveUi` owns:

- native widget, form, layout, overlay, display, and operational component families
- the shared server-authoritative runtime used for both native screens and canonical IUR rendering
- canonical `UnifiedIUR` rendering through native widget reuse instead of a second renderer stack
- canonical boundary transport via `Jido.Signal` and channel-safe translation helpers
- package-specialized `live_ui` screens that mirror the repository widget-focused example inventory one for one
- maintainer-facing preview, inspection, export, and validation workflows

`LiveUi` does not own:

- the authored `unified_ui` DSL
- the canonical `unified_iur` construct model
- client-side Elm state management
- desktop-native process lifecycles

## Maintainer Workflows

The package includes four maintainer-facing Mix tasks:

- `mix live_ui.preview [EXAMPLE_ID] [--format report|html|metadata]`
- `mix live_ui.inspect [EXAMPLE_ID] [--format report|metadata|comparison|diagnostics|catalog]`
- `mix live_ui.export [EXAMPLE_ID] [--format metadata|report|html|comparison|diagnostics|catalog]`
- `mix live_ui.validate [--format summary|report] [--strict]`

Use these commands to:

- preview the same focused example ids that the repository `examples/` suite exposes publicly
- inspect how native and canonical flows map onto the same runtime for the same focused example id
- export review-friendly metadata, snapshots, comparisons, and diagnostics
- validate one-for-one inventory coverage, continuity, transport, runtime authority, and documentation readiness

The package review story is anchored to the same focused example ids as the root suite. `live_ui` specializes those ids with native screens instead of maintaining a second catalog.

Common entry points:

```bash
cd /Users/Pascal/code/unified/packages/live_ui
mix deps.get
mix live_ui.preview button --format html
mix live_ui.inspect button --format comparison
mix live_ui.export button --format diagnostics
```

Canonical review, transport inspection, and continuity comparison stay attached to those same focused example ids instead of living in separate native/canonical/mixed lanes.

The aligned focused example story covers the whole widget inventory. For example, `button`, `table`, `tabs`, and `tree_view` all resolve to package-local native `live_ui` screens, and the canonical review path stays available on the same focused example ids where package validation requires it.

Before promoting runtime-boundary changes, run:

```bash
mix live_ui.validate --strict
```

## Reference Guides

Use the package guides for the package contract details:

- [Runtime Backbone](guides/runtime_backbone.md)
- [Native Runtime and Examples](guides/native_runtime_and_examples.md)
- [Canonical Rendering and Transport](guides/canonical_rendering_and_transport.md)
- [Maintainer Workflows](guides/maintainer_workflows.md)

## Release Readiness

`LiveUi` treats aligned example health, repository-inventory coverage, styled
continuity alignment, boundary transport soundness, server-authoritative runtime
behavior, and maintainer documentation as release-readiness criteria. Run
`mix live_ui.validate --strict` before promoting runtime-boundary changes.
