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
    progress = Tree.find_by_id(iur, :quality_bar)
    panel = Tree.find_by_id(iur, :details_panel)
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
    stepper = Tree.find_by_id(iur, :release_steps)
    panel = Tree.find_by_id(iur, :details_panel)
    callout = Tree.find_by_id(iur, :incident_callout)

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

    assert [%Interaction{family: :navigation, intent: :select_step} = step_navigation] =
             stepper.attributes.interactions

    assert step_navigation.payload == %{mapping: %{step_id: :id, step_index: :index}}

    assert [%Interaction{family: :close, intent: :close_panel} = close_panel] =
             panel.attributes.interactions

    assert close_panel.payload == %{mapping: %{open?: false}}

    assert [%Interaction{family: :click, intent: :inspect_event}] =
             callout.attributes.interactions
  end
end
