# Ash UI Example Suite

Standalone example-application contract for the mirrored `examples/` suite.

## Intent

Define the current truth for how Ash UI example apps are structured, seeded,
mounted, and reviewed as resource-authority applications.

```spec-meta
id: ash_ui.examples
kind: workflow
status: active
summary: Standalone example-app contract for catalog parity, resource-authority authoring, and shared review surfaces under `examples/`.
surface:
  - examples/README.md
  - examples/catalog.tsv
  - examples/scaffold_contract.md
  - examples/ash_hq_theme_baseline.md
  - examples/ash_hq_theme_tokens.css
  - specs/planning/phase-17-ash-ui-example-suite-scaffold-catalog-crosswalk-and-ash-hq-theme-baseline.md
```

## Requirements

```spec-requirements
- id: ash_ui.examples.catalog_parity_contract
  statement: The example suite shall preserve the sibling `unified_ui` example-directory identifiers and catalog metadata as the authoritative parity surface, while allowing canonical Ash UI widget-type normalization behind those stable directory names.
  priority: must
  stability: stable
- id: ash_ui.examples.standalone_mix_projects
  statement: Each example application shall live under `examples/<directory_name>/` as an independent Mix project with its own configuration, runtime entrypoints, and tests rather than depending on an `examples/shared` support package.
  priority: must
  stability: stable
- id: ash_ui.examples.resource_authority_scaffold
  statement: Each example application shall be authored as one screen resource plus related element resources, backed by app-local UI storage resources and persisted through `AshUI.Resource.Authority.create/2`.
  priority: must
  stability: stable
- id: ash_ui.examples.host_app_mount_contract
  statement: Each example application shall provide app-local host modules for UI storage, runtime domain resources, Phoenix endpoint/router wiring, and one LiveView mount surface that loads the seeded screen through `AshUI.LiveView.Integration`.
  priority: must
  stability: stable
- id: ash_ui.examples.review_surface_contract
  statement: Every example application shall expose one reviewer-visible `Meaningful Interaction Story` surface and one reviewer-visible `Canonical Signal Preview` surface alongside the focused demonstration of its primary subject.
  priority: must
  stability: stable
- id: ash_ui.examples.seed_and_reset_contract
  statement: Every example application shall expose app-local seed helpers that create representative runtime fixtures, persist the authored screen through `AshUI.Resource.Authority`, and provide a repeatable reset or reseed path for tests and local review workflows.
  priority: must
  stability: stable
- id: ash_ui.examples.ash_hq_theme_baseline
  statement: The example suite shall preserve one Ash-HQ-derived baseline of dark slate shells, warm orange-red accent ramps, glass panels, rounded pill actions, and gridded gradient backdrops, with each standalone app vendoring that baseline locally instead of relying on an `examples/shared` dependency.
  priority: must
  stability: stable
- id: ash_ui.examples.authoring_facing_style_api
  statement: Example applications shall keep palette tokens and shell treatments in host-app CSS while exposing semantic example-shell, panel, story, signal-preview, and CTA style hooks through stable class names or variants rather than ad hoc inline styling.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: source_file
  target: examples/README.md
  covers:
    - ash_ui.examples.catalog_parity_contract
    - ash_ui.examples.review_surface_contract
- kind: source_file
  target: examples/catalog.tsv
  covers:
    - ash_ui.examples.catalog_parity_contract
- kind: source_file
  target: examples/scaffold_contract.md
  covers:
    - ash_ui.examples.standalone_mix_projects
    - ash_ui.examples.resource_authority_scaffold
    - ash_ui.examples.host_app_mount_contract
    - ash_ui.examples.review_surface_contract
    - ash_ui.examples.seed_and_reset_contract
- kind: source_file
  target: examples/ash_hq_theme_baseline.md
  covers:
    - ash_ui.examples.ash_hq_theme_baseline
    - ash_ui.examples.authoring_facing_style_api
- kind: source_file
  target: examples/ash_hq_theme_tokens.css
  covers:
    - ash_ui.examples.ash_hq_theme_baseline
    - ash_ui.examples.authoring_facing_style_api
```
