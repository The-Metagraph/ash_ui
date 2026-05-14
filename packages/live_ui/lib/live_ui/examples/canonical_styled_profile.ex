defmodule LiveUi.Examples.CanonicalStyledProfile do
  @moduledoc """
  Maintained canonical styling example for the profile continuity workflow.
  """

  alias LiveUi.Examples.StyledExampleStyles
  alias UnifiedIUR.Container
  alias UnifiedIUR.Widgets.{Foundational, Input}

  def element do
    Container.box(
      [
        Foundational.text("Profile",
          id: "profile-title",
          style: StyledExampleStyles.profile_title(),
          theme: %{id: :live_ui}
        ),
        Foundational.text("Connected",
          id: "profile-status",
          style: StyledExampleStyles.profile_status(),
          theme: %{id: :live_ui}
        ),
        Input.text_input(
          id: "profile-name",
          name: "name",
          value: "Pascal",
          placeholder: "Name",
          style: StyledExampleStyles.profile_input(),
          theme: %{id: :live_ui}
        ),
        Foundational.button("Save",
          id: "profile-save",
          style: StyledExampleStyles.profile_button(),
          theme: %{id: :live_ui}
        )
      ],
      id: "profile-shell",
      padding: "lg",
      border: "subtle",
      background: "panel",
      style: StyledExampleStyles.profile_shell(),
      theme: %{id: :live_ui}
    )
  end

  def metadata do
    %{
      id: :canonical_styled_profile,
      title: "Canonical Styled Profile",
      families: [:styling, :input, :continuity],
      comparable_to: :native_styled_profile,
      summary: "Canonical styled profile that reuses the native runtime surface."
    }
  end
end
