defmodule UnifiedUi.FormsNavigationTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule ProfileFormScreen do
    use UnifiedUi.Dsl

    identity do
      id(:profile_form_screen)
      authored_ref([:examples, :profile_form_screen])
    end

    composition do
      root(:profile_form_root)
      mode(:screen)

      form_builder :profile_form do
        summary("Profile editing workflow")
        submit_intent(:save_profile)

        field_group :profile_identity do
          legend("Identity")

          field :display_name do
            field_name(:display_name)
            label("Display name")
            value_path([:profile, :display_name])

            text_input :display_name_input do
              placeholder("Enter a display name")
            end
          end

          field :role do
            field_name(:role)
            label("Role")

            select :role_select do
              options(admin: "Admin", member: "Member")
            end
          end
        end

        tabs :profile_tabs do
          items(profile: "Profile", permissions: "Permissions")
          active_item(:profile)
        end

        command_palette :profile_commands do
          items(save: "Save profile", discard: "Discard changes")
          label("Profile actions")
        end
      end
    end
  end

  test "registers input, form, and navigation kinds for package inspection" do
    assert UnifiedUi.Widgets.input_kinds() == [
             :text_input,
             :numeric_input,
             :toggle,
             :checkbox,
             :radio_group,
             :select,
             :pick_list,
             :date_input,
             :time_input,
             :file_input
           ]

    assert UnifiedUi.Navigation.kinds() == [:menu, :tabs, :command_palette]
    assert UnifiedUi.Forms.kinds() == [:form_builder, :field_group, :field, :form_field]
  end

  test "stores forms, inputs, and navigation nodes in the authored composition tree" do
    [form] = Extension.get_entities(ProfileFormScreen, [:composition])

    assert form.family == :forms
    assert form.kind == :form_builder
    assert Enum.map(form.children, & &1.kind) == [:field_group, :tabs, :command_palette]

    [group | _] = form.children
    [field_one, field_two] = group.children

    assert field_one.kind == :field
    assert field_one.children |> List.first() |> Map.get(:kind) == :text_input
    assert field_two.children |> List.first() |> Map.get(:kind) == :select
  end

  test "summarizes authored form workflows without runtime packages" do
    assert UnifiedUi.Info.composition_summary(ProfileFormScreen) == [
             %{
               id: :profile_form,
               family: :forms,
               kind: :form_builder,
               summary: "Profile editing workflow",
               children: [
                 %{
                   id: :profile_identity,
                   family: :forms,
                   kind: :field_group,
                   children: [
                     %{
                       id: :display_name,
                       family: :forms,
                       kind: :field,
                       label: "Display name",
                       children: [
                         %{id: :display_name_input, family: :input, kind: :text_input}
                       ]
                     },
                     %{
                       id: :role,
                       family: :forms,
                       kind: :field,
                       label: "Role",
                       children: [
                         %{id: :role_select, family: :input, kind: :select}
                       ]
                     }
                   ]
                 },
                 %{
                   id: :profile_tabs,
                   family: :navigation,
                   kind: :tabs,
                   items: [profile: "Profile", permissions: "Permissions"]
                 },
                 %{
                   id: :profile_commands,
                   family: :navigation,
                   kind: :command_palette,
                   label: "Profile actions",
                   items: [save: "Save profile", discard: "Discard changes"]
                 }
               ]
             }
           ]
  end
end
