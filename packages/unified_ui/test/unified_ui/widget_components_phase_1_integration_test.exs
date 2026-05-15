defmodule UnifiedUi.WidgetComponentsPhase1IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents
  alias UnifiedUi.WidgetComponents

  defmodule ExpandedWidgetSurface do
    use UnifiedUi.Dsl

    identity do
      id(:expanded_widget_surface)
      authored_ref([:examples, :expanded_widget_surface])
    end

    signals do
      data_binding do
        id(:artifact_rows)
        path([:artifacts])
        collection?(true)
      end
    end

    composition do
      root(:expanded_widget_root)
      mode(:screen)

      inline_rich_text_heading :headline do
        level(:h2)
        segments([%{type: :text, value: "Widget surface"}])
      end

      avatar :owner_avatar do
        initials("PC")
        accessibility_label("Pascal Charbonneau")
      end

      runtime_form_shell :settings_form do
        fields([%{name: :title, type: :text, label: "Title"}])
        submit_intent(:save_settings)
        change_intent(:validate_settings)
      end

      chat_composer :composer do
        send_intent(:send_message)
      end

      artifact_row :artifact_row do
        title("Spec artifact")
        row_identity(:spec_artifact)
        action_intent(:open_artifact)
      end

      sidebar_item :artifact_sidebar_item do
        label("build/spec-artifact")
        glyph("◇")
        meta("spec")
        state(:active)
        item_kind(:build)
        item_id("spec-artifact")
        action_intent(:open_artifact)
        unread_count(3)
      end

      pipeline_stepper_horizontal :workflow_steps do
        steps([
          %{id: :authored, label: "Authored", state: :done},
          %{id: :implemented, label: "Implemented", state: :active}
        ])

        active_index(1)
      end

      slide_over_panel :details_panel do
        accessibility_label("Details")
        open?(true)
      end

      redline_inline :redline do
        segments([%{state: :insert, text: "new text"}])
      end

      code_block_syntax_highlighted :code do
        language(:elixir)
        tokens([%{type: :keyword, text: "defmodule"}])
      end

      list_repeat :artifact_repeat do
        repeat_binding(:artifact_rows)
        row_fields([:id, :title])
        template_identity(:artifact_template)

        artifact_row_template :artifact_template do
          title("Repeated artifact")
          row_identity(:id)
        end
      end
    end
  end

  test "expanded widget families validate and inspect through the authored DSL" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(ExpandedWidgetSurface)

    assert report.construct_families == [
             :composition_behavior,
             :content_identity_and_disclosure,
             :form_control_and_composer,
             :layer_shell_and_callout,
             :redline_and_code,
             :row_and_artifact,
             :workflow_progress_and_status
           ]

    kinds =
      ExpandedWidgetSurface
      |> UnifiedUi.Info.composition_summary()
      |> Enum.flat_map(&summary_kinds/1)

    for kind <- [
          :inline_rich_text_heading,
          :avatar,
          :runtime_form_shell,
          :chat_composer,
          :artifact_row,
          :sidebar_item,
          :pipeline_stepper_horizontal,
          :slide_over_panel,
          :redline_inline,
          :code_block_syntax_highlighted,
          :list_repeat
        ] do
      assert kind in kinds
    end
  end

  test "malformed representative widget fields report canonical diagnostics" do
    assert {:error, [:composition, :inline_rich_text_heading, :bad_heading], heading_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :inline_rich_text_heading,
               id: :bad_heading,
               segments: [%{type: :html, value: "<strong>bad</strong>"}]
             })

    assert heading_message =~ "inline_rich_text_heading"

    assert {:error, [:composition, :segmented_button_group, :bad_segmented], segmented_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :segmented_button_group,
               id: :bad_segmented,
               options: []
             })

    assert segmented_message =~ "segmented_button_group"

    assert {:error, [:composition, :redline_inline, :bad_redline], redline_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :redline_inline,
               id: :bad_redline,
               segments: [%{state: :markup, text: "<b>bad</b>"}]
             })

    assert redline_message =~ "redline_inline"
  end

  test "host-specific aliases remain catalog diagnostics rather than authored canonical names" do
    assert WidgetComponents.name_diagnostic(:phoenix_form) == %{
             status: :alias,
             name: :phoenix_form,
             canonical: :runtime_form_shell,
             family: :form_control_and_composer,
             message:
               ":phoenix_form is an AshUi compatibility alias; use :runtime_form_shell for canonical UnifiedUi authoring."
           }
  end

  test "repeat rejects non-list bindings during authored validation" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_repeat_screen)
        authored_ref([:examples, :invalid_repeat_screen])
      end

      signals do
        data_binding do
          id(:profile)
          path([:profile])
          collection?(false)
        end
      end

      composition do
        root(:invalid_repeat_root)

        list_repeat :profile_repeat do
          repeat_binding(:profile)
          row_fields([:id])

          artifact_row_template :template do
            title("Template")
            row_identity(:id)
          end
        end
      end
      """,
      "repeat_binding :profile must reference a collection data_binding"
    )
  end

  defp summary_kinds(%{kind: kind, children: children}) do
    [kind | Enum.flat_map(children, &summary_kinds/1)]
  end

  defp summary_kinds(%{kind: kind}), do: [kind]

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.WidgetComponentsPhase1IntegrationTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
