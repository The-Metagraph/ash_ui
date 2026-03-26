defmodule UnifiedUi.Examples.ProfileForm do
  @moduledoc """
  Reference workflow for baseline forms, inputs, and navigation constructs.
  """

  use UnifiedUi.Dsl

  identity do
    id(:profile_form_example)
    title("Profile Form Example")
    authored_ref([:examples, :profile_form_example])
    tags([:example, :form])
  end

  composition do
    root(:profile_form_example_root)
    mode(:screen)

    form_builder :profile_form do
      summary("Profile update workflow")
      submit_intent(:save_profile)

      field_group :profile_identity do
        legend("Identity")

        field :display_name do
          field_name(:display_name)
          label("Display name")
          value_path([:profile, :display_name])

          text_input :display_name_input do
            placeholder("Display name")
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
        items(save: "Save", discard: "Discard")
        label("Profile actions")
      end
    end
  end
end
