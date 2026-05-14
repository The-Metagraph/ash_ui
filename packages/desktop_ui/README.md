# DesktopUi

`desktop_ui` is the desktop-target runtime library for the unified ecosystem.
It supports both direct-native desktop screens and canonical `UnifiedIUR`
rendering through one shared SDL3-oriented runtime boundary.

## Main Surfaces

- `DesktopUi.Widgets` exposes the direct-native widget surface.
- `DesktopUi.Runtime` defines the shared desktop runtime boundary used by both
  native and canonical entry paths.
- `DesktopUi.Platform` and `DesktopUi.Artifacts` expose bounded target
  variation and explicit platform packaging workflows.
- `DesktopUi.Renderer` defines the canonical renderer entrypoint.
- `DesktopUi.Transport` defines normalized local input and canonical boundary
  translation.
- `DesktopUi.Style`, `DesktopUi.Theme`, `DesktopUi.Inspection`, and
  `DesktopUi.Continuity` expose style realization and review surfaces.
- `DesktopUi.Examples`, `DesktopUi.Inspect`, `DesktopUi.Validate`,
  `DesktopUi.Reference`, and `DesktopUi.Info` provide the maintained example,
  inspection, validation, and summary helpers maintainers use day to day.

## Shared Runtime Model

`desktop_ui` does not own the authored DSL or canonical IUR definitions.
Instead, it consumes canonical `UnifiedIUR`, realizes that meaning through
native desktop widgets, and translates cross-package event meaning at the
desktop runtime boundary.

Both entry paths stay inside one package:

- direct-native `DesktopUi.Widgets` screens mount through `DesktopUi.Runtime`
- canonical `UnifiedIUR` trees render through `DesktopUi.Renderer` and then
  mount through the same `DesktopUi.Runtime`
- style resolution, platform integration, artifact policy, transport
  translation, and continuity diagnostics stay shared across both paths

## Platform And Artifact Policy

`desktop_ui` treats Windows, macOS, and Linux as first-class targets, but keeps
their differences explicitly bounded:

- platform modules may vary in window chrome, menu shape, shortcut scope, and
  notification style
- shared runtime, widget, renderer, style, and transport semantics must remain
  common
- build and packaging workflows are explicit in `DesktopUi.Artifacts` and do
  not redefine runtime behavior

## Maintained Example Workflows

The package ships paired maintained examples for:

- foundational desktop flows
- advanced layered and multiwindow flows
- transport and normalized-input review
- styled review and style continuity
- screen navigation, including independent modal stack review

Desktop modal navigation is managed by `DesktopUi.Navigation.Controller`, not by
host routes. Opening a modal pushes onto the modal stack, targetless close pops
the top modal, and targeted close removes a matching symbolic modal while
preserving the main screen history and forward stacks.

Use the example helpers directly:

- `DesktopUi.Examples.catalog/0`
- `DesktopUi.Examples.metadata/1`
- `DesktopUi.Examples.coverage_matrix/0`
- `DesktopUi.Reference.example_summary/0`

## Maintainer Workflow

Package-local checks:

- `mix deps.get`
- `mix compile`
- `mix test`
- `mix desktop_ui.inspect --format catalog`
- `mix desktop_ui.inspect native_styled_review --format diagnostics`
- `mix desktop_ui.build_host --dry-run`
- `mix desktop_ui.build_host`
- `mix desktop_ui.build --target linux --dry-run`
- `mix desktop_ui.build --target linux`
- `mix desktop_ui.package --target linux --dry-run`
- `mix desktop_ui.package --target linux`
- `mix desktop_ui.run --format catalog`
- `mix desktop_ui.run native_foundational --format summary`
- `mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000`
- `mix desktop_ui.validate`
- `mix desktop_ui.validate --format report`
- `mix desktop_ui.validate --strict`

Workspace checks:

- `mix spec.plancheck desktop_ui`
- `mix spec.traceability.generate desktop_ui`

## SDL3 Native Execution Notes

`desktop_ui` now has two bounded execution paths:

- compiled SDL3 visible-window execution through the native host executable
- explicit Elixir-host fallback through the framed protocol seam

Use these commands from `packages/desktop_ui`:

- `mix desktop_ui.build_host --dry-run` to inspect compiler and SDL3 dependency state
- `mix desktop_ui.build_host` to build the native executable when SDL3 is available
- `mix desktop_ui.build --target linux --dry-run` to inspect staged target output readiness
- `mix desktop_ui.package --target linux --dry-run` to inspect packaging output and fallback warnings
- `mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000` to prefer the real visible SDL3 window path
- `mix desktop_ui.run native_foundational --backend fallback` to force the protocol fallback host

The run surface reports:

- whether the compiled visible runner is ready
- whether protocol-style compiled launch is ready yet
- whether the current execution achieved widget-complete interactive native rendering or explicit fallback review
- how many interaction events were observed during the current compiled visible run
- whether text and image companion-library support is native-backed or falling back
- whether staged build and packaged target artifacts are compiled-host-ready or review-only
- whether the current execution used a real visible window or the bounded fallback host

Text and image companion libraries remain optional in this phase. Missing
`SDL3_ttf` or `SDL3_image` should produce explicit diagnostics and bounded
fallback behavior, not hidden failure.

On SDL3-ready maintainer machines, the normal manual review loop is:

- `mix desktop_ui.build_host`
- `mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_transport_review --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000`

That review loop is expected to exercise widget-complete native rendering,
native text and image realization, keyboard and pointer interaction, and
multiwindow or overlay behavior. When SDL3 is unavailable, the fallback host
path should stay explicit rather than pretending the same visible runtime is
active.

## Guides

- [Runtime Backbone](guides/runtime_backbone.md)
- [Native Runtime And Examples](guides/native_runtime_and_examples.md)
- [Canonical Rendering And Transport](guides/canonical_rendering_and_transport.md)
- [Styling, Platforms, And Artifacts](guides/styling_platforms_and_artifacts.md)
- [Maintainer Workflows](guides/maintainer_workflows.md)

## Release Readiness

Treat these as the normal release-readiness loop:

- `mix desktop_ui.validate --strict`
- `mix spec.traceability.generate desktop_ui`
- `mix spec.plancheck desktop_ui`

That loop keeps example coverage, shared runtime behavior, transport
translation, documentation, traceability, and artifact policy aligned before
the package evolves further.

`desktop_ui` does not own authored `UnifiedUi` contracts or canonical
`UnifiedIUR` definitions. When those upstream contracts change, the expected
follow-up here is to update `desktop_ui` planning, renderer/runtime behavior,
docs, and validation together rather than letting the runtime drift.
