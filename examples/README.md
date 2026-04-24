# Examples

This directory is reserved for runnable and copyable Ash UI examples.

## Status

The repository now includes checked-in standalone example apps from Phase 18
Sections 18.1, 18.2, and 18.3.

Current directories:

- `examples/box`
- `examples/text`
- `examples/button`
- `examples/checkbox`
- `examples/content`
- `examples/field`
- `examples/field_group`
- `examples/form_builder`
- `examples/icon`
- `examples/image`
- `examples/label`
- `examples/link`
- `examples/date_input`
- `examples/file_input`
- `examples/numeric_input`
- `examples/pick_list`
- `examples/radio_group`
- `examples/separator`
- `examples/spacer`
- `examples/select`
- `examples/text_input`
- `examples/time_input`
- `examples/toggle`

Phase 17 Section 17.1 defines the example-suite contract that the checked-in
apps and future example directories must follow. The shared planning artifacts
and baseline references in this directory are:

- `examples/catalog.tsv`: machine-readable crosswalk from the sibling
  `unified_ui` example suite into the planned Ash UI example suite
- `examples/scaffold_contract.md`: required per-app resource-authority app
  shape, host modules, review surfaces, and bootstrap conventions
- `examples/ash_hq_theme_baseline.md`: shared visual baseline derived from the
  current `ash-hq.org` site
- `examples/ash_hq_theme_tokens.css`: copyable palette and shell token source
  for future app-local CSS
- `specs/planning/phase-17-ash-ui-example-suite-scaffold-catalog-crosswalk-and-ash-hq-theme-baseline.md`
- `specs/planning/phase-18-foundational-content-form-and-input-example-apps.md`
- `.spec/specs/examples.spec.md`

## Shared Scaffold

Phase 17 Section 17.2 defines the reusable example-app scaffold used by every
future directory under `examples/<name>/`.

The maintained baseline is:

- one standalone Mix project per example directory
- one authored screen resource plus related element resources per example
- app-local UI storage and runtime domains
- one LiveView host route at `/`
- one reviewer-visible `Meaningful Interaction Story` surface
- one reviewer-visible `Canonical Signal Preview` surface
- one app-local seed module that persists the screen through
  `AshUI.Resource.Authority.create/2`

See [Resource-Authority Example App Scaffold](./scaffold_contract.md) for the
full module, route, DOM-id, and reset/reseed contract.

Current form-oriented helper rules established by Phase 18 Section 18.2:

- `form_builder` may own nested `form_field` and submit-button children.
- `field` may normalize into `form_field` with a nested input child.
- `field_group` may use `custom:field_group` as the review subject while
  composing nested `form_field` and input children underneath it.
- Supporting helper elements must stay subordinate to one clear primary subject
  per directory.

Current input-control rules established by Phase 18 Section 18.3:

- `text_input`, `numeric_input`, `date_input`, `time_input`, and `file_input`
  are authored through the canonical `input` widget with specialized props.
- `checkbox` and `select` use the current public widget surface directly.
- `radio_group` preserves sibling naming while authoring through the canonical
  `radio` widget.
- `toggle` preserves sibling naming while authoring through the canonical
  `switch` widget.
- `pick_list` remains an explicit `custom:pick_list` surface until a stable
  public multi-pick contract is admitted.
- Preview stats are the reviewer-visible transformed value surface for input
  examples, including boolean values and narrowed filename echoes.
- Partial or normalized surfaces must render a support notice instead of
  implying broader runtime support than Ash UI currently provides.
- Invalid binding/runtime assumptions must surface a visible error flash through
  the shared shell rather than silently no-op.

## Shared Theme

Phase 17 Section 17.3 defines the shared Ash HQ visual contract for the
example suite.

The maintained baseline uses:

- `slate-950` page shells and translucent slate glass panels
- warm orange-to-red accent ramps derived from the current Ash HQ homepage
- rounded pill CTAs with restrained warm glow
- gradient-plus-grid backdrops and code-surface motifs
- host-app CSS tokens plus semantic style hooks instead of ad hoc inline styles

Use [Ash HQ Theme Baseline](./ash_hq_theme_baseline.md) for the normative
design contract and [ash_hq_theme_tokens.css](./ash_hq_theme_tokens.css) as the
copyable token source that future standalone apps should vendor locally.

## Planned Suite Contract

The Ash UI suite will mirror the current sibling `unified_ui` example catalog
by directory name while rebuilding each app through Ash UI resource-authority
screens and related element resources.

The current Phase 17 parity rules are:

- Preserve the current sibling example directory identifiers exactly.
- Preserve the imported family grouping and interaction metadata as the starting
  review contract.
- Keep one primary subject per example directory even when supporting shell
  elements or helper controls are needed.
- Require one reviewer-visible `Meaningful Interaction Story` surface per app.
- Require one reviewer-visible `Canonical Signal Preview` surface per app.
- Require app-local seed helpers that persist the mounted screen through
  `AshUI.Resource.Authority`.
- Treat `liveview` as the maintained runtime target for all apps.
- Treat any renderer previews beyond `liveview` as optional and non-blocking.
- Call out unsupported or partial widget/runtime surfaces explicitly in the
  catalog and app-local docs instead of implying support.

## Rollout Buckets

| Ash UI Phase | Families | Rollout intent |
|---|---|---|
| `18` | `content`, `forms`, `input`, plus `box` and `content` | Stand up the baseline suite shape through the lowest-risk examples first. |
| `19` | `layout`, `navigation`, `display` | Expand the public example surface around relationship-driven structure and higher-order layout constructs. |
| `20` | `overlay`, `data`, `feedback`, `operational` | Land the highest-complexity examples that depend on richer runtime data, layered flows, or custom/example-only widget surfaces. |

## Catalog Field Meanings

`examples/catalog.tsv` uses these planning-specific columns in addition to the
imported sibling metadata:

- `ash_ui_phase`: planned Ash UI rollout phase for the example directory
- `ash_ui_canonical_subject`: canonical Ash UI widget type, custom type, or
  screen/composition subject the example is expected to use
- `ash_ui_authoring_path`: the expected implementation path
- `support_gap`: the main capability gap or normalization rule that still
  matters before the example can ship honestly
- `complexity_tier`: current rollout-risk bucket
- `maintained_runtime`: the runtime target the suite commits to maintain
- `preview_policy`: whether non-LiveView previews are mandatory or optional

### `ash_ui_authoring_path`

- `native_widget`: current public Ash UI type with no naming translation
- `normalized_widget`: stable example directory name with a different canonical
  Ash UI type
- `specialized_input`: stable example directory name implemented through the
  canonical `input` type with specialized props and host/runtime handling
- `promote_fallback_widget`: fallback renderer/runtime understands the concept
  today, but public authoring validation does not yet admit it
- `composed_native_screen`: the example should be treated as a named review
  pattern built from a screen plus related native widgets rather than one
  standalone widget type
- `custom_widget`: the example currently needs an explicit `custom:*` surface or
  a future public widget admission

### `support_gap`

- `none`: current public authoring and fallback runtime are good enough for the
  first example implementation
- `normalized_name`: the directory name is preserved, but the canonical Ash UI
  type differs
- `specialized_input_runtime`: the directory name is preserved, but the example
  depends on specialized `input` props or host/runtime handling
- `public_type_admission`: current fallback behavior exists, but public
  authoring validation must admit the type
- `richer_fallback_rendering`: the public type exists, but the current fallback
  renderer is too generic for an honest example
- `composition_shell`: the example is best treated as a named composition
  pattern rather than one first-class widget type
- `custom_surface_until_admitted`: the example needs an explicit custom surface
  until a stable public widget contract exists
- `seeded_runtime_complexity`: the example can be built from native widgets but
  needs richer seeded runtime state or operational storytelling
