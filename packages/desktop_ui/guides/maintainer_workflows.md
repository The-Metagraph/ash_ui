# Maintainer Workflows

Run package-local checks from `packages/desktop_ui`:

```bash
mix deps.get
mix compile
mix test
mix desktop_ui.inspect --format catalog
mix desktop_ui.inspect native_styled_review --format diagnostics
mix desktop_ui.inspect native_foundational --format host
mix desktop_ui.build --target linux --dry-run
mix desktop_ui.build --target linux
mix desktop_ui.package --target linux --dry-run
mix desktop_ui.package --target linux
mix desktop_ui.build_host --dry-run
mix desktop_ui.build_host
mix desktop_ui.run --format catalog
mix desktop_ui.run native_foundational --format summary
mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000
mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000
mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000
mix desktop_ui.run native_foundational --backend fallback
mix desktop_ui.validate
mix desktop_ui.validate --format report
mix desktop_ui.validate --strict
```

Run the current workspace planning check from the repository root:

```bash
mix spec.traceability.generate desktop_ui
mix spec.plancheck desktop_ui
```

Useful helper surfaces while working:

- `DesktopUi.Examples.catalog/0`
- `DesktopUi.Reference.package_reference/0`
- `DesktopUi.Reference.example_summary/0`
- `DesktopUi.Reference.transport_summary/0`
- `DesktopUi.Reference.style_summary/0`
- `DesktopUi.Reference.artifact_summary/0`
- `DesktopUi.Inspect.host_execution/1`
- `DesktopUi.Package.diagnostics/0`
- `DesktopUi.Tooling.run_catalog/0`
- `DesktopUi.Validate.validation_report/0`

Treat `mix desktop_ui.validate --strict` as the package release-readiness gate
for day-to-day maintenance.

## Host Execution Notes

- `mix desktop_ui.run` now chooses between the compiled visible SDL3 runner and
  the explicit Elixir-host fallback.
- `mix desktop_ui.build` stages a per-target reviewable build directory before
  packaging.
- `mix desktop_ui.package` turns the staged target output into an archive or
  bundle surface while keeping fallback-only warnings explicit.
- `mix desktop_ui.build_host --dry-run` is the fastest way to see whether the
  current machine can compile and run the native host.
- `mix desktop_ui.inspect ... --format host` still reports the protocol-host
  execution seam directly.
- text and image support remain bounded when SDL3 companion libraries are
  missing; the run and validation surfaces report that state explicitly.
- compiled visible SDL3 execution is now expected to be widget-complete and
  interactive for the maintained examples on SDL3-ready machines.
- the run surface now distinguishes widget-complete interactive execution from
  the bounded fallback review path and reports interaction-event diagnostics.

## Manual SDL3 Review Loop

On SDL3-ready maintainer machines, use this review loop from
`packages/desktop_ui`:

- `mix desktop_ui.build_host`
- `mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_transport_review --backend compiled --linger-ms 3000`
- `mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000`

During that loop, review:

- visible widget completeness rather than placeholder geometry
- native text and image realization diagnostics
- keyboard focus movement, command activation, scrolling, and pointer behavior
- dialog, context-menu, and multiwindow transitions

## Evolution Guardrails

Keep these guardrails explicit when the package changes:

- `desktop_ui` does not own authored `UnifiedUi` or canonical `UnifiedIUR`
  definitions.
- Changes to widgets, renderer behavior, platform integration, or transport
  should move with maintained examples, validation, docs, and traceability.
- Root ecosystem subjects in `.spec/specs/architecture.spec.md`,
  `.spec/specs/platform_runtimes.spec.md`, and
  `.spec/specs/signal_transport.spec.md` are part of the package review
  surface, not optional background reading.
