defmodule UnifiedUi.Phase2IntegrationTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule BaselineWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:phase_2_workspace)
      title("Phase 2 Workspace")
      description("Foundational authored screen for the Phase 2 integration suite")
      authored_ref([:integration, :phase_2_workspace])
      tags([:integration, :phase_2])
    end

    composition do
      root(:phase_2_workspace_root)
      mode(:screen)
      summary("Phase 2 baseline authored workspace")

      content :hero_copy do
        summary("Hero copy")

        text :headline do
          value("UnifiedUi foundational workspace")
        end

        label :supporting_label do
          value("Canonical authored baseline")
          target(:workspace_name)
        end

        icon :workspace_icon do
          name(:sparkles)
          set(:system)
        end
      end

      box :hero_shell do
        summary("Hero shell")

        image :hero_image do
          source("/static/hero.png")
          alt_text("Workspace hero image")
        end

        button :primary_action do
          label("Create workspace")
          action_intent(:create_workspace)
        end

        separator :hero_separator do
          orientation(:horizontal)
        end

        spacer :hero_gap do
          size(:lg)
        end
      end

      row :navigation_row do
        gap(:md)
        justify(:space_between)

        menu :main_menu do
          items(home: "Home", workspaces: "Workspaces")
          active_item(:home)
        end

        tabs :workspace_tabs do
          items(overview: "Overview", activity: "Activity")
          active_item(:overview)
        end

        command_palette :workspace_commands do
          items(create: "Create", archive: "Archive")
          label("Workspace commands")
        end

        link :docs_link do
          label("Open docs")
          target("https://specled.dev/home")
          external?(true)
        end
      end

      column :settings_column do
        gap(:sm)

        text_input :workspace_name do
          placeholder("Workspace name")
          value_path([:workspace, :name])
        end

        toggle :workspace_private do
          label("Private workspace")
          value_path([:workspace, :private])
          default_value(false)
        end

        select :workspace_region do
          label("Region")
          value_path([:workspace, :region])
          options(us: "US", eu: "EU")
          default_value(:us)
        end
      end

      grid :summary_grid do
        columns(2)
        gap(:sm)

        text :summary_title do
          value("Summary")
        end

        label :summary_status do
          value("Ready")
          target(:workspace_status)
        end
      end

      stack :spotlight_stack do
        align(:center)

        text :spotlight_copy do
          value("Phase 2 spotlight")
        end
      end

      form_builder :workspace_form do
        summary("Workspace setup form")
        submit_intent(:submit_workspace)

        field_group :workspace_identity do
          legend("Workspace")

          field :workspace_name_field do
            field_name(:name)
            label("Workspace name")
            value_path([:workspace, :name])

            text_input :workspace_name_input do
              placeholder("Acme workspace")
            end
          end

          field :workspace_role_field do
            field_name(:role)
            label("Role")
            default_value(:owner)

            select :workspace_role_input do
              options(owner: "Owner", editor: "Editor")
            end
          end
        end

        tabs :form_tabs do
          items(details: "Details", members: "Members")
          active_item(:details)
        end

        command_palette :form_actions do
          items(save: "Save", cancel: "Cancel")
          label("Form actions")
        end
      end
    end
  end

  defmodule EquivalentWorkspaceOne do
    use UnifiedUi.Dsl

    identity do
      id(:equivalent_workspace_one)
      authored_ref([:integration, :equivalent_workspace_one])
    end

    composition do
      root(:equivalent_workspace_one_root)
      mode(:screen)

      box :equivalent_shell do
        text :equivalent_title do
          value("Equivalent")
        end

        button :equivalent_action do
          label("Continue")
        end
      end

      form_builder :equivalent_form do
        field_group :equivalent_group do
          field :equivalent_name do
            field_name(:name)
            label("Name")

            text_input :equivalent_name_input do
              placeholder("Name")
            end
          end
        end

        command_palette :equivalent_commands do
          items(save: "Save")
        end
      end
    end
  end

  defmodule EquivalentWorkspaceTwo do
    use UnifiedUi.Dsl

    identity do
      id(:equivalent_workspace_two)
      authored_ref([:integration, :equivalent_workspace_two])
    end

    composition do
      root(:equivalent_workspace_two_root)
      mode(:screen)

      box :equivalent_shell do
        text :equivalent_title do
          value("Equivalent")
        end

        button :equivalent_action do
          label("Continue")
        end
      end

      form_builder :equivalent_form do
        field_group :equivalent_group do
          field :equivalent_name do
            field_name(:name)
            label("Name")

            text_input :equivalent_name_input do
              placeholder("Name")
            end
          end
        end

        command_palette :equivalent_commands do
          items(save: "Save")
        end
      end
    end
  end

  test "phase 2 foundational widgets, layouts, forms, and navigation compose through the package reference surfaces" do
    assert UnifiedUi.Widgets.kinds() == [
             :text,
             :label,
             :icon,
             :image,
             :badge,
             :hero,
             :content,
             :button,
             :link,
             :separator,
             :spacer,
             :text_input,
             :numeric_input,
             :toggle,
             :checkbox,
             :radio_group,
             :select,
             :pick_list,
             :date_input,
             :time_input,
             :file_input,
             :menu,
             :tabs,
             :command_palette,
             :list,
             :table,
             :tree_view,
             :stat,
             :key_value,
             :info_list,
             :markdown_viewer,
             :log_viewer,
             :status,
             :progress,
             :gauge,
             :inline_feedback,
             :sparkline,
             :bar_chart,
             :line_chart,
             :stream_widget,
             :process_monitor,
             :supervision_tree_viewer,
             :cluster_dashboard,
             :inline_rich_text_heading,
             :disclosure,
             :kicker,
             :avatar,
             :presence_dot,
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer,
             :collection_picker,
             :list_item_multi_column,
             :artifact_row,
             :thread_card,
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin,
             :workflow_progress_status_card,
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout,
             :composer_query_preview,
             :right_rail,
             :redline_inline,
             :code_block_syntax_highlighted,
             :list_repeat
           ]

    assert UnifiedUi.Layout.kinds() == [:box, :row, :column, :grid, :stack]
    assert UnifiedUi.Forms.kinds() == [:form_builder, :field_group, :field, :form_field]
    assert UnifiedUi.Navigation.kinds() == [:menu, :tabs, :command_palette]

    summary = UnifiedUi.Info.composition_summary(BaselineWorkspace)

    assert Enum.map(summary, &{&1.id, &1.family, &1.kind}) == [
             {:hero_copy, :foundational, :content},
             {:hero_shell, :layout, :box},
             {:navigation_row, :layout, :row},
             {:settings_column, :layout, :column},
             {:summary_grid, :layout, :grid},
             {:spotlight_stack, :layout, :stack},
             {:workspace_form, :forms, :form_builder}
           ]

    assert Enum.map(hd(summary).children, &{&1.id, &1.kind}) == [
             {:headline, :text},
             {:supporting_label, :label},
             {:workspace_icon, :icon}
           ]

    assert Enum.map(Enum.at(summary, 1).children, &{&1.id, &1.kind}) == [
             {:hero_image, :image},
             {:primary_action, :button},
             {:hero_separator, :separator},
             {:hero_gap, :spacer}
           ]

    assert Enum.map(Enum.at(summary, 2).children, &{&1.id, &1.kind}) == [
             {:main_menu, :menu},
             {:workspace_tabs, :tabs},
             {:workspace_commands, :command_palette},
             {:docs_link, :link}
           ]

    assert Enum.map(Enum.at(summary, 3).children, &{&1.id, &1.kind}) == [
             {:workspace_name, :text_input},
             {:workspace_private, :toggle},
             {:workspace_region, :select}
           ]
  end

  test "phase 2 reference examples remain valid and introspectable without runtime libraries" do
    assert UnifiedUi.Examples.modules() == [
             UnifiedUi.Examples.FoundationalScreen,
             UnifiedUi.Examples.ProfileForm,
             UnifiedUi.Examples.OverlayWorkspace,
             UnifiedUi.Examples.OperationsDashboard,
             UnifiedUi.Examples.ThemedSignalWorkspace
           ]

    assert Enum.map(UnifiedUi.Reference.example_catalog(), & &1.id) == [
             :foundational_screen,
             :profile_form,
             :overlay_workspace,
             :operations_dashboard,
             :themed_signal_workspace
           ]

    assert Enum.map(UnifiedUi.Info.example_summaries(), & &1.id) == [
             :foundational_screen,
             :profile_form,
             :overlay_workspace,
             :operations_dashboard,
             :themed_signal_workspace
           ]

    assert Enum.all?(UnifiedUi.Examples.modules(), fn module ->
             UnifiedUi.Info.inspect_module(module).validation_state == :phase_1_valid
           end)
  end

  test "phase 2 form workflows preserve field labels, value paths, and action relationships" do
    [_, _, _, _, _, _, form] = Extension.get_entities(BaselineWorkspace, [:composition])
    [group, tabs, palette] = form.children
    [name_field, role_field] = group.children

    assert form.summary == "Workspace setup form"
    assert form.submit_intent == :submit_workspace
    assert group.legend == "Workspace"

    assert %{
             field_name: :name,
             label: "Workspace name",
             value_path: [:workspace, :name]
           } = Map.take(name_field, [:field_name, :label, :value_path])

    assert %{
             kind: :text_input,
             placeholder: "Acme workspace"
           } = Map.take(List.first(name_field.children), [:kind, :placeholder])

    assert %{
             field_name: :role,
             label: "Role",
             default_value: :owner
           } = Map.take(role_field, [:field_name, :label, :default_value])

    assert %{
             kind: :select,
             options: [owner: "Owner", editor: "Editor"]
           } = Map.take(List.first(role_field.children), [:kind, :options])

    assert {tabs.kind, tabs.active_item} == {:tabs, :details}
    assert {palette.kind, palette.label} == {:command_palette, "Form actions"}
  end

  test "phase 2 invalid placement and incomplete authored declarations fail at compile time" do
    assert_compile_dsl_error(
      """
      identity do
        id(:broken_field)
      end

      composition do
        root(:broken_field_root)

        form_builder :broken_form do
          field :empty_field do
            field_name(:empty)
          end
        end
      end
      """,
      "must contain exactly one input child"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:broken_menu)
      end

      composition do
        root(:broken_menu_root)

        row :broken_row do
          menu :missing_items do
          end
        end
      end
      """,
      ":items"
    )
  end

  test "phase 2 equivalent authored baseline inputs yield stable summaries ahead of compilation" do
    assert UnifiedUi.Info.composition_summary(EquivalentWorkspaceOne) ==
             UnifiedUi.Info.composition_summary(EquivalentWorkspaceTwo)

    assert UnifiedUi.Info.module_summary(EquivalentWorkspaceOne).sections == %{
             composition: true,
             identity: true,
             signals: false,
             themes: false
           }

    assert UnifiedUi.Info.module_summary(EquivalentWorkspaceOne).composition == %{
             mode: :screen,
             root: :equivalent_workspace_one_root
           }

    assert UnifiedUi.Info.composition_summary(EquivalentWorkspaceOne) == [
             %{
               id: :equivalent_shell,
               family: :layout,
               kind: :box,
               children: [
                 %{
                   id: :equivalent_title,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Equivalent"
                 },
                 %{
                   id: :equivalent_action,
                   family: :foundational,
                   kind: :button,
                   label: "Continue"
                 }
               ]
             },
             %{
               id: :equivalent_form,
               family: :forms,
               kind: :form_builder,
               children: [
                 %{
                   id: :equivalent_group,
                   family: :forms,
                   kind: :field_group,
                   children: [
                     %{
                       id: :equivalent_name,
                       family: :forms,
                       kind: :field,
                       label: "Name",
                       children: [
                         %{
                           id: :equivalent_name_input,
                           family: :input,
                           kind: :text_input
                         }
                       ]
                     }
                   ]
                 },
                 %{
                   id: :equivalent_commands,
                   family: :navigation,
                   items: [save: "Save"],
                   kind: :command_palette
                 }
               ]
             }
           ]
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.Phase2IntegrationTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    try do
      {_result, diagnostics} = Code.with_diagnostics(fn -> compile_module(body) end)
      diagnostics_text = Enum.map_join(diagnostics, "\n", &diagnostic_message/1)

      if diagnostics_text == "" do
        flunk("expected authored module compilation to fail, but it succeeded")
      else
        assert diagnostics_text =~ expected_message
      end
    rescue
      exception ->
        assert Exception.message(exception) =~ expected_message
    catch
      :exit, reason ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end

  defp diagnostic_message(%{message: message}) when is_binary(message), do: message
  defp diagnostic_message(diagnostic), do: inspect(diagnostic)
end
