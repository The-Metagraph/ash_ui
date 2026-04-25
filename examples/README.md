# Ash UI Example Suite

This directory now serves as the maintained landing page for the checked-in Ash
UI example suite. The suite mirrors the current sibling `unified_ui/examples`
catalog by directory name while rebuilding each example through
resource-authority screens, related element resources, and the shared Ash HQ
visual contract.

## Maintained Inputs

- `examples/catalog.tsv` remains the planning crosswalk imported from the
  sibling suite.
- `examples/catalog_metadata.json` is the maintained machine-readable suite
  index for discovery, tooling, and review reporting.
- `examples/scaffold_contract.md` defines the per-app resource-authority app
  shape and review-surface contract.
- `examples/ash_hq_theme_baseline.md` and `examples/ash_hq_theme_tokens.css`
  define the shared Ash HQ shell and styling tokens every example app must use.

## Parity Labels

- `exact`: the example directory name and canonical Ash UI subject match.
- `normalized`: the directory name is preserved, but the canonical Ash UI
  subject differs.
- `composed`: the example is a named review pattern built from a screen plus
  related native widgets.
- `custom`: the example still depends on an explicit `custom:*` shell until a
  stable public widget contract exists.

## Suite Index

<!-- ash_ui:example-suite-index:start -->
| Directory | Title | Family | Phase | Canonical Subject | Parity | Runtime |
|---|---|---|---|---|---|---|
| `button` | Button Example | `content` | `18` | `button` | `exact` | `liveview` |
| `text` | Text Example | `content` | `18` | `text` | `exact` | `liveview` |
| `text_input` | Text Input Example | `input` | `18` | `input` | `normalized` | `liveview` |
| `box` | Box Example | `layout` | `18` | `container` | `composed` | `liveview` |
| `content` | Content Example | `layout` | `18` | `fragment` | `composed` | `liveview` |
| `icon` | Icon Example | `content` | `18` | `icon` | `exact` | `liveview` |
| `image` | Image Example | `content` | `18` | `image` | `exact` | `liveview` |
| `label` | Label Example | `content` | `18` | `label` | `exact` | `liveview` |
| `link` | Link Example | `content` | `18` | `custom:link` | `custom` | `liveview` |
| `separator` | Separator Example | `content` | `18` | `divider` | `normalized` | `liveview` |
| `spacer` | Spacer Example | `content` | `18` | `spacer` | `exact` | `liveview` |
| `checkbox` | Checkbox Example | `input` | `18` | `checkbox` | `exact` | `liveview` |
| `date_input` | Date Input Example | `input` | `18` | `input` | `normalized` | `liveview` |
| `field` | Field Example | `forms` | `18` | `form_field` | `normalized` | `liveview` |
| `field_group` | Field Group Example | `forms` | `18` | `custom:field_group` | `composed` | `liveview` |
| `file_input` | File Input Example | `input` | `18` | `input` | `normalized` | `liveview` |
| `form_builder` | Form Builder Example | `forms` | `18` | `form_builder` | `exact` | `liveview` |
| `numeric_input` | Numeric Input Example | `input` | `18` | `input` | `normalized` | `liveview` |
| `pick_list` | Pick List Example | `input` | `18` | `custom:pick_list` | `custom` | `liveview` |
| `radio_group` | Radio Group Example | `input` | `18` | `radio` | `normalized` | `liveview` |
| `select` | Select Example | `input` | `18` | `select` | `exact` | `liveview` |
| `time_input` | Time Input Example | `input` | `18` | `input` | `normalized` | `liveview` |
| `toggle` | Toggle Example | `input` | `18` | `switch` | `normalized` | `liveview` |
| `row` | Row Example | `layout` | `19` | `row` | `exact` | `liveview` |
| `column` | Column Example | `layout` | `19` | `column` | `exact` | `liveview` |
| `grid` | Grid Example | `layout` | `19` | `grid` | `exact` | `liveview` |
| `viewport` | Viewport Example | `display` | `19` | `custom:viewport` | `custom` | `liveview` |
| `scroll_bar` | Scroll Bar Example | `display` | `19` | `custom:scroll_bar` | `custom` | `liveview` |
| `split_pane` | Split Pane Example | `display` | `19` | `custom:split_pane` | `custom` | `liveview` |
| `canvas` | Canvas Example | `display` | `19` | `custom:canvas` | `custom` | `liveview` |
| `overlay` | Overlay Example | `overlay` | `20` | `custom:overlay` | `custom` | `liveview` |
| `dialog` | Dialog Example | `overlay` | `20` | `custom:dialog` | `custom` | `liveview` |
| `alert_dialog` | Alert Dialog Example | `overlay` | `20` | `custom:alert_dialog` | `custom` | `liveview` |
| `context_menu` | Context Menu Example | `overlay` | `20` | `custom:context_menu` | `custom` | `liveview` |
| `toast` | Toast Example | `overlay` | `20` | `custom:toast` | `custom` | `liveview` |
| `stream_widget` | Stream Widget Example | `operational` | `20` | `screen` | `composed` | `liveview` |
| `process_monitor` | Process Monitor Example | `operational` | `20` | `screen` | `composed` | `liveview` |
| `supervision_tree_viewer` | Supervision Tree Viewer Example | `operational` | `20` | `screen` | `composed` | `liveview` |
| `cluster_dashboard` | Cluster Dashboard Example | `operational` | `20` | `screen` | `composed` | `liveview` |
| `menu` | Menu Example | `navigation` | `19` | `custom:menu` | `custom` | `liveview` |
| `tabs` | Tabs Example | `navigation` | `19` | `custom:tabs` | `custom` | `liveview` |
| `command_palette` | Command Palette Example | `navigation` | `19` | `custom:command_palette` | `custom` | `liveview` |
| `list` | List Example | `data` | `20` | `list` | `exact` | `liveview` |
| `table` | Table Example | `data` | `20` | `table` | `exact` | `liveview` |
| `tree_view` | Tree View Example | `data` | `20` | `custom:tree_view` | `custom` | `liveview` |
| `markdown_viewer` | Markdown Viewer Example | `data` | `20` | `custom:markdown_viewer` | `custom` | `liveview` |
| `log_viewer` | Log Viewer Example | `data` | `20` | `custom:log_viewer` | `custom` | `liveview` |
| `status` | Status Example | `feedback` | `20` | `badge` | `normalized` | `liveview` |
| `progress` | Progress Example | `feedback` | `20` | `custom:progress` | `custom` | `liveview` |
| `gauge` | Gauge Example | `feedback` | `20` | `custom:gauge` | `custom` | `liveview` |
| `inline_feedback` | Inline Feedback Example | `feedback` | `20` | `custom:inline_feedback` | `composed` | `liveview` |
| `sparkline` | Sparkline Example | `feedback` | `20` | `custom:sparkline` | `custom` | `liveview` |
| `bar_chart` | Bar Chart Example | `feedback` | `20` | `custom:bar_chart` | `custom` | `liveview` |
| `line_chart` | Line Chart Example | `feedback` | `20` | `custom:line_chart` | `custom` | `liveview` |
<!-- ash_ui:example-suite-index:end -->

## Shared Contracts

- every checked-in directory remains one standalone Mix project
- every example persists its screen through `AshUI.Resource.Authority`
- every example foregrounds the shared Ash HQ shell, one meaningful
  interaction story, and one canonical signal preview
- unsupported or partial surfaces stay called out explicitly in metadata and
  app-local docs rather than implied silently
