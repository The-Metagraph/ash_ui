defmodule LiveUi.Stylesheet do
  @moduledoc """
  Shared browser stylesheet for `live_ui` HTML rendering.

  Host apps, preview tooling, and the browser demo should load `css/0`
  whenever `live_ui` widgets are rendered into a browser document.
  """

  @spec css() :: String.t()
  def css do
    Enum.join(
      [theme_tokens(), reset_css(), layout_css(), foundational_css(), advanced_css()],
      "\n\n"
    )
  end

  defp theme_tokens do
    ~S"""
    :root {
      --live-ui-theme-surface-base: #111827;
      --live-ui-theme-surface-panel: #1f2937;
      --live-ui-theme-foreground: #f9fafb;
      --live-ui-theme-foreground-muted: #d1d5db;
      --live-ui-theme-border-muted: hsl(215 28% 22%);
      --live-ui-theme-border-strong: hsl(215 28% 30%);
      --live-ui-theme-accent: #2563eb;
      --live-ui-theme-accent-strong: #1d4ed8;
      --live-ui-theme-accent-soft: hsl(217 91% 60% / 0.12);
      --live-ui-theme-success: #059669;
      --live-ui-theme-warning: #d97706;
      --live-ui-theme-critical: #dc2626;
      --live-ui-gap-sm: 0.55rem;
      --live-ui-gap-md: 0.85rem;
      --live-ui-gap-lg: 1rem;
      --live-ui-gap-xl: 1.35rem;
      --live-ui-radius-sm: 0.5rem;
      --live-ui-radius-md: 0.75rem;
      --live-ui-radius-lg: 1rem;
      --live-ui-shadow-panel: inset 0 1px 0 hsl(0 0% 100% / 0.04);
      --live-ui-shadow-action: 0 14px 34px hsl(217 91% 60% / 0.18);
    }
    """
  end

  defp reset_css do
    ~S"""
    [data-live-ui-widget] {
      --live-ui-foreground: initial;
      --live-ui-background: initial;
      --live-ui-border-color: initial;
      --live-ui-border-width: initial;
      --live-ui-border-style: initial;
      --live-ui-border-radius: initial;
      --live-ui-padding: initial;
      --live-ui-padding-inline: initial;
      --live-ui-padding-block: initial;
      --live-ui-margin: initial;
      --live-ui-margin-inline: initial;
      --live-ui-margin-block: initial;
      --live-ui-gap: initial;
      --live-ui-width: initial;
      --live-ui-height: initial;
      --live-ui-min-width: initial;
      --live-ui-min-height: initial;
      --live-ui-max-width: initial;
      --live-ui-max-height: initial;
      --live-ui-align-items: initial;
      --live-ui-justify-content: initial;
      --live-ui-text-align: initial;
      --live-ui-align-self: initial;
      --live-ui-display: initial;
      --live-ui-grid-columns: initial;
      --live-ui-grid-rows: initial;
      --live-ui-box-shadow: initial;
      --live-ui-overlay-scrim: initial;
      --live-ui-overflow: initial;
      --live-ui-overflow-x: initial;
      --live-ui-overflow-y: initial;
      --live-ui-viewport-offset-x: initial;
      --live-ui-viewport-offset-y: initial;
      --live-ui-canvas-columns: initial;
      --live-ui-canvas-rows: initial;
      --live-ui-font-weight: initial;
      --live-ui-font-style: initial;
      --live-ui-text-decoration: initial;
      --live-ui-text-opacity: initial;
      --live-ui-opacity: initial;
      --live-ui-visibility: initial;
    }
    """
  end

  defp layout_css do
    ~S"""
    [data-live-ui-runtime="screen"] {
      display: grid;
      gap: 1rem;
    }

    [data-live-ui-widget="row"],
    [data-live-ui-widget="column"] {
      display: flex;
      min-width: 0;
      width: var(--live-ui-width, auto);
      height: var(--live-ui-height, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, auto);
      max-width: var(--live-ui-max-width, none);
      max-height: var(--live-ui-max-height, none);
      align-self: var(--live-ui-align-self, auto);
      align-items: var(--live-ui-align-items, stretch);
      justify-content: var(--live-ui-justify-content, flex-start);
      gap: var(--live-ui-gap, 0);
      padding: var(--live-ui-padding, var(--live-ui-padding-block, 0) var(--live-ui-padding-inline, 0));
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
    }

    [data-live-ui-widget="column"] {
      flex-direction: column;
    }

    [data-live-ui-widget="row"] {
      flex-wrap: wrap;
      flex-direction: row;
      align-items: flex-start;
    }

    [data-live-ui-widget="grid"] {
      display: grid;
      min-width: 0;
      width: var(--live-ui-width, auto);
      height: var(--live-ui-height, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, auto);
      max-width: var(--live-ui-max-width, none);
      max-height: var(--live-ui-max-height, none);
      align-self: var(--live-ui-align-self, auto);
      align-items: var(--live-ui-align-items, stretch);
      justify-content: var(--live-ui-justify-content, stretch);
      gap: var(--live-ui-gap, 0);
      padding: var(--live-ui-padding, var(--live-ui-padding-block, 0) var(--live-ui-padding-inline, 0));
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
      grid-template-columns: repeat(var(--live-ui-grid-columns, 1), minmax(0, 1fr));
      grid-template-rows: repeat(var(--live-ui-grid-rows, auto), minmax(0, auto));
    }

    [data-live-ui-widget="overlay-surface"],
    .live-ui-overlay-surface {
      position: relative;
      display: grid;
      min-width: 0;
      isolation: isolate;
    }

    [data-live-ui-overlay-slot="base"],
    [data-live-ui-overlay-slot="overlay"] {
      grid-area: 1 / 1;
      min-width: 0;
    }

    [data-live-ui-overlay-slot="overlay"] {
      z-index: 10;
      display: grid;
      align-items: center;
      justify-items: center;
      padding: 1.5rem;
      background: var(--live-ui-overlay-scrim, transparent);
      pointer-events: none;
    }

    [data-live-ui-overlay-slot="overlay"] > * {
      pointer-events: auto;
    }

    [data-live-ui-widget="viewport"],
    .live-ui-viewport {
      display: block;
      width: var(--live-ui-width, auto);
      height: var(--live-ui-height, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, auto);
      max-width: var(--live-ui-max-width, none);
      max-height: var(--live-ui-max-height, none);
      padding: var(--live-ui-padding, 0.75rem);
      margin: var(--live-ui-margin, 0);
      border-width: var(--live-ui-border-width, 1px);
      border-style: var(--live-ui-border-style, solid);
      border-color: var(--live-ui-border-color, var(--live-ui-theme-border-muted));
      border-radius: var(--live-ui-border-radius, var(--live-ui-radius-lg));
      background: var(--live-ui-background, color-mix(in srgb, var(--live-ui-theme-surface-base) 92%, white 8%));
      overflow-x: var(--live-ui-overflow-x, hidden);
      overflow-y: var(--live-ui-overflow-y, auto);
      box-sizing: border-box;
    }

    [data-live-ui-viewport-slot="content"] {
      min-width: 100%;
      transform: translate(
        calc(var(--live-ui-viewport-offset-x, 0) * -1px),
        calc(var(--live-ui-viewport-offset-y, 0) * -1px)
      );
    }

    [data-live-ui-widget="canvas"],
    .live-ui-canvas {
      display: grid;
      position: relative;
      width: var(--live-ui-width, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, auto);
      padding: var(--live-ui-padding, 0.75rem);
      margin: var(--live-ui-margin, 0);
      border-width: var(--live-ui-border-width, 1px);
      border-style: var(--live-ui-border-style, solid);
      border-color: var(--live-ui-border-color, var(--live-ui-theme-border-muted));
      border-radius: var(--live-ui-border-radius, var(--live-ui-radius-lg));
      background: var(--live-ui-background, color-mix(in srgb, var(--live-ui-theme-surface-panel) 82%, black));
      overflow: var(--live-ui-overflow, hidden);
      grid-template-columns: repeat(var(--live-ui-canvas-columns, 24), minmax(0, 1ch));
      grid-template-rows: repeat(var(--live-ui-canvas-rows, 12), minmax(1lh, auto));
      align-content: start;
      justify-content: start;
      box-sizing: border-box;
      font-family: ui-monospace, "SFMono-Regular", Menlo, monospace;
      line-height: 1;
      gap: 0;
    }

    [data-live-ui-widget="canvas"][data-live-ui-variant="analysis"],
    .live-ui-canvas-analysis {
      --live-ui-border-color: color-mix(in srgb, var(--live-ui-theme-accent) 48%, var(--live-ui-theme-border-strong));
      --live-ui-background: linear-gradient(
        180deg,
        color-mix(in srgb, var(--live-ui-theme-surface-base) 84%, var(--live-ui-theme-accent) 16%) 0%,
        color-mix(in srgb, var(--live-ui-theme-surface-base) 96%, black) 100%
      );
    }

    [data-live-ui-widget="canvas"] > [data-live-ui-canvas-op] {
      grid-column: var(--live-ui-canvas-col, 1);
      grid-row: var(--live-ui-canvas-row, 1);
      white-space: pre;
    }
    """
  end

  defp foundational_css do
    ~S"""
    .live-ui-text,
    .live-ui-button,
    .live-ui-text-input,
    .live-ui-box,
    .live-ui-screen-shell {
      color: var(--live-ui-foreground, var(--live-ui-default-foreground, var(--live-ui-theme-foreground)));
      opacity: var(--live-ui-text-opacity, var(--live-ui-opacity, 1));
      visibility: var(--live-ui-visibility, visible);
      box-sizing: border-box;
    }

    .live-ui-text[data-live-ui-tone="accent"],
    .live-ui-button[data-live-ui-tone="accent"],
    .live-ui-text-input[data-live-ui-tone="accent"] {
      --live-ui-default-foreground: var(--live-ui-theme-accent);
    }

    .live-ui-text[data-live-ui-tone="success"],
    .live-ui-button[data-live-ui-tone="success"] {
      --live-ui-default-foreground: var(--live-ui-theme-success);
    }

    .live-ui-text[data-live-ui-tone="warning"],
    .live-ui-button[data-live-ui-tone="warning"] {
      --live-ui-default-foreground: var(--live-ui-theme-warning);
    }

    .live-ui-text[data-live-ui-tone="critical"],
    .live-ui-button[data-live-ui-tone="critical"] {
      --live-ui-default-foreground: var(--live-ui-theme-critical);
    }

    .live-ui-screen-shell {
      --live-ui-default-padding-inline: 1rem;
      --live-ui-default-padding-block: 1rem;
      --live-ui-default-background: linear-gradient(
        180deg,
        color-mix(in srgb, var(--live-ui-theme-surface-panel) 50%, var(--live-ui-theme-surface-base)) 0%,
        var(--live-ui-theme-surface-base) 100%
      );
      --live-ui-default-border-color: var(--live-ui-theme-border-muted);
    }

    .live-ui-box {
      display: var(--live-ui-display, flex);
      flex-direction: column;
      gap: var(--live-ui-gap, 1rem);
      padding: var(--live-ui-padding, var(--live-ui-padding-block, var(--live-ui-default-padding-block, 0)) var(--live-ui-padding-inline, var(--live-ui-default-padding-inline, 0)));
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
      width: var(--live-ui-width, auto);
      height: var(--live-ui-height, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, auto);
      max-width: var(--live-ui-max-width, none);
      max-height: var(--live-ui-max-height, none);
      align-self: var(--live-ui-align-self, auto);
      border-width: var(--live-ui-border-width, var(--live-ui-default-border-width, 1px));
      border-style: var(--live-ui-border-style, var(--live-ui-default-border-style, solid));
      border-color: var(--live-ui-border-color, var(--live-ui-default-border-color, transparent));
      border-radius: var(--live-ui-border-radius, var(--live-ui-default-border-radius, var(--live-ui-radius-lg)));
      background: var(--live-ui-background, var(--live-ui-default-background, transparent));
      box-shadow: var(--live-ui-box-shadow, none);
    }

    .live-ui-box.live-ui-box-panel,
    .live-ui-screen-shell {
      --live-ui-default-padding-inline: 1.2rem;
      --live-ui-default-padding-block: 1.2rem;
      --live-ui-default-border-color: var(--live-ui-theme-border-muted);
      --live-ui-default-background: linear-gradient(
        180deg,
        color-mix(in srgb, var(--live-ui-theme-surface-panel) 78%, black) 0%,
        color-mix(in srgb, var(--live-ui-theme-surface-base) 88%, black) 100%
      );
      border-width: var(--live-ui-border-width, 1px);
      border-style: var(--live-ui-border-style, solid);
      border-color: var(--live-ui-border-color, var(--live-ui-default-border-color));
      border-radius: var(--live-ui-border-radius, var(--live-ui-radius-lg));
      box-shadow: var(--live-ui-box-shadow, var(--live-ui-shadow-panel));
    }

    .live-ui-text {
      display: var(--live-ui-display, inline);
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
      width: var(--live-ui-width, auto);
      min-width: var(--live-ui-min-width, 0);
      max-width: var(--live-ui-max-width, none);
      font: inherit;
      font-weight: var(--live-ui-font-weight, inherit);
      font-style: var(--live-ui-font-style, normal);
      text-decoration: var(--live-ui-text-decoration, none);
      text-align: var(--live-ui-text-align, inherit);
      line-height: 1.6;
    }

    .live-ui-button {
      --live-ui-default-padding-inline: 1.15rem;
      --live-ui-default-padding-block: 0.8rem;
      --live-ui-default-border-width: 1px;
      --live-ui-default-border-style: solid;
      --live-ui-default-border-radius: 12px;
      --live-ui-default-border-color: var(--live-ui-theme-border-strong);
      appearance: none;
      display: var(--live-ui-display, inline-flex);
      width: var(--live-ui-width, auto);
      min-width: var(--live-ui-min-width, 0);
      min-height: var(--live-ui-min-height, 2.8rem);
      max-width: var(--live-ui-max-width, none);
      align-self: var(--live-ui-align-self, auto);
      align-items: var(--live-ui-align-items, center);
      justify-content: var(--live-ui-justify-content, center);
      gap: var(--live-ui-gap, 0.5rem);
      padding: var(--live-ui-padding, var(--live-ui-padding-block, var(--live-ui-default-padding-block)) var(--live-ui-padding-inline, var(--live-ui-default-padding-inline)));
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
      font: inherit;
      font-size: 0.92rem;
      font-weight: var(--live-ui-font-weight, 700);
      font-style: var(--live-ui-font-style, normal);
      letter-spacing: 0.02em;
      text-decoration: var(--live-ui-text-decoration, none);
      cursor: pointer;
      background: var(--live-ui-background, var(--live-ui-default-background, transparent));
      border-width: var(--live-ui-border-width, var(--live-ui-default-border-width));
      border-style: var(--live-ui-border-style, var(--live-ui-default-border-style));
      border-color: var(--live-ui-border-color, var(--live-ui-default-border-color));
      border-radius: var(--live-ui-border-radius, var(--live-ui-default-border-radius));
      transition:
        transform 120ms ease,
        box-shadow 160ms ease,
        filter 160ms ease,
        border-color 160ms ease;
    }

    .live-ui-button:hover {
      transform: translateY(-1px);
    }

    .live-ui-button:focus-visible {
      outline: 2px solid color-mix(in srgb, var(--live-ui-theme-accent) 82%, white);
      outline-offset: 2px;
    }

    .live-ui-button.live-ui-button-solid {
      --live-ui-default-foreground: #ffffff;
      --live-ui-default-background: linear-gradient(
        180deg,
        var(--live-ui-theme-accent) 0%,
        var(--live-ui-theme-accent-strong) 100%
      );
      --live-ui-default-border-color: color-mix(in srgb, var(--live-ui-theme-accent) 50%, white);
      box-shadow:
        inset 0 1px 0 hsl(0 0% 100% / 0.18),
        var(--live-ui-shadow-action);
    }

    .live-ui-button.live-ui-button-quiet {
      --live-ui-default-foreground: var(--live-ui-theme-accent);
      --live-ui-default-background: var(--live-ui-theme-accent-soft);
      --live-ui-default-border-color: color-mix(in srgb, var(--live-ui-theme-accent) 30%, transparent);
      box-shadow: none;
    }

    .live-ui-button.is-disabled,
    .live-ui-button:disabled {
      cursor: not-allowed;
      filter: saturate(0.7);
      transform: none;
    }

    .live-ui-text-input {
      --live-ui-default-padding-inline: 0.85rem;
      --live-ui-default-padding-block: 0.7rem;
      --live-ui-default-border-width: 1px;
      --live-ui-default-border-style: solid;
      --live-ui-default-border-radius: 12px;
      --live-ui-default-border-color: var(--live-ui-theme-border-strong);
      --live-ui-default-background: color-mix(in srgb, var(--live-ui-theme-surface-base) 92%, white 8%);
      width: var(--live-ui-width, 100%);
      min-height: var(--live-ui-min-height, 2.8rem);
      max-width: var(--live-ui-max-width, none);
      padding: var(--live-ui-padding, var(--live-ui-padding-block, var(--live-ui-default-padding-block)) var(--live-ui-padding-inline, var(--live-ui-default-padding-inline)));
      margin: var(--live-ui-margin, var(--live-ui-margin-block, 0) var(--live-ui-margin-inline, 0));
      font: inherit;
      font-weight: var(--live-ui-font-weight, inherit);
      font-style: var(--live-ui-font-style, normal);
      text-decoration: var(--live-ui-text-decoration, none);
      border-width: var(--live-ui-border-width, var(--live-ui-default-border-width));
      border-style: var(--live-ui-border-style, var(--live-ui-default-border-style));
      border-color: var(--live-ui-border-color, var(--live-ui-default-border-color));
      border-radius: var(--live-ui-border-radius, var(--live-ui-default-border-radius));
      background: var(--live-ui-background, var(--live-ui-default-background));
    }

    .live-ui-text-input.live-ui-text-input-filled {
      --live-ui-default-background: var(--live-ui-theme-surface-panel);
    }

    .live-ui-text-input.live-ui-text-input-subtle {
      --live-ui-default-background: var(--live-ui-theme-surface-base);
    }

    .live-ui-text-input.is-focused,
    .live-ui-text-input:focus-visible {
      --live-ui-default-border-color: var(--live-ui-theme-accent);
      box-shadow: 0 0 0 3px color-mix(in srgb, var(--live-ui-theme-accent) 18%, transparent);
      outline: none;
    }

    .live-ui-text-input:disabled,
    .live-ui-text-input.is-disabled {
      cursor: not-allowed;
      filter: saturate(0.7);
    }

    [data-live-ui-widget="dialog"],
    [data-live-ui-widget="alert-dialog"],
    .live-ui-dialog,
    .live-ui-alert-dialog {
      display: grid;
      gap: var(--live-ui-gap, 1rem);
      width: min(100%, var(--live-ui-width, 32rem));
      padding: var(--live-ui-padding, 1rem);
      margin: 0 auto;
      border-width: var(--live-ui-border-width, 1px);
      border-style: var(--live-ui-border-style, solid);
      border-color: var(--live-ui-border-color, var(--live-ui-theme-border-strong));
      border-radius: var(--live-ui-border-radius, var(--live-ui-radius-lg));
      background: var(--live-ui-background, color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, black));
      box-shadow:
        var(--live-ui-box-shadow, 0 22px 48px hsl(222 47% 6% / 0.32)),
        inset 0 1px 0 hsl(0 0% 100% / 0.06);
      box-sizing: border-box;
    }

    [data-live-ui-widget="dialog"][data-live-ui-open="false"],
    [data-live-ui-widget="alert-dialog"][data-live-ui-open="false"] {
      display: none;
    }

    [data-live-ui-dialog-slot="header"],
    [data-live-ui-alert-slot="header"] {
      display: grid;
      gap: 0.35rem;
    }

    [data-live-ui-dialog-slot="header"] > h2,
    [data-live-ui-alert-slot="header"] > h2 {
      margin: 0;
      font-size: 1.05rem;
      line-height: 1.25;
    }

    [data-live-ui-dialog-slot="content"],
    [data-live-ui-alert-slot="content"] {
      display: grid;
      gap: 0.85rem;
    }

    [data-live-ui-dialog-slot="actions"],
    [data-live-ui-alert-slot="actions"] {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 0.75rem;
    }

    [data-live-ui-widget="alert-dialog"][data-live-ui-severity="critical"],
    .live-ui-alert-dialog-critical {
      --live-ui-border-color: var(--live-ui-theme-critical);
      --live-ui-background: color-mix(in srgb, var(--live-ui-theme-surface-panel) 86%, var(--live-ui-theme-critical) 14%);
    }

    [data-live-ui-widget="alert-dialog"][data-live-ui-severity="warning"],
    .live-ui-alert-dialog-warning {
      --live-ui-border-color: var(--live-ui-theme-warning);
      --live-ui-background: color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, var(--live-ui-theme-warning) 12%);
    }
    """
  end

  defp advanced_css do
    ~S"""
    [data-live-ui-widget="tabs"],
    [data-live-ui-widget="list"],
    [data-live-ui-widget="tree-view"],
    [data-live-ui-widget="markdown-viewer"],
    [data-live-ui-widget="stream-widget"],
    [data-live-ui-widget="cluster-dashboard"],
    [data-live-ui-widget="status"],
    [data-live-ui-widget="inline-feedback"],
    [data-live-ui-widget="toast"],
    [data-live-ui-widget="bar-chart"],
    [data-live-ui-widget="line-chart"],
    .live-ui-toast {
      width: var(--live-ui-width, auto);
      min-width: var(--live-ui-min-width, 0);
      max-width: var(--live-ui-max-width, none);
      padding: var(--live-ui-padding, 0.95rem);
      margin: var(--live-ui-margin, 0);
      border-width: var(--live-ui-border-width, 1px);
      border-style: var(--live-ui-border-style, solid);
      border-color: var(--live-ui-border-color, var(--live-ui-theme-border-muted));
      border-radius: var(--live-ui-border-radius, var(--live-ui-radius-lg));
      background: var(--live-ui-background, color-mix(in srgb, var(--live-ui-theme-surface-panel) 86%, black));
      color: var(--live-ui-foreground, var(--live-ui-theme-foreground));
      box-sizing: border-box;
    }

    [data-live-ui-widget="tabs"] {
      display: grid;
      gap: 0.85rem;
    }

    [data-live-ui-widget="tabs"] [role="tablist"] {
      display: flex;
      flex-wrap: wrap;
      gap: 0.65rem;
    }

    [data-live-ui-widget="tabs"] [role="tab"] {
      appearance: none;
      border: 1px solid color-mix(in srgb, var(--live-ui-theme-border-strong) 88%, transparent);
      border-radius: 999px;
      background: color-mix(in srgb, var(--live-ui-theme-surface-base) 88%, white 12%);
      color: inherit;
      padding: 0.55rem 0.95rem;
      font: inherit;
      cursor: pointer;
      transition: border-color 140ms ease, background 140ms ease, transform 120ms ease;
    }

    [data-live-ui-widget="tabs"] [role="tab"]:hover {
      transform: translateY(-1px);
    }

    [data-live-ui-widget="tabs"] [role="tab"][aria-selected="true"] {
      border-color: var(--live-ui-theme-accent);
      background: color-mix(in srgb, var(--live-ui-theme-accent) 18%, transparent);
      color: color-mix(in srgb, var(--live-ui-theme-accent) 82%, white);
      box-shadow: inset 0 1px 0 hsl(0 0% 100% / 0.08);
    }

    [data-live-ui-widget="tabs"] [role="tab"]:disabled {
      cursor: not-allowed;
      filter: saturate(0.4);
      opacity: 0.72;
    }

    [data-live-ui-widget="list"],
    [data-live-ui-widget="tree-view"],
    [data-live-ui-widget="stream-widget"],
    [data-live-ui-widget="cluster-dashboard"] {
      display: grid;
      gap: 0.8rem;
    }

    [data-live-ui-widget="list"] ul,
    [data-live-ui-widget="list"] ol,
    [data-live-ui-widget="tree-view"] ul,
    [data-live-ui-widget="cluster-dashboard"] ul {
      list-style: none;
      display: grid;
      gap: 0.6rem;
      margin: 0;
      padding: 0;
    }

    [data-live-ui-widget="tree-view"] ul ul {
      margin-left: 1rem;
      padding-left: 0.75rem;
      border-left: 1px solid color-mix(in srgb, var(--live-ui-theme-border-muted) 82%, transparent);
    }

    [data-live-ui-widget="list"] li,
    [data-live-ui-widget="tree-view"] li,
    [data-live-ui-widget="cluster-dashboard"] li {
      display: grid;
      gap: 0.25rem;
      padding: 0.7rem 0.85rem;
      border: 1px solid color-mix(in srgb, var(--live-ui-theme-border-muted) 88%, transparent);
      border-radius: calc(var(--live-ui-radius-md) - 2px);
      background: color-mix(in srgb, var(--live-ui-theme-surface-base) 92%, white 8%);
    }

    [data-live-ui-widget="list"] li[data-selected="true"],
    [data-live-ui-widget="tree-view"] li[data-selected="true"] {
      border-color: var(--live-ui-theme-accent);
      background: color-mix(in srgb, var(--live-ui-theme-accent) 14%, transparent);
    }

    [data-live-ui-widget="tree-view"] li[data-expanded="true"] > span {
      font-weight: 700;
    }

    [data-live-ui-widget="status"],
    [data-live-ui-widget="inline-feedback"],
    [data-live-ui-widget="toast"],
    .live-ui-toast {
      display: flex;
      gap: 0.7rem;
      align-items: flex-start;
      line-height: 1.5;
      box-shadow: 0 14px 28px hsl(222 47% 8% / 0.18);
    }

    [data-live-ui-widget="status"][data-live-ui-severity="success"],
    [data-live-ui-widget="inline-feedback"][data-live-ui-severity="success"],
    [data-live-ui-widget="toast"][data-live-ui-severity="success"] {
      --live-ui-border-color: var(--live-ui-theme-success);
      --live-ui-background: color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, var(--live-ui-theme-success) 12%);
    }

    [data-live-ui-widget="status"][data-live-ui-severity="warning"],
    [data-live-ui-widget="inline-feedback"][data-live-ui-severity="warning"],
    [data-live-ui-widget="toast"][data-live-ui-severity="warning"] {
      --live-ui-border-color: var(--live-ui-theme-warning);
      --live-ui-background: color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, var(--live-ui-theme-warning) 12%);
    }

    [data-live-ui-widget="status"][data-live-ui-severity="critical"],
    [data-live-ui-widget="inline-feedback"][data-live-ui-severity="critical"],
    [data-live-ui-widget="toast"][data-live-ui-severity="critical"] {
      --live-ui-border-color: var(--live-ui-theme-critical);
      --live-ui-background: color-mix(in srgb, var(--live-ui-theme-surface-panel) 86%, var(--live-ui-theme-critical) 14%);
    }

    [data-live-ui-widget="toast"][data-live-ui-open="false"] {
      display: none;
    }

    [data-live-ui-widget="markdown-viewer"] pre {
      margin: 0;
      white-space: pre-wrap;
      font-family: ui-monospace, "SFMono-Regular", Menlo, monospace;
      line-height: 1.65;
    }

    [data-live-ui-widget="bar-chart"],
    [data-live-ui-widget="line-chart"] {
      position: relative;
      min-height: 14rem;
      overflow: hidden;
      isolation: isolate;
      background-image:
        linear-gradient(180deg, transparent 0%, hsl(0 0% 100% / 0.03) 100%),
        repeating-linear-gradient(
          to top,
          transparent 0,
          transparent calc(25% - 1px),
          hsl(0 0% 100% / 0.05) calc(25% - 1px),
          hsl(0 0% 100% / 0.05) 25%
        );
    }

    [data-live-ui-widget="bar-chart"]::before,
    [data-live-ui-widget="line-chart"]::before {
      content: "";
      position: absolute;
      inset: auto 0 0 0;
      pointer-events: none;
    }

    [data-live-ui-widget="bar-chart"]::before {
      height: 62%;
      background:
        linear-gradient(90deg,
          hsl(217 91% 60% / 0.8) 8%,
          hsl(217 91% 60% / 0.8) 18%,
          transparent 18%,
          transparent 28%,
          hsl(160 84% 39% / 0.78) 28%,
          hsl(160 84% 39% / 0.78) 38%,
          transparent 38%,
          transparent 48%,
          hsl(38 92% 50% / 0.78) 48%,
          hsl(38 92% 50% / 0.78) 58%,
          transparent 58%,
          transparent 68%,
          hsl(0 84% 60% / 0.78) 68%,
          hsl(0 84% 60% / 0.78) 78%,
          transparent 78%
        );
      mask: linear-gradient(180deg, transparent 0%, black 30%);
    }

    [data-live-ui-widget="line-chart"]::before {
      inset: 20% 1rem 1.25rem 1rem;
      border-top: 2px solid color-mix(in srgb, var(--live-ui-theme-accent) 74%, white);
      border-right: 2px solid transparent;
      border-radius: 999px;
      transform: skewY(-10deg) scaleY(1.1);
      box-shadow: 0 0 0 1px hsl(0 0% 100% / 0.04);
    }

    [data-live-ui-widget="cluster-dashboard"] header {
      min-height: 1rem;
    }

    [data-live-ui-widget="cluster-dashboard"] li[data-status="up"] {
      border-color: var(--live-ui-theme-success);
    }

    [data-live-ui-widget="cluster-dashboard"] li[data-status="degraded"] {
      border-color: var(--live-ui-theme-warning);
    }

    [data-live-ui-widget="cluster-dashboard"] li[data-status="down"] {
      border-color: var(--live-ui-theme-critical);
    }

    [data-live-ui-widget="stream-widget"] p {
      margin: 0;
      padding: 0.65rem 0.8rem;
      border-left: 3px solid color-mix(in srgb, var(--live-ui-theme-border-strong) 86%, transparent);
      background: color-mix(in srgb, var(--live-ui-theme-surface-base) 90%, white 10%);
      border-radius: 0.7rem;
    }

    [data-live-ui-widget="stream-widget"] p[data-severity="warning"] {
      border-left-color: var(--live-ui-theme-warning);
    }

    [data-live-ui-widget="stream-widget"] p[data-severity="critical"] {
      border-left-color: var(--live-ui-theme-critical);
    }

    [data-live-ui-widget="stream-widget"] p[data-severity="success"] {
      border-left-color: var(--live-ui-theme-success);
    }

    [data-live-ui-widget="tabs"][data-live-ui-state="focused"],
    [data-live-ui-widget="list"][data-live-ui-state="focused"],
    [data-live-ui-widget="tree-view"][data-live-ui-state="focused"],
    [data-live-ui-widget="toast"][data-live-ui-state="focused"] {
      box-shadow: 0 0 0 3px color-mix(in srgb, var(--live-ui-theme-accent) 18%, transparent);
    }

    [data-live-ui-widget="tabs"][data-live-ui-state="selected"],
    [data-live-ui-widget="list"][data-live-ui-state="selected"],
    [data-live-ui-widget="tree-view"][data-live-ui-state="selected"],
    [data-live-ui-widget="status"][data-live-ui-state="active"],
    [data-live-ui-widget="toast"][data-live-ui-state="active"],
    .live-ui-toast.is-active {
      --live-ui-border-color: var(--live-ui-theme-accent);
      box-shadow:
        0 0 0 1px color-mix(in srgb, var(--live-ui-theme-accent) 52%, transparent),
        0 18px 36px hsl(222 47% 8% / 0.2);
    }

    [data-live-ui-widget="tabs"][data-live-ui-state="disabled"],
    [data-live-ui-widget="list"][data-live-ui-state="disabled"],
    [data-live-ui-widget="tree-view"][data-live-ui-state="disabled"],
    [data-live-ui-widget="status"][data-live-ui-state="disabled"],
    [data-live-ui-widget="toast"][data-live-ui-state="disabled"] {
      filter: saturate(0.5);
      opacity: 0.7;
      pointer-events: none;
    }
    """
  end
end
