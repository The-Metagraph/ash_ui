defmodule UnifiedUi.WidgetComponentsCompilerLoweringTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Interaction, Tree}
  alias UnifiedUi.Compiler

  defmodule ComponentCompilerScreen do
    use UnifiedUi.Dsl

    identity do
      id(:component_compiler_screen)
      authored_ref([:tests, :component_compiler_screen])
    end

    composition do
      root(:component_compiler_root)
      mode(:screen)

      inline_rich_text_heading :headline do
        level(:h2)
        segments([%{type: :text, value: "Canonical widgets"}])
      end

      disclosure :details do
        summary("Details")
        open?(true)

        text :details_body do
          value("Portable disclosure body")
        end
      end

      segmented_button_group :status_filter do
        options([%{value: :all, label: "All"}, %{value: :active, label: "Active"}])
        active_value(:all)
        selection_intent(:select_status)
      end

      runtime_form_shell :settings_form do
        fields([%{name: :title, type: :text, label: "Title"}])
        submit_label("Save")
        submit_intent(:save_settings)
        change_intent(:validate_settings)
        validation_state(:invalid)
        annotations(live_ui: [adapter: :phoenix_form])
      end

      chat_composer :composer do
        name(:message)
        value("Draft")
        send_intent(:send_message)
        change_intent(:update_message)

        button :attach_tool do
          label("Attach")
        end
      end

      list_item_multi_column :task_row do
        row_identity("task-1")
        column_template([%{id: :title, label: "Title"}])
        active?(true)
        action_intent(:open_task)

        text :task_title do
          value("Review ADR")
        end
      end

      artifact_row :artifact do
        title("Widget ADR")
        row_identity(:adr)
        meta(%{status: :accepted})
        artifact_kind(:spec)
        status_badges([%{label: "Accepted", tone: :positive}])
        counts([%{key: :comments, value: 3, label: "Comments"}])
        timestamp_at(~U[2026-05-18 10:00:00Z])
        action_intent(:open_artifact)
      end

      pipeline_stepper_horizontal :release_steps do
        steps([%{id: :draft, label: "Draft", state: :done}])
        navigation_intent(:select_step)
      end

      segmented_progress_bar :quality_bar do
        segments([%{label: "Passing", weight: 8, state: :success}])
        aggregate_progress(%{current: 8, maximum: 9})
        label("Scenario health")
      end

      workflow_stage_list_vertical :review_stages do
        stages([%{id: :authored, label: "Authored", state: :done}])
      end

      meter_thin :coverage_meter do
        current(82.5)
        label("Coverage")
        state(:success)
      end

      sticky_frosted_header :workspace_header do
        title("Workspace")
        leading([:back_button])
      end

      slide_over_panel :details_panel do
        accessibility_label("Details")
        open?(true)
        size(:wide)
        dismiss_intent(:close_panel)
      end

      event_callout :incident_callout do
        tone(:warning)
        message("Paused")
        action_intent(:inspect_event)
      end

      composer_query_preview :query_preview do
        composer_id("composer-main")
        query("release blockers")
        preview_state(:ready)
        explanation("Two release checks need attention.")
        metrics(%{results_count: 2, duration_ms: 34, sources_visited: 4})
        findings([%{id: "finding-1", n: 1, snippet: "CI is still pending.", confidence: 0.82}])
        open_intent(:open_query_preview)
        save_intent(:save_query)
        dismiss_intent(:dismiss_query_preview)
      end

      right_rail :workspace_rail do
        side(:right)

        panels([
          %{id: :agents, label: "Agents", badge: %{label: "2"}, content_slot: :agents_body},
          %{id: :sources, label: "Sources", content_slot: :sources_body}
        ])

        active_panel(:sources)
        collapsed?(false)
        collapsible?(true)
        panel_select_intent(:select_rail_panel)
        collapse_intent(:toggle_rail)
        density(:compact)
        width(:wide)

        text :sources_body do
          value("Rail body")
        end
      end

      redline_inline :copy_redline do
        segments([%{state: :insert, text: "new"}])
      end

      code_block_syntax_highlighted :code_sample do
        language(:elixir)
        tokens([%{type: :keyword, text: "defmodule"}])
      end
    end
  end

  test "lowers expanded widget components into canonical UnifiedIUR component nodes" do
    iur = Compiler.iur!(ComponentCompilerScreen)

    heading = Tree.find_by_id(iur, :headline)
    disclosure = Tree.find_by_id(iur, :details)
    form = Tree.find_by_id(iur, :settings_form)
    composer = Tree.find_by_id(iur, :composer)
    row = Tree.find_by_id(iur, :task_row)
    artifact = Tree.find_by_id(iur, :artifact)
    progress = Tree.find_by_id(iur, :quality_bar)
    panel = Tree.find_by_id(iur, :details_panel)
    query_preview = Tree.find_by_id(iur, :query_preview)
    rail = Tree.find_by_id(iur, :workspace_rail)
    code = Tree.find_by_id(iur, :code_sample)

    assert heading.kind == :inline_rich_text_heading

    assert heading.attributes.component == %{
             family: :content_identity_and_disclosure,
             kind: :inline_rich_text_heading
           }

    refute Map.has_key?(heading.attributes, :authored)

    assert heading.attributes.heading == %{
             level: :h2,
             segments: [%{type: :text, value: "Canonical widgets"}]
           }

    assert disclosure.attributes.disclosure == %{summary: "Details", open?: true}
    assert [%{element: %{kind: :text}}] = disclosure.children

    assert form.attributes.form.host_adapter_hints == %{live_ui: %{adapter: :phoenix_form}}

    assert composer.attributes.composer == %{
             name: :message,
             value: "Draft",
             rows: 3,
             send_label: "Send",
             send_intent: :send_message,
             change_intent: :update_message
           }

    assert [%{element: %{kind: :button}}] = composer.children

    assert row.attributes.row == %{
             row_identity: "task-1",
             active?: true,
             action_intent: :open_task,
             column_template: [%{id: :title, label: "Title"}]
           }

    assert artifact.attributes.artifact == %{
             row_identity: :adr,
             active?: false,
             action_intent: :open_artifact,
             title: "Widget ADR",
             meta: %{status: :accepted},
             kind: :spec,
             status_badges: [%{label: "Accepted", tone: :positive}],
             counts: [%{key: :comments, value: 3, label: "Comments"}],
             timestamp_at: ~U[2026-05-18 10:00:00Z]
           }

    assert progress.attributes.progress == %{
             presentation: :segmented_progress_bar,
             segments: [%{label: "Passing", weight: 8, state: :success}],
             aggregate: %{current: 8, maximum: 9},
             label: "Scenario health"
           }

    assert panel.attributes.panel == %{
             modal?: false,
             open?: true,
             size: :wide,
             label: "Details",
             dismiss_intent: :close_panel
           }

    assert query_preview.attributes.component == %{
             family: :layer_shell_and_callout,
             kind: :composer_query_preview
           }

    assert query_preview.attributes.query_preview == %{
             composer_id: "composer-main",
             query: "release blockers",
             preview_state: :ready,
             explanation: "Two release checks need attention.",
             metrics: %{results_count: 2, duration_ms: 34, sources_visited: 4},
             findings: [
               %{id: "finding-1", n: 1, snippet: "CI is still pending.", confidence: 0.82}
             ],
             max_findings_shown: 2,
             loading_label: "Searching",
             empty_label: "No results for this query.",
             open_label: "Open query",
             save_label: "Save query"
           }

    assert rail.attributes.component == %{
             family: :layer_shell_and_callout,
             kind: :right_rail
           }

    assert rail.attributes.rail == %{
             id: :workspace_rail,
             side: :right,
             panels: [
               %{id: :agents, label: "Agents", badge: %{label: "2"}, content_slot: :agents_body},
               %{id: :sources, label: "Sources", content_slot: :sources_body}
             ],
             active_panel: :sources,
             collapsed?: false,
             collapsible?: true,
             density: :compact,
             width: :wide
           }

    assert [%{slot: :sources_body, element: %{kind: :text, id: :sources_body}}] = rail.children

    assert code.attributes.code == %{
             language: :elixir,
             tokens: [%{type: :keyword, text: "defmodule"}]
           }
  end

  test "lowers component intents into renderer-independent interaction descriptors" do
    iur = Compiler.iur!(ComponentCompilerScreen)

    segmented = Tree.find_by_id(iur, :status_filter)
    form = Tree.find_by_id(iur, :settings_form)
    composer = Tree.find_by_id(iur, :composer)
    row = Tree.find_by_id(iur, :task_row)
    artifact = Tree.find_by_id(iur, :artifact)
    stepper = Tree.find_by_id(iur, :release_steps)
    panel = Tree.find_by_id(iur, :details_panel)
    callout = Tree.find_by_id(iur, :incident_callout)
    query_preview = Tree.find_by_id(iur, :query_preview)
    rail = Tree.find_by_id(iur, :workspace_rail)

    assert [%Interaction{family: :selection, intent: :select_status} = selection] =
             segmented.attributes.interactions

    assert selection.source == %{element_id: :status_filter}
    assert selection.payload == %{selection: :all, mapping: %{selected_value: :value}}

    assert Enum.map(form.attributes.interactions, &{&1.family, &1.intent}) == [
             {:submit, :save_settings},
             {:change, :validate_settings}
           ]

    assert Enum.map(composer.attributes.interactions, &{&1.family, &1.intent}) == [
             {:change, :update_message},
             {:submit, :send_message}
           ]

    assert [%Interaction{family: :click, intent: :open_task} = row_action] =
             row.attributes.interactions

    assert row_action.payload == %{value: "task-1", mapping: %{row_identity: :row_identity}}

    assert [%Interaction{family: :click, intent: :open_artifact} = artifact_action] =
             artifact.attributes.interactions

    assert artifact_action.payload == %{value: :adr, mapping: %{row_identity: :row_identity}}

    assert [%Interaction{family: :navigation, intent: :select_step} = step_navigation] =
             stepper.attributes.interactions

    assert step_navigation.payload == %{mapping: %{step_id: :id, step_index: :index}}

    assert [%Interaction{family: :close, intent: :close_panel} = close_panel] =
             panel.attributes.interactions

    assert close_panel.payload == %{mapping: %{open?: false}}

    assert [%Interaction{family: :click, intent: :inspect_event}] =
             callout.attributes.interactions

    assert Enum.map(query_preview.attributes.interactions, &{&1.family, &1.intent}) == [
             {:close, :dismiss_query_preview},
             {:open, :open_query_preview},
             {:command, :save_query}
           ]

    assert [
             %Interaction{family: :selection, intent: :select_rail_panel} = panel_select,
             %Interaction{family: :change, intent: :toggle_rail} = collapse_change
           ] = rail.attributes.interactions

    assert panel_select.source == %{element_id: :workspace_rail}
    assert panel_select.payload == %{selection: :sources, mapping: %{panel_id: :id}}
    assert collapse_change.payload == %{value: false, mapping: %{collapsed?: :collapsed?}}
  end
end
