defmodule UnifiedUi.OperationalWidgetComponentsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule OperationalComponentsScreen do
    use UnifiedUi.Dsl

    identity do
      id(:operational_components_screen)
      authored_ref([:examples, :operational_components_screen])
    end

    composition do
      root(:operational_components_root)
      mode(:screen)

      list_item_multi_column :task_row do
        row_identity("task-1")
        column_template([%{id: :title, label: "Title"}, %{id: :owner, label: "Owner"}])
        active?(true)
        link_target("/tasks/1")
        action_intent(:open_task)

        text :task_title do
          value("Review ADR")
        end

        badge :task_owner do
          value("PC")
        end
      end

      artifact_row :adr_artifact do
        title("Widget component ADR")
        meta(%{status: :accepted})
        artifact_kind(:doc)
        status_badges([%{label: "Accepted", tone: :positive}])
        counts(%{comments: 4})
        timestamp_at("2026-05-18T10:00:00Z")
        row_identity(:adr_widget_components)
        active?(true)
        link_target("/artifacts/widget-components")
        action_intent(:open_artifact)

        button :artifact_action do
          label("Open")
        end
      end

      pipeline_stepper_horizontal :release_steps do
        steps([
          %{id: :draft, label: "Draft", state: :done},
          %{id: :review, label: "Review", state: :active},
          %{id: :ship, label: "Ship", state: :pending}
        ])

        active_index(1)
        completed_indices([0])
        navigation_intent(:select_release_step)
      end

      segmented_progress_bar :quality_bar do
        segments([
          %{label: "Passing", weight: 8, state: :success},
          %{label: "Failing", weight: 1, state: :error}
        ])

        aggregate_progress(%{current: 8, maximum: 9})
        label("Scenario health")
      end

      workflow_stage_list_vertical :review_stages do
        stages([
          %{id: :authored, label: "Authored", state: :done},
          %{id: :implemented, label: "Implemented", state: :active}
        ])

        active_index(1)
      end

      meter_thin :coverage_meter do
        current(82.5)
        minimum(0)
        maximum(100)
        label("Coverage")
        state(:success)
      end

      sticky_frosted_header :workspace_header do
        title("Workspace")
        leading([:back_button])
        trailing([:save_button])

        button :save_button do
          label("Save")
        end
      end

      slide_over_panel :details_panel do
        accessibility_label("Details")
        open?(true)
        size(:wide)
        dismiss_intent(:close_details)

        text :details_body do
          value("Panel content")
        end
      end

      event_callout :incident_callout do
        tone(:warning)
        eyebrow("Deploy")
        title("Delayed")
        message("Rollout paused for review")
        action_intent(:open_incident)

        button :callout_action do
          label("Inspect")
        end
      end

      composer_query_preview :query_preview do
        composer_id("composer-main")
        query("release blockers")
        preview_state(:ready)
        explanation("Three likely blockers found.")
        metrics(%{results_count: 3, duration_ms: 42, sources_visited: 8})
        findings([%{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}])
        max_findings_shown(2)
        open_intent(:open_query_preview)
        save_intent(:save_query)
        dismiss_intent(:dismiss_query_preview)
      end

      redline_inline :copy_redline do
        segments([
          %{state: :keep, text: "Keep this "},
          %{state: :delete, text: "old"},
          %{state: :insert, text: "new"}
        ])
      end

      code_block_syntax_highlighted :code_sample do
        language(:elixir)

        tokens([
          %{type: :keyword, text: "defmodule"},
          %{type: :text, text: " Demo"}
        ])
      end
    end
  end

  test "registers authored operational widget component kinds" do
    assert UnifiedUi.Widgets.row_artifact_component_kinds() == [
             :list_item_multi_column,
             :artifact_row,
             :thread_card
           ]

    assert UnifiedUi.Widgets.workflow_component_kinds() == [
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin,
             :workflow_progress_status_card
           ]

    assert UnifiedUi.Widgets.layer_callout_component_kinds() == [
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout,
             :composer_query_preview,
             :propose_new_doc_card,
             :right_rail
           ]

    assert UnifiedUi.Widgets.redline_code_component_kinds() == [
             :redline_inline,
             :code_block_syntax_highlighted
           ]
  end

  test "stores row, workflow, layer, callout, redline, and code components" do
    entities = Extension.get_entities(OperationalComponentsScreen, [:composition])
    by_id = Map.new(entities, &{&1.id, &1})

    assert {by_id.task_row.family, by_id.task_row.kind, by_id.task_row.row_identity,
            by_id.task_row.active?, by_id.task_row.action_intent} ==
             {:row_and_artifact, :list_item_multi_column, "task-1", true, :open_task}

    assert Enum.map(by_id.task_row.children, & &1.kind) == [:text, :badge]

    assert {by_id.adr_artifact.family, by_id.adr_artifact.kind, by_id.adr_artifact.title,
            by_id.adr_artifact.artifact_kind, by_id.adr_artifact.meta.status} ==
             {:row_and_artifact, :artifact_row, "Widget component ADR", :doc, :accepted}

    assert {by_id.release_steps.family, by_id.release_steps.kind,
            by_id.release_steps.active_index, by_id.release_steps.navigation_intent} ==
             {:workflow_progress_and_status, :pipeline_stepper_horizontal, 1,
              :select_release_step}

    assert {by_id.details_panel.family, by_id.details_panel.kind, by_id.details_panel.open?,
            by_id.details_panel.modal?} ==
             {:layer_shell_and_callout, :slide_over_panel, true, false}

    assert {by_id.query_preview.family, by_id.query_preview.kind, by_id.query_preview.query,
            by_id.query_preview.preview_state} ==
             {:layer_shell_and_callout, :composer_query_preview, "release blockers", :ready}

    assert {by_id.copy_redline.family, by_id.copy_redline.kind, by_id.copy_redline.text_safety} ==
             {:redline_and_code, :redline_inline, :plain_text}

    assert {by_id.code_sample.family, by_id.code_sample.kind, by_id.code_sample.language} ==
             {:redline_and_code, :code_block_syntax_highlighted, :elixir}
  end

  test "summarizes operational components without a renderer runtime" do
    summary =
      OperationalComponentsScreen
      |> UnifiedUi.Info.composition_summary()
      |> Map.new(&{&1.id, &1})

    assert %{
             family: :row_and_artifact,
             kind: :list_item_multi_column,
             row_identity: "task-1",
             column_template: [%{id: :title, label: "Title"}, %{id: :owner, label: "Owner"}],
             active?: true,
             link_target: "/tasks/1",
             action_intent: :open_task
           } = summary.task_row

    assert Enum.map(summary.task_row.children, & &1.kind) == [:text, :badge]

    assert %{
             family: :row_and_artifact,
             kind: :artifact_row,
             title: "Widget component ADR",
             artifact_kind: :doc,
             status_badges: [%{label: "Accepted", tone: :positive}],
             counts: %{comments: 4},
             timestamp_at: "2026-05-18T10:00:00Z",
             action_intent: :open_artifact
           } = summary.adr_artifact

    assert %{
             family: :workflow_progress_and_status,
             kind: :pipeline_stepper_horizontal,
             active_index: 1,
             completed_indices: [0],
             navigation_intent: :select_release_step
           } = summary.release_steps

    assert Enum.map(summary.release_steps.steps, & &1.state) == [:done, :active, :pending]

    assert %{
             family: :layer_shell_and_callout,
             kind: :slide_over_panel,
             open?: true,
             modal?: false,
             dismiss_intent: :close_details
           } = summary.details_panel

    assert %{
             family: :layer_shell_and_callout,
             kind: :composer_query_preview,
             composer_id: "composer-main",
             query: "release blockers",
             preview_state: :ready,
             open_intent: :open_query_preview,
             save_intent: :save_query,
             dismiss_intent: :dismiss_query_preview
           } = summary.query_preview

    assert %{
             family: :redline_and_code,
             kind: :code_block_syntax_highlighted,
             language: :elixir,
             text_safety: :plain_text
           } = summary.code_sample
  end

  test "validates operational component field shapes" do
    assert {:error, [:composition, :list_item_multi_column, :bad_row], row_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :list_item_multi_column,
               id: :bad_row,
               row_identity: "row-1",
               column_template: [%{id: :title}]
             })

    assert row_message =~ "column_template must be a non-empty list"

    assert {:error, [:composition, :artifact_row, :bad_artifact], artifact_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :artifact_row,
               id: :bad_artifact,
               title: "Bad artifact",
               row_identity: :artifact,
               artifact_kind: :conversation
             })

    assert artifact_message =~ "artifact_kind must be one of"

    assert {:error, [:composition, :pipeline_stepper_horizontal, :bad_steps], step_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :pipeline_stepper_horizontal,
               id: :bad_steps,
               steps: [%{id: :draft, label: "Draft", state: :done}],
               active_index: 2,
               completed_indices: []
             })

    assert step_message =~ "active_index must reference an existing step"

    assert {:error, [:composition, :segmented_progress_bar, :bad_progress], progress_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :segmented_progress_bar,
               id: :bad_progress,
               segments: [%{label: "Failing", weight: 0}]
             })

    assert progress_message =~ "positive weight or value"

    assert {:error, [:composition, :meter_thin, :bad_meter], meter_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :meter_thin,
               id: :bad_meter,
               current: 12,
               minimum: 0,
               maximum: 10
             })

    assert meter_message =~ "current, minimum, and maximum must be numeric"

    assert {:error, [:composition, :slide_over_panel, :bad_panel], panel_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :slide_over_panel,
               id: :bad_panel,
               modal?: true
             })

    assert panel_message =~ "must remain non-modal"

    assert {:error, [:composition, :composer_query_preview, :bad_query_preview],
            query_preview_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :composer_query_preview,
               id: :bad_query_preview,
               composer_id: "composer-main",
               query: "status",
               preview_state: :ready
             })

    assert query_preview_message =~ "explanation is required"

    assert {:error, [:composition, :redline_inline, :bad_redline], redline_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :redline_inline,
               id: :bad_redline,
               segments: [%{state: :html, text: "<strong>bad</strong>"}]
             })

    assert redline_message =~ "supported state"

    assert {:error, [:composition, :code_block_syntax_highlighted, :bad_code], code_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :code_block_syntax_highlighted,
               id: :bad_code,
               tokens: [%{type: :keyword}]
             })

    assert code_message =~ "token maps with type and text"
  end

  test "tooling links operational families to widget component specs" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(OperationalComponentsScreen)

    assert :row_and_artifact in report.construct_families
    assert :workflow_progress_and_status in report.construct_families
    assert :layer_shell_and_callout in report.construct_families
    assert :redline_and_code in report.construct_families
    assert ".spec/specs/unified-ui/widget_components.spec.md" in report.related_specs
  end
end
