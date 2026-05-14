# ElmUi

`elm_ui` is the web-target runtime library for the unified ecosystem. It
supports both direct-native authored screens and canonical `UnifiedIUR`
rendering through the same Phoenix-authoritative and Elm-realized runtime
boundary.

## Main Surfaces

- `ElmUi.Widgets`, `ElmUi.Layout`, and `ElmUi.Layer` expose the direct-native
  widget and composition surface.
- `ElmUi.Renderer` maps canonical `UnifiedIUR.Element` values into the same
  native widget model.
- `ElmUi.Runtime`, `ElmUi.ServerRuntime`, and `ElmUi.FrontendRuntime` provide
  the shared split-runtime path for native and canonical screens.
- `ElmUi.Style` and `ElmUi.Theme` define portable styling, theme tokens, and
  cross-runtime style continuity.
- `ElmUi.Inspect`, `ElmUi.Export`, `ElmUi.Validate`, `ElmUi.Reference`, and
  `ElmUi.Info` provide the maintainer tooling surface.

## Maintained Example Suites

`ElmUi.Examples` includes maintained:

- direct-native examples through `ElmUi.Examples.native_examples/0`
- canonical-rendered examples through `ElmUi.Examples.canonical_examples/0`
- mixed comparison and continuity artifacts through `ElmUi.Examples.mixed_examples/0`

Each example carries stable metadata, artifact names, parity obligations, and
coverage tags through `ElmUi.Examples.catalog/0`, `ElmUi.Examples.metadata/1`,
and `ElmUi.Examples.coverage_matrix/0`.

## Maintainer Workflow

Package-local checks:

- `mix deps.get`
- `mix compile`
- `mix test`
- `mix elm_ui.preview --format catalog`
- `mix elm_ui.inspect native_styling`
- `mix elm_ui.export styling_continuity --format comparison`
- `mix elm_ui.validate --strict`

Workspace checks:

- `mix spec.plancheck elm_ui`
- `mix spec.compliance elm_ui`

Maintainer helper modules:

- `ElmUi.Inspect.preview/1`
- `ElmUi.Export.artifact/1`
- `ElmUi.Validate.release_readiness/1`
- `ElmUi.Reference.package_reference/0`
- `ElmUi.Info.package_summary/0`

## Guides

- `guides/runtime_backbone.md`
- `guides/native_runtime_and_examples.md`
- `guides/canonical_rendering_and_transport.md`
- `guides/styling_and_inspection.md`
- `guides/maintainer_workflows.md`
