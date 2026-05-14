# UnifiedUi Widget Catalog

This guide summarizes the authored widget and construct families currently
available in `UnifiedUi`.

Every widget shares a common baseline schema:

- `id`: stable authored node id
- `description`, `authored_ref`, `annotations`, `tags`
- `variant`, `tone`
- `theme_ref`, `style_refs`, `style`
- `interaction_refs`, `binding_refs`
- `accessibility_label`, `accessibility_description`
- `disabled?`

## Foundational Widgets

| Widget | Purpose | Key authored fields |
| --- | --- | --- |
| `text` | Display text content | `value`, `role` |
| `label` | Label another control | `value`, `target` |
| `icon` | Icon glyph | `name`, `set`, `fallback_text` |
| `image` | Image/media content | `source`, `alt_text`, `media_type`, `fit` |
| `badge` | Small status label | `value`, `name`, `set`, `presentation` |
| `button` | Action trigger | `label`, `action_intent`, `emphasis` |
| `link` | Navigation link | `label`, `target`, `external?`, `target_kind`, `navigation_target` |
| `separator` | Visual divider | `orientation`, `decorative?` |
| `spacer` | Intentional empty space | `size`, `grow` |
| `content` | Group foundational children | `role`, `presentation`, `summary` |
| `hero` | Large lead section | `eyebrow`, `title`, `message`, `align`, `summary` |

Example:

```elixir
box :intro do
  text :headline do
    value("UnifiedUi")
  end

  badge :status_badge do
    value("Preview")
    presentation(:pill)
  end

  button :start_button do
    label("Get started")
    action_intent(:start)
  end
end
```

## Input Widgets

| Widget | Purpose | Key authored fields |
| --- | --- | --- |
| `text_input` | Freeform text | `placeholder`, `value_path`, `default_value`, `multiline?`, `input_mode` |
| `numeric_input` | Numeric entry | `placeholder`, `value_path`, `default_value`, `min`, `max`, `step` |
| `toggle` | Boolean switch | `label`, `value_path`, `default_value` |
| `checkbox` | Boolean checkbox | `label`, `value_path`, `default_value` |
| `radio_group` | Single choice from options | `label`, `options`, `value_path`, `default_value` |
| `select` | Select dropdown | `label`, `options`, `value_path`, `default_value`, `multiple?` |
| `pick_list` | Multi-select list | `label`, `options`, `value_path`, `default_value`, `multiple?` |
| `date_input` | Date input | `value_path`, `default_value`, `format`, `min`, `max` |
| `time_input` | Time input | `value_path`, `default_value`, `format`, `min`, `max`, `step` |
| `file_input` | File selection | `label`, `value_path`, `accept`, `multiple?`, `capture` |

Example:

```elixir
field :email do
  field_name(:email)
  label("Email")
  value_path([:profile, :email])

  text_input :email_input do
    placeholder("name@example.com")
    input_mode(:email)
  end
end
```

## Navigation and Form Workflow Widgets

| Widget | Purpose | Key authored fields |
| --- | --- | --- |
| `menu` | Menu of named items | `items`, `active_item`, `orientation` |
| `tabs` | Tabbed navigation | `items`, `active_item`, `orientation` |
| `command_palette` | Command chooser | `items`, `label`, `summary` |
| `form_builder` | Form root | `summary`, `submit_intent` |
| `field_group` | Group form fields | `legend`, `summary` |
| `field` | Named field container | `field_name`, `label`, `help`, `value_path`, `default_value` |
| `form_field` | Alternate field container | `field_name`, `label`, `help`, `value_path`, `default_value` |

Example:

```elixir
form_builder :profile_form do
  submit_intent(:save_profile)

  field_group :identity do
    legend("Identity")

    field :display_name do
      field_name(:display_name)
      label("Display name")

      text_input :display_name_input do
        placeholder("Display name")
      end
    end
  end

  tabs :profile_tabs do
    items(profile: "Profile", permissions: "Permissions")
    active_item(:profile)
  end
end
```

## Data, Feedback, and Operational Widgets

| Widget | Purpose | Key authored fields |
| --- | --- | --- |
| `list` | Ordered or unordered list | `items`, `ordered?`, `selection_mode`, `empty_state`, `summary` |
| `table` | Tabular data | `table_columns`, `table_rows`, `empty_state`, `summary` |
| `tree_view` | Hierarchical data | `tree_nodes`, `expanded?`, `empty_state`, `summary` |
| `stat` | Title/value metric | `title`, `value`, `message`, `summary` |
| `key_value` | Label/value pair | `label`, `value`, `description`, `summary` |
| `info_list` | Descriptive item list | `items`, `ordered?`, `empty_state`, `summary` |
| `markdown_viewer` | Render markdown source | `source`, `presentation`, `summary` |
| `log_viewer` | Log/event stream | `log_entries`, `show_timestamps?`, `wrap?`, `empty_state`, `summary` |
| `status` | Short status indicator | `value`, `severity`, `status`, `summary` |
| `progress` | Progress surface | `current`, `maximum`, `label`, `severity`, `status`, `indeterminate?`, `summary` |
| `gauge` | Gauge meter | `current`, `minimum`, `maximum`, `label`, `severity`, `status`, `summary` |
| `inline_feedback` | Inline message | `title`, `message`, `severity`, `status`, `summary` |
| `sparkline` | Small trend line | `points`, `summary` |
| `bar_chart` | Bar chart | `series`, `x_label`, `y_label`, `empty_state`, `summary` |
| `line_chart` | Line chart | `series`, `x_label`, `y_label`, `empty_state`, `summary` |
| `stream_widget` | Append-oriented event stream | `entries`, `ordering`, `severity_field`, `timestamp_field`, `summary` |
| `process_monitor` | Process list | `processes`, `sort_by`, `severity`, `summary` |
| `supervision_tree_viewer` | Supervision topology | `topology`, `expanded?`, `summary` |
| `cluster_dashboard` | Cluster health surface | `cluster_nodes`, `metrics`, `severity`, `summary` |

Example:

```elixir
column :operations_shell do
  table :deployments_table do
    table_columns(name: "Name", status: "Status")
    table_rows([
      [name: "API", status: "Healthy"],
      [name: "Web", status: "Degraded"]
    ])
  end

  gauge :cpu_gauge do
    current(72)
    maximum(100)
    severity(:warning)
  end
end
```

## When to Use the Package Examples

If you want real end-to-end authored references instead of isolated snippets,
inspect:

- `UnifiedUi.Examples.FoundationalScreen`
- `UnifiedUi.Examples.ProfileForm`
- `UnifiedUi.Examples.OperationsDashboard`
- `UnifiedUi.Examples.ThemedSignalWorkspace`
