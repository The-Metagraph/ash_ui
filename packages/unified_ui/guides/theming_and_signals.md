# Theming and Signals

This guide covers the cross-cutting authored surfaces that tend to drift first:
themes, styles, bindings, and interactions.

## Theming Model

Themes are declared in the `themes` section and compiled into canonical
`UnifiedIUR` theme values. The authored surface supports:

- theme identity and optional inheritance through `extends`
- palette colors for reusable base values
- semantic roles for intent-driven color usage
- tokens for reusable style fragments
- component styles, variants, and state-specific overrides

The package allows local node styles, shared component styles, and theme-level
token resolution, but the final compiler output must still be deterministic.

## Style Attributes

The authored style model includes the canonical attribute families defined by
the package specs:

- typography
- color and semantic emphasis
- spacing and sizing
- alignment and layout-affecting placement details
- borders
- visibility
- state variants

Validation rejects invalid combinations or values such as unsupported component
states or visibility opacity outside the accepted range.

## Signal Authoring Model

Canonical signals are authored in the `signals` section. The package supports:

- data bindings with canonical paths and scopes
- interaction descriptors with families such as `:click`, `:change`, `:submit`, `:open`, `:navigation`, and `:command`
- payload mappings that point to canonical bindings
- target intents that preserve canonical downstream meaning

The authored signal surface is package-level canonical behavior, not a renderer
bridge. Renderer-local keys such as `phx_click` or `phx_submit` are rejected.

## Validation Expectations

The package validates theme and signal authoring at compile time:

- default themes must reference declared theme ids
- style refs must point to declared component styles
- interaction refs must point to declared interactions
- binding references must point to declared bindings
- renderer-local keys are not allowed in canonical signal source context

The maintained example `themed_signal_workspace` is the reference module for
cross-cutting theme and signal authoring.
