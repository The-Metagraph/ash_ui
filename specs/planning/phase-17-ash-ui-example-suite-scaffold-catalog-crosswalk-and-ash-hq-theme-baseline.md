# Phase 17 - Ash UI Example Suite Scaffold, Catalog Crosswalk, and Ash HQ Theme Baseline

Back to index: [README](./README.md)

## Relevant Shared APIs / Interfaces
- `examples/`
- `AshUI.Resource.DSL.Screen`
- `AshUI.Resource.DSL.Element`
- `AshUI.Resource.Authority`
- `AshUI.LiveView.Integration`
- `AshUI.Rendering.LiveUIAdapter`
- Ash UI storage config and shipped `Screen` / `Element` / `Binding` resources
- the sibling `unified_ui` example catalog

## Relevant Assumptions / Defaults
- the Ash UI example suite must mirror the current `unified_ui` example catalog
  and directory names so coverage stays comparable across the two packages
- every example app lives under `examples/<example_name>/` as a standalone Mix
  project with its own endpoint, router, LiveView host, and seed/bootstrap path
- every example is authored as one screen resource plus related element
  resources, with bindings and actions declared on the owning screen or element
  resource rather than in detached screen documents
- the shared visual baseline follows the current `ash-hq.org` public site
  language: dark `slate` surfaces, white/slate copy, warm red/orange accent
  gradients, glass-like panels, rounded pill CTAs, and grid/gradient backdrop
  motifs
- directory names may preserve `unified_ui` catalog parity even when the
  canonical Ash UI widget type normalizes differently, for example
  `separator -> divider`, `text_input -> input`, `radio_group -> radio`, and
  `toggle -> switch`

[ ] 17 Phase 17 - Ash UI Example Suite Scaffold, Catalog Crosswalk, and Ash HQ Theme Baseline
  Define the suite-wide contract for rebuilding the Ash UI `examples/`
  directory as a resource-first mirror of the sibling `unified_ui` example
  catalog.

  [ ] 17.1 Section - Catalog Crosswalk and Capability Mapping
    Map the `unified_ui` example catalog onto Ash UI's current authoring and
    runtime boundaries before example implementation begins.

    [ ] 17.1.1 Task - Define the Ash UI example catalog contract
    Establish the authoritative app list, naming continuity, and widget-type
    normalization rules for the mirrored suite.

      [ ] 17.1.1.1 Subtask - Import all current example identifiers and family groupings from the sibling `unified_ui` example catalog.
      [ ] 17.1.1.2 Subtask - Define the canonical Ash UI type mapping for normalized names such as `separator`, `text_input`, `radio_group`, and `toggle`.
      [ ] 17.1.1.3 Subtask - Classify `numeric_input`, `date_input`, `time_input`, and `file_input` as stable directory names backed by specialized `input` authoring where appropriate.
      [ ] 17.1.1.4 Subtask - Identify which catalog entries require new public Ash UI widget vocabulary, richer fallback rendering, or temporary `custom:*` surfaces before their example apps can ship honestly.

    [ ] 17.1.2 Task - Define parity and rollout rules
    Decide what "same example set" means operationally for Ash UI rather than
    treating catalog parity as only a directory-copy exercise.

      [ ] 17.1.2.1 Subtask - Define required parity across app names, primary interaction stories, and public review surfaces.
      [ ] 17.1.2.2 Subtask - Separate the catalog into low-risk, medium-risk, and high-complexity implementation families for rollout planning.
      [ ] 17.1.2.3 Subtask - Define the maintained runtime target for all apps, with LiveView mandatory and other renderer previews explicitly optional.
      [ ] 17.1.2.4 Subtask - Define an unsupported-surface policy so example apps do not overstate widget support beyond maintained Ash UI authoring/runtime boundaries.

  [ ] 17.2 Section - Resource-Authority Example App Template
    Define the reusable app-level shape that every mirrored example must follow.

    [ ] 17.2.1 Task - Define the per-app resource-first scaffold
    Make every example app look like a small but complete Ash UI application.

      [ ] 17.2.1.1 Subtask - Define the required screen resource, element resource, relationship, and binding/action module set for one example app.
      [ ] 17.2.1.2 Subtask - Define the required host-app modules for UI storage, runtime domain, endpoint, router, and LiveView mounting.
      [ ] 17.2.1.3 Subtask - Define one shared "Meaningful Interaction Story" review surface and one shared "Canonical Signal Preview" surface for all apps.
      [ ] 17.2.1.4 Subtask - Define route, seed-data, naming, and DOM-id conventions so every app is discoverable and comparable across the suite.

    [ ] 17.2.2 Task - Define suite bootstrap and seed conventions
    Keep example apps repeatable without forcing maintainers to hand-assemble
    storage or runtime state for each app.

      [ ] 17.2.2.1 Subtask - Define the default storage strategy for example apps, including when ETS-backed UI storage is sufficient and when repo-backed fixtures are required.
      [ ] 17.2.2.2 Subtask - Define app-local seed helpers that create persisted screens through `AshUI.Resource.Authority`.
      [ ] 17.2.2.3 Subtask - Define how representative runtime actors, authorization context, and list/action data fixtures are created per app.
      [ ] 17.2.2.4 Subtask - Define the reset/reseed path used by tests and local review workflows.

  [ ] 17.3 Section - Ash HQ Theme and Shell Baseline
    Turn the current `ash-hq.org` visual language into a reusable suite
    baseline rather than re-styling every example ad hoc.

    [ ] 17.3.1 Task - Define the shared theme tokens and shell contract
    Provide one Ash-HQ-derived presentation baseline for every example app.

      [ ] 17.3.1.1 Subtask - Define suite palette tokens for dark slate backgrounds, white/slate copy, and warm red/orange accent ramps derived from the current Ash HQ site.
      [ ] 17.3.1.2 Subtask - Define suite shell treatments for gradient/grid backdrops, frosted panels, rounded containers, and code-surface motifs.
      [ ] 17.3.1.3 Subtask - Define suite button, panel, form, and status style profiles that example apps can reuse without duplicating CSS decisions.
      [ ] 17.3.1.4 Subtask - Define accessibility, responsive, and contrast requirements so the Ash HQ visual language remains usable in example-app review flows.

    [ ] 17.3.2 Task - Define the authoring-facing style API
    Make the theme contract usable from Ash UI resource props and not only from
    Phoenix host templates.

      [ ] 17.3.2.1 Subtask - Define which style tokens live in host-app CSS versus `ui_element` props like `class`, `inline_style`, and semantic variants.
      [ ] 17.3.2.2 Subtask - Define when examples should prefer semantic widget variants over raw inline CSS.
      [ ] 17.3.2.3 Subtask - Define how example apps keep the suite shell visually shared while allowing per-widget emphasis where needed.
      [ ] 17.3.2.4 Subtask - Add validation or review guidance that catches divergence from the shared Ash HQ style baseline.

  [ ] 17.4 Section - Phase 17 Integration Tests
    Validate the suite scaffold, catalog crosswalk, and theme baseline before
    app families start landing.

    [ ] 17.4.1 Task - Scaffold and style baseline scenarios
    Prove that the suite foundation is coherent enough to scale across the full
    mirrored catalog.

      [ ] 17.4.1.1 Subtask - Verify the catalog crosswalk covers every sibling `unified_ui` example entry exactly once.
      [ ] 17.4.1.2 Subtask - Verify a generated or scaffolded example app can persist a resource-authority screen and mount it through LiveView.
      [ ] 17.4.1.3 Subtask - Verify the shared Ash HQ theme shell renders correctly on desktop and mobile breakpoints.
      [ ] 17.4.1.4 Subtask - Verify the suite contract rejects example names, widget mappings, or style baselines that drift from the catalog scaffold.
