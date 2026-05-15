# Canonical Widget Component Examples

This page gives resource-authored examples for the Phase 31 canonical
widget-component catalog. The examples use canonical kinds, not `custom:*`,
because these surfaces are owned by the Unified UI catalog and adopted through
AshUI resource authority.

## Catalog Examples

| Family | Example canonical kinds | Resource-authoring note |
|---|---|---|
| Content, identity, and disclosure | `inline_rich_text_heading`, `avatar`, `disclosure` | Use semantic text segments, identity props, and open state as props on element resources. |
| Form control and composer | `runtime_form_shell`, `segmented_button_group`, `chat_composer` | Keep form and composer actions on the owning element through `ui_actions`. |
| Row and artifact | `list_item_multi_column`, `artifact_row` | Use row identity and column templates as props; avoid custom row shells for cataloged artifact rows. |
| Workflow, progress, and status | `pipeline_stepper_horizontal`, `segmented_progress_bar`, `workflow_stage_list_vertical`, `meter_thin` | Keep progress and workflow state in props that canonical validation can check. |
| Layer shell and callout | `sticky_frosted_header`, `slide_over_panel`, `event_callout` | Preserve accessible names, open state, and message text in canonical props. |
| Redline and code | `redline_inline`, `code_block_syntax_highlighted` | Provide explicit segment or token state instead of pre-rendered HTML. |
| Composition behavior | `list_repeat` | Declare repeat ownership through relationships and list bindings. |

## Heading And Identity

```elixir
ui_element do
  type(:inline_rich_text_heading)

  props(%{
    level: :h2,
    segments: [
      %{type: :text, value: "Canonical component review"}
    ]
  })

  metadata(%{id: "component_review_heading"})
end
```

```elixir
ui_element do
  type(:avatar)
  props(%{initials: "PC", accessibility_label: "Pascal Charbonneau"})
  metadata(%{id: "review_owner_avatar"})
end
```

## Form, Composer, Row, And Artifact

```elixir
ui_element do
  type(:runtime_form_shell)
  props(%{fields: [%{name: :email, label: "Email"}], submit_label: "Save"})
  metadata(%{id: "profile_form_shell"})
end
```

```elixir
ui_element do
  type(:segmented_button_group)

  props(%{
    options: [%{value: :all, label: "All"}, %{value: :mine, label: "Mine"}],
    active_value: :all
  })

  metadata(%{id: "review_filter_segmented_group"})
end
```

```elixir
ui_element do
  type(:artifact_row)

  props(%{
    row_identity: "adr-0007",
    title: "Canonical widget components",
    meta: %{status: :accepted}
  })

  metadata(%{id: "adr_0007_row"})
end
```

## Workflow, Progress, Layer, Callout, Redline, And Code

```elixir
ui_element do
  type(:pipeline_stepper_horizontal)
  props(%{steps: [%{id: :draft, label: "Draft"}], active_index: 0})
  metadata(%{id: "release_pipeline"})
end
```

```elixir
ui_element do
  type(:event_callout)
  props(%{message: "Deployment paused", tone: :warning})
  metadata(%{id: "deployment_pause_callout"})
end
```

```elixir
ui_element do
  type(:redline_inline)
  props(%{segments: [%{state: :insert, text: "new requirement"}]})
  metadata(%{id: "contract_redline"})
end
```

```elixir
ui_element do
  type(:code_block_syntax_highlighted)
  props(%{language: :elixir, tokens: [%{type: :keyword, text: "defmodule"}]})
  metadata(%{id: "example_code_block"})
end
```

## Relationship-Owned List Repeat

```elixir
ui_relationships do
  relationship :artifact_rows do
    kind(:child)
    slot(:body)
    placement(:append)
    repeat(%{binding: :artifact_rows, row_scope: :row, row_fields: [:id, :title, :status]})
  end
end
```

```elixir
ui_element do
  type(:list_repeat)
  props(%{row_fields: [:id, :title, :status]})
  metadata(%{id: "artifact_repeat"})
end

ui_bindings do
  binding :artifact_rows do
    source(%{resource: "Demo.Artifact", relationship: "artifacts"})
    target("artifact_rows")
    binding_type(:list)
  end
end
```

```elixir
ui_element do
  type(:artifact_row)

  props(%{
    row_identity: %{scope: :row, field: :id},
    title: %{scope: :row, field: :title},
    meta: %{status: %{scope: :row, field: :status}}
  })

  metadata(%{id: "artifact_row_template"})
end
```

The relationship keeps repeat ownership in the Ash resource graph. Hydration
uses the list binding rows to materialize concrete row children for fallback
renderers while preserving canonical `list_repeat` metadata.
