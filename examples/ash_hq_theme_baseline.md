# Ash HQ Theme Baseline

This document defines the shared visual baseline for the Ash UI example suite.

The baseline is derived from the current `https://www.ash-hq.org/` homepage as
observed on `2026-04-24`. The live site currently uses:

- a `bg-slate-950` page shell
- warm `primary-light-*` and `primary-dark-*` orange-to-red gradients
- frosted `bg-slate-950/50` glass panels with `backdrop-blur-lg`
- rounded pill CTAs with warm red glow shadows
- gridded gradient backdrops and code-panel motifs

Future example apps should preserve that visual language while still remaining
honest about Ash UI runtime and widget support.

## Palette Tokens

Use these suite tokens as the default palette in app-local CSS:

| Token | Value | Current Ash HQ basis |
|---|---|---|
| `--ashui-example-bg-base` | `#020617` | `bg-slate-950` |
| `--ashui-example-glass-bg` | `#02061780` | `bg-slate-950/50` |
| `--ashui-example-panel-bg` | `#0f172acc` | `bg-slate-900/80` |
| `--ashui-example-panel-muted-bg` | `#1e293bb3` | `bg-slate-800/70` |
| `--ashui-example-copy` | `#ffffff` | body copy |
| `--ashui-example-copy-soft` | `#cbd5e1` | slate-muted copy |
| `--ashui-example-copy-warm` | `#ffcaa9` | `text-primary-light-200` |
| `--ashui-example-accent-soft` | `#ffa46c` | `text-primary-light-400` |
| `--ashui-example-accent` | `#ff914d` | `text-primary-light-500` |
| `--ashui-example-accent-strong` | `#ff6e15` | `text-primary-light-600` |
| `--ashui-example-signal` | `#ff5757` | `text-primary-dark-500` |
| `--ashui-example-signal-strong` | `#ff1f1f` | `bg-primary-dark-600` |
| `--ashui-example-signal-hover` | `#e60000` | `hover:bg-primary-dark-700` |
| `--ashui-example-border-soft` | `#ff914d4d` | `border-primary-light-500/30` |
| `--ashui-example-border-strong` | `#ff575733` | `border-primary-dark-500/20` |
| `--ashui-example-grid-line` | `rgba(254, 19, 19, 0.2)` | grid backdrop lines |

## Shell Treatments

Every app should vendor the same shell treatments locally:

- page shell: `slate-950` background with a soft top-to-bottom warm gradient
  wash
- backdrop grid: 40px perspective grid lines masked radially so the center is
  brightest and the edges fade out
- glass panels: `backdrop-blur`, translucent slate fill, warm orange border,
  and `24px`-class corner radius
- code surfaces: darker slate panel, monospaced copy, and window-dot chrome
  when a code or signal-readout surface is present
- actions: pill-shaped CTAs, one filled orange-to-red gradient primary action,
  and one outlined warm-accent secondary action
- glow: restrained warm glow on primary headings, logo treatment, and primary
  CTA only

## Shared Style Profiles

App-local CSS should expose these shared semantic profiles:

- `example_shell`: full-page Ash HQ backdrop, centered content, and review-grid
  layout
- `example_panel`: glass-card treatment for the main demo and supporting panels
- `example_story`: reviewer guidance panel for `Meaningful Interaction Story`
- `example_signal_preview`: structured signal readout panel for `Canonical
  Signal Preview`
- `example_code_surface`: monospace, deeper-slate panel for signal payloads,
  snippets, or structured debug output
- `example_primary_cta`: warm gradient pill button
- `example_secondary_cta`: outlined warm-accent pill button
- `example_status_notice`: compact state pill using warm accent or signal tone

These profiles may be implemented as CSS classes, semantic `variants`, or a
small combination of both, but the names above are the review contract for the
suite.

## Authoring-Facing Style API

Split the style boundary this way:

- host-app CSS owns palette tokens, gradients, backdrop grid, glass treatment,
  CTA glow, spacing rhythm, and responsive panel layout
- `ui_element` and `ui_screen` declarations should prefer semantic variants and
  class hooks such as `example_panel` or `example_primary_cta`
- raw `class` props are allowed when they point at host-defined semantic
  classes and layout hooks
- `inline_style` is reserved for dynamic values that cannot be expressed
  semantically, such as chart dimensions or data-driven widths
- examples should not use `inline_style` to re-specify palette, blur, spacing,
  or core shell rules that belong in the shared theme contract

Per-widget emphasis is allowed when the primary subject needs it, but that
emphasis must sit inside the shared shell rather than replacing it with a new
background, new accent family, or unrelated button language.

## Accessibility And Responsive Baseline

Every app should preserve these review requirements:

- maintain at least `4.5:1` contrast for body copy against the dark shell and
  `3:1` for large display text
- keep visible focus rings using the shared signal color family
- keep touch targets at `44px` minimum height for primary controls
- respect reduced-motion preferences by disabling non-essential glow and scale
  transitions
- on desktop, keep the demo, story, and signal-preview zones simultaneously
  visible without tabs or hidden drawers
- on narrower screens, stack the review zones in this order: demo, story,
  signal preview
