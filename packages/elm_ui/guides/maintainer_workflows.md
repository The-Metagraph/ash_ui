# Maintainer Workflows

`elm_ui` treats examples, tooling, and documentation as release surfaces.

## Package Commands

- `mix deps.get`
- `mix compile`
- `mix test`
- `mix elm_ui.preview --format catalog`
- `mix elm_ui.inspect native_styling`
- `mix elm_ui.export styling_continuity --format comparison`
- `mix elm_ui.validate --strict`

## Workspace Commands

- `mix spec.plancheck elm_ui`
- `mix spec.compliance elm_ui`

## Helper Modules

- `ElmUi.Inspect`
  - preview native, canonical, and mixed examples through one workflow
- `ElmUi.Export`
  - export stable review artifacts backed by example metadata
- `ElmUi.Validate`
  - validate example coverage, runtime behavior, and release readiness
- `ElmUi.Reference`
  - inspect the current package-facing capability surface
- `ElmUi.Info`
  - inspect the current package summary and validation state

## Recommended Review Loop

1. Inspect example metadata through `mix elm_ui.preview --format catalog`.
2. Preview example behavior through `mix elm_ui.inspect native_styling`.
3. Export a review artifact through `mix elm_ui.export styling_continuity --format comparison`.
4. Run release-readiness checks through `mix elm_ui.validate --strict`.
