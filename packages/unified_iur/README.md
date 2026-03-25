# UnifiedIUR

`UnifiedIUR` is the canonical intermediate representation package for the
unified ecosystem.

The package is intentionally a pure Elixir library. It defines the portable
canonical UI model that sits between authored `unified_ui` output and the
runtime-library packages that render or transport those values.

## What This Package Owns

`UnifiedIUR` owns renderer-independent data structures and maintainer-facing
reference surfaces for:

- the core canonical element and metadata model
- canonical widget, layout, layer, form, and canvas construct families
- styling, theming, token, binding, and interaction descriptors
- normalization and validation of portable canonical values
- interoperability helpers for runtime-library consumption
- reference fixtures, inspection helpers, export helpers, and package validation

This package does not own runtime rendering, event transport servers, Phoenix
integration, Elm state management, or desktop process lifecycles.

## Maintainer Workflows

The package includes three maintainer-facing Mix tasks:

- `mix unified_iur.inspect FIXTURE_ID --format report|tree|diagnostics|extensions`
- `mix unified_iur.export FIXTURE_ID --format fixture|snapshot|diagnostics`
- `mix unified_iur.validate --format summary|report [--strict]`

These commands are built to let maintainers inspect, export, validate, and
review canonical IUR without needing any runtime-library package.

## Reference Guides

Use the package guides for the canonical contract details:

- [Construct Families](guides/construct_families.md)
- [Core Model](guides/core_model.md)
- [Interoperability](guides/interoperability.md)
- [Maintainer Workflows](guides/maintainer_workflows.md)

## Release Readiness

The package treats reference fixtures, deterministic normalization, runtime
compatibility, and paired `unified_ui` parity as release gates rather than
optional documentation concerns. Run `mix unified_iur.validate --strict` before
promoting changes to the canonical IUR surface.
