# Canonical Widget Component Examples

This page gives resource-authored examples for the Phase 31 canonical
widget-component catalog. The examples use canonical kinds, not `custom:*`,
because these surfaces are owned by the Unified UI catalog and adopted through
AshUI resource authority.

## Catalog Examples

| Family | Example canonical kinds | Resource-authoring note |
|---|---|---|
| Content, identity, and disclosure | `inline_rich_text_heading`, `avatar`, `disclosure` | Use semantic text segments, identity props, and open state as props on element resources. |
| Form control and composer | `runtime_form_shell`, `segmented_button_group`, `chat_composer`, `collection_picker` | Keep form, composer, and picker actions on the owning element through `ui_actions`. |
| Row and artifact | `list_item_multi_column`, `artifact_row`, `thread_card` | Use row identity, artifact metadata, or thread identity as props; avoid custom row shells for cataloged artifact rows. |
| Workflow, progress, and status | `pipeline_stepper_horizontal`, `segmented_progress_bar`, `workflow_stage_list_vertical`, `meter_thin`, `workflow_progress_status_card` | Keep progress and workflow state in props that canonical validation can check. |
| Layer shell and callout | `sticky_frosted_header`, `slide_over_panel`, `event_callout`, `right_rail` | Preserve accessible names, open state, message text, and rail panel descriptors in canonical props. |
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
  type(:collection_picker)

  props(%{
    picker_id: "sources",
    query: "adr",
    filters: [%{id: "all", label: "All", selected?: true}],
    items: [%{id: "adr-0007", label: "ADR-0007", description: "Canonical widget components"}],
    suggestions: [%{id: "suggestion-1", label: "Add ADR-0008", source: "review"}]
  })

  metadata(%{id: "source_collection_picker"})
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
  type(:workflow_progress_status_card)

  props(%{
    subject_id: "subject:ash_ui",
    name: "ash_ui",
    path: "workspaces/ash_ui",
    progress_pct: 0.72,
    active_count: 4,
    blocked_count: 1
  })

  metadata(%{id: "workflow_health_card"})
end
```

Dependency-focused cards keep `depends_on` and `depended_by` as ordered edge
descriptors, not display text.

```elixir
ui_element do
  type(:workflow_progress_status_card)

  props(%{
    subject_id: "subject:release-readiness",
    name: "Release readiness",
    progress_pct: 0.84,
    active_count: 2,
    blocked_count: 1,
    depends_on: [
      %{id: "subject:unified_iur", label: "Unified IUR", state: :done},
      %{id: "subject:unified_ui", label: "Unified UI", state: :active}
    ],
    depended_by: [
      %{id: "subject:live_ui", label: "Live UI", state: :blocked}
    ],
    selected?: true,
    open_action: %{label: "Open", intent: :open_subject, visible_when: :when_selected}
  })

  metadata(%{id: "release_readiness_card"})
end
```

Canonical signal previews should show semantic open, focus, and dependency
selection interactions instead of renderer-specific event attributes.

```elixir
UnifiedIUR.Widgets.Components.workflow_progress_status_card(
  id: "release-readiness-card",
  subject_id: "subject:release-readiness",
  name: "Release readiness",
  progress_pct: 0.84,
  active_count: 2,
  blocked_count: 1,
  depends_on: ["subject:unified_iur", "subject:unified_ui"],
  depended_by: ["subject:live_ui"],
  focus_interaction:
    UnifiedIUR.Interaction.focus(
      intent: :focus_subject,
      entity: "subject:release-readiness"
    ),
  dependency_select_interaction:
    UnifiedIUR.Interaction.selection(
      intent: :select_dependency,
      entity: "subject:release-readiness"
    ),
  open_action: %{
    label: "Open",
    intent: :open_subject,
    interaction:
      UnifiedIUR.Interaction.open(
        intent: :open_subject,
        entity: "subject:release-readiness"
      )
  }
)
```

```elixir
ui_element do
  type(:event_callout)
  props(%{message: "Deployment paused", tone: :warning})
  metadata(%{id: "deployment_pause_callout"})
end
```

## Reusable Right Rail

Generic inspector rails use the canonical `right_rail` type directly. Panel
descriptors stay domain-neutral, and each `content_slot` points to a
relationship-owned panel body.

```elixir
ui_element do
  type(:right_rail)

  props(%{
    side: :right,
    active_panel: :summary,
    collapsed?: false,
    collapsible?: true,
    density: :compact,
    panels: [
      %{id: :summary, label: "Summary", content_slot: :summary_body},
      %{id: :activity, label: "Activity", badge: "3", content_slot: :activity_body},
      %{
        id: :sources,
        label: "Sources",
        disabled?: true,
        empty_state: "No sources available",
        content_slot: :sources_body
      }
    ]
  })

  metadata(%{id: "workspace_inspector_rail"})
end
```

```elixir
ui_relationships do
  relationship :summary_panel do
    kind(:child)
    slot(:summary_body)
    placement(:append)
    order(0)
  end

  relationship :activity_panel do
    kind(:child)
    slot(:activity_body)
    placement(:append)
    order(1)
  end
end
```

Document-oriented rails are application compositions that emit the same
canonical kind. The resource, module, or example may use a document name, but
the authored widget type remains `right_rail`; do not author `doc_right_rail`
as package vocabulary.

```elixir
defmodule MyApp.Documents.DocumentContextRail do
  use Ash.Resource, domain: MyApp.Documents.UIDomain, data_layer: Ash.DataLayer.Ets
  use AshUI.Resource.DSL.Element

  ui_element do
    type(:right_rail)

    props(%{
      active_panel: :outline,
      panels: [
        %{id: :outline, label: "Outline", content_slot: :outline_body},
        %{id: :comments, label: "Comments", badge: "8", content_slot: :comments_body},
        %{id: :sources, label: "Sources", empty_state: "No linked sources"}
      ]
    })

    metadata(%{id: "document_context_rail", composition: "document rail"})
  end
end
```

Canonical signal previews should show semantic selection and collapse
interactions instead of renderer-specific event attributes.

```elixir
UnifiedIUR.Widgets.Components.right_rail(
  id: "workspace-inspector-rail",
  panels: [
    %{id: :summary, label: "Summary", content_slot: :summary_body},
    %{id: :activity, label: "Activity", badge: "3", content_slot: :activity_body}
  ],
  active_panel: :summary,
  interactions: [
    UnifiedIUR.Interaction.selection(
      intent: :select_panel,
      element_id: "workspace-inspector-rail",
      mapping: %{selected_value: :id}
    ),
    UnifiedIUR.Interaction.change(
      intent: :toggle_rail,
      element_id: "workspace-inspector-rail",
      mapping: %{collapsed?: :collapsed?}
    )
  ]
)
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
