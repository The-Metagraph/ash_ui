defmodule UnifiedUi.FormControlComponentsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule FormControlScreen do
    use UnifiedUi.Dsl

    identity do
      id(:form_control_screen)
      authored_ref([:examples, :form_control_screen])
    end

    composition do
      root(:form_control_root)
      mode(:screen)

      segmented_button_group :status_filter do
        options([
          %{value: :all, label: "All"},
          %{value: :active, label: "Active"},
          %{value: :archived, label: "Archived", disabled?: true}
        ])

        active_value(:all)
        selection_intent(:select_status)
        disabled?(true)
      end

      runtime_form_shell :sign_in_form do
        fields([
          %{
            name: :email,
            type: :email,
            label: "Work email",
            attributes: [required: true, autocomplete: "email"]
          },
          %{name: :password, type: :password, label: "Password"}
        ])

        submit_label("Sign in")
        submit_intent(:submit_sign_in)
        change_intent(:validate_sign_in)
        validation_state(:invalid)
        annotations(live_ui: [adapter: :phoenix_form, integration: :ash_phoenix])
      end

      chat_composer :message_composer do
        name(:message)
        value("Draft message")
        placeholder("Write a message")
        rows(4)
        send_label("Send")
        send_intent(:send_message)
        change_intent(:update_message)
        disabled?(true)

        button :attach_tool do
          label("Attach")
        end
      end

      collection_picker :source_picker do
        picker_id("sources")
        title("Sources")
        query("adr")
        filters([%{id: "all", label: "All", selected?: true}])
        items([%{id: "adr-1", label: "ADR 1", description: "Architecture decision"}])
        suggestions([%{id: "suggestion-1", label: "Add ADR 2", confidence: 0.8}])
        change_intent(:change_source_query)
        selection_intent(:select_source)
        filter_toggle_intent(:toggle_source_filter)
      end
    end
  end

  test "registers authored form control and composer component kinds" do
    assert UnifiedUi.Widgets.form_control_component_kinds() == [
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer,
             :collection_picker
           ]

    assert :segmented_button_group in UnifiedUi.Widgets.kinds()
    assert :runtime_form_shell in UnifiedUi.Widgets.kinds()
    assert :chat_composer in UnifiedUi.Widgets.kinds()
    assert :collection_picker in UnifiedUi.Widgets.kinds()
  end

  test "stores form control and composer components in the composition tree" do
    [segmented, form, composer, picker] =
      Extension.get_entities(FormControlScreen, [:composition])

    assert {segmented.family, segmented.kind, segmented.active_value, segmented.selection_intent,
            segmented.disabled?} ==
             {:form_control_and_composer, :segmented_button_group, :all, :select_status, true}

    assert Enum.map(segmented.options, & &1.value) == [:all, :active, :archived]

    assert {form.family, form.kind, form.submit_label, form.submit_intent, form.change_intent,
            form.validation_state} ==
             {:form_control_and_composer, :runtime_form_shell, "Sign in", :submit_sign_in,
              :validate_sign_in, :invalid}

    assert form.annotations == [live_ui: [adapter: :phoenix_form, integration: :ash_phoenix]]

    assert Enum.map(form.fields, & &1.name) == [:email, :password]

    assert {composer.family, composer.kind, composer.name, composer.rows, composer.send_intent,
            composer.disabled?} ==
             {:form_control_and_composer, :chat_composer, :message, 4, :send_message, true}

    assert Enum.map(composer.children, & &1.kind) == [:button]

    assert {picker.family, picker.kind, picker.picker_id, picker.query, picker.change_intent,
            picker.selection_intent, picker.filter_toggle_intent} ==
             {:form_control_and_composer, :collection_picker, "sources", "adr",
              :change_source_query, :select_source, :toggle_source_filter}

    assert Enum.map(picker.items, & &1.label) == ["ADR 1"]
  end

  test "summarizes form control and composer components without a renderer runtime" do
    assert UnifiedUi.Info.composition_summary(FormControlScreen) == [
             %{
               id: :status_filter,
               family: :form_control_and_composer,
               kind: :segmented_button_group,
               active_value: :all,
               selection_intent: :select_status
             },
             %{
               id: :sign_in_form,
               family: :form_control_and_composer,
               kind: :runtime_form_shell,
               annotations: [live_ui: [adapter: :phoenix_form, integration: :ash_phoenix]],
               fields: [
                 %{
                   name: :email,
                   type: :email,
                   label: "Work email",
                   attributes: [required: true, autocomplete: "email"]
                 },
                 %{name: :password, type: :password, label: "Password"}
               ],
               submit_label: "Sign in",
               submit_intent: :submit_sign_in,
               change_intent: :validate_sign_in,
               validation_state: :invalid
             },
             %{
               id: :message_composer,
               family: :form_control_and_composer,
               kind: :chat_composer,
               value: "Draft message",
               change_intent: :update_message,
               send_label: "Send",
               send_intent: :send_message,
               children: [
                 %{id: :attach_tool, family: :foundational, kind: :button, label: "Attach"}
               ]
             },
             %{
               id: :source_picker,
               family: :form_control_and_composer,
               kind: :collection_picker,
               title: "Sources",
               picker_id: "sources",
               query: "adr",
               filters: [%{id: "all", label: "All", selected?: true}],
               items: [%{id: "adr-1", label: "ADR 1", description: "Architecture decision"}],
               suggestions: [%{id: "suggestion-1", label: "Add ADR 2", confidence: 0.8}],
               empty_label: "No matching items.",
               loading?: false,
               change_intent: :change_source_query,
               selection_intent: :select_source,
               filter_toggle_intent: :toggle_source_filter
             }
           ]
  end

  test "validates form control and composer field shapes" do
    assert {:error, [:composition, :segmented_button_group, :filters], segmented_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :segmented_button_group,
               id: :filters,
               options: [%{value: :all}]
             })

    assert segmented_message =~ "options must be a non-empty list"

    assert {:error, [:composition, :runtime_form_shell, :form], form_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :runtime_form_shell,
               id: :form,
               fields: [%{name: :email}]
             })

    assert form_message =~ "fields must be a non-empty list"

    assert {:error, [:composition, :chat_composer, :composer], composer_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :chat_composer,
               id: :composer,
               rows: 0,
               send_intent: :send
             })

    assert composer_message == "chat_composer :composer rows must be a positive integer"

    assert {:error, [:composition, :collection_picker, :picker], picker_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :collection_picker,
               id: :picker,
               picker_id: "",
               items: []
             })

    assert picker_message =~ "picker_id must be a non-empty string"
  end

  test "tooling links the form control family to widget and signal specs" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(FormControlScreen)

    assert :form_control_and_composer in report.construct_families
    assert ".spec/specs/unified-ui/widget_components.spec.md" in report.related_specs
    assert ".spec/specs/unified-ui/signals.spec.md" in report.related_specs
  end
end
