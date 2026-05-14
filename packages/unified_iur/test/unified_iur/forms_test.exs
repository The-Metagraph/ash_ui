defmodule UnifiedIUR.FormsTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Element
  alias UnifiedIUR.Forms
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Widgets.Foundational
  alias UnifiedIUR.Widgets.Input

  test "exposes canonical form composition kinds" do
    assert [:form_builder, :field_group, :field, :form_field] == Forms.kinds()
  end

  test "builds form builders with binding, validation, and submission attachment points" do
    name_input = Input.text_input(id: "name-input", name: :name, required?: true)
    age_input = Input.numeric_input(id: "age-input", name: :age, min: 0)

    name_field = Forms.field(name_input, id: "name-field", label: "Name", required?: true)
    age_field = Forms.field(age_input, id: "age-field", label: "Age")

    group =
      Forms.field_group(
        [
          {:fields, name_field},
          {:fields, age_field}
        ],
        id: "profile-group",
        legend: "Profile",
        group_description: "Primary profile inputs"
      )

    form =
      Forms.form_builder(
        [
          {:content, group},
          {:actions, Foundational.button("Save", id: "save-button")}
        ],
        id: "profile-form",
        name: :profile,
        path: [:profile],
        validation: %{status: :valid},
        submit_intent: :save_profile,
        allow_partial?: false,
        style_refs: [:form_surface]
      )

    assert %Element{
             id: "profile-form",
             kind: :form_builder,
             children: [content, actions],
             attributes: %{
               form: %{mode: :grouped, autocomplete?: true},
               bindings: [%Binding{name: :profile, path: [:profile]}],
               validation: %{status: :valid},
               interactions: [
                 %Interaction{
                   family: :submit,
                   intent: :save_profile,
                   target: %{binding: [:profile]},
                   metadata: %{phase: :submit, allow_partial?: false}
                 }
               ],
               theme: %{
                 component: :form_builder,
                 token_refs: [%{kind: :token_ref, path: [:form_surface]}]
               }
             }
           } = form

    assert content.slot == :content
    assert actions.slot == :actions

    assert %Element{
             kind: :field_group,
             attributes: %{
               group: %{
                 legend: "Profile",
                 description: "Primary profile inputs",
                 role: :group,
                 collapsible?: false
               }
             }
           } = content.element
  end

  test "builds fields with canonical label and help relationships around controls" do
    control =
      Input.text_input(
        id: "email-input",
        name: :email,
        placeholder: "name@example.com",
        accessibility_label: "Email address"
      )

    field =
      Forms.field(control,
        id: "email-field",
        label: "Email",
        help: "We will never share your email.",
        required?: true,
        errors: ["must be present"],
        constraints: %{format: :email}
      )

    assert %Element{
             id: "email-field",
             kind: :field,
             children: [label_child, control_child, help_child],
             attributes: %{
               field: %{
                 control_id: "email-input",
                 label_slot: :label,
                 help_slot: :help
               },
               validation: %{
                 required?: true,
                 errors: ["must be present"],
                 constraints: %{format: :email}
               }
             }
           } = field

    assert label_child.slot == :label
    assert control_child.slot == :control
    assert help_child.slot == :help

    assert %Element{
             kind: :label,
             id: "email-input-label",
             attributes: %{label: %{for: "email-input", relationship: :field_label}}
           } = label_child.element

    assert control_child.element == control

    assert %Element{
             kind: :text,
             attributes: %{content: %{text: "We will never share your email."}}
           } = help_child.element
  end

  test "builds semantic form_field composites alongside baseline fields" do
    control =
      Input.text_input(
        id: "project-name-input",
        name: :project_name,
        placeholder: "Semantic widgets rollout"
      )

    form_field =
      Forms.form_field(control,
        id: "project-name-field",
        label: "Project name",
        help: "Shown in project dashboards."
      )

    assert %Element{
             id: "project-name-field",
             kind: :form_field,
             children: [label_child, control_child, help_child],
             attributes: %{
               field: %{
                 control_id: "project-name-input",
                 label_slot: :label,
                 help_slot: :help
               }
             }
           } = form_field

    assert label_child.slot == :label
    assert control_child.slot == :control
    assert help_child.slot == :help
  end
end
