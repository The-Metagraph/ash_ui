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
    end
  end

  test "registers authored form control and composer component kinds" do
    assert UnifiedUi.Widgets.form_control_component_kinds() == [
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer
           ]

    assert :segmented_button_group in UnifiedUi.Widgets.kinds()
    assert :runtime_form_shell in UnifiedUi.Widgets.kinds()
    assert :chat_composer in UnifiedUi.Widgets.kinds()
  end

  test "stores form control and composer components in the composition tree" do
    [segmented, form, composer] = Extension.get_entities(FormControlScreen, [:composition])

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
  end

  test "tooling links the form control family to widget and signal specs" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(FormControlScreen)

    assert :form_control_and_composer in report.construct_families
    assert ".spec/specs/unified-ui/widget_components.spec.md" in report.related_specs
    assert ".spec/specs/unified-ui/signals.spec.md" in report.related_specs
  end
end
