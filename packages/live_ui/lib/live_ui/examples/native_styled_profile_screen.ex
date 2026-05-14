defmodule LiveUi.Examples.NativeStyledProfileScreen do
  @moduledoc """
  Maintained native styling example for a directly authored profile screen.
  """

  alias LiveUi.Examples.StyledExampleStyles

  use LiveUi.Screen, id: :native_styled_profile, title: "Native Styled Profile"

  @impl true
  def mount_defaults do
    %{name: "Pascal", status: "Connected"}
  end

  @impl true
  def render(assigns) do
    theme = LiveUi.Theme.default()

    assigns =
      assigns
      |> Map.put(
        :box_style,
        LiveUi.Style.component_assigns(:box,
          theme: theme,
          style: StyledExampleStyles.profile_shell()
        )
      )
      |> Map.put(
        :title_style,
        LiveUi.Style.component_assigns(:text,
          theme: theme,
          style: StyledExampleStyles.profile_title()
        )
      )
      |> Map.put(
        :status_style,
        LiveUi.Style.component_assigns(:text,
          theme: theme,
          style: StyledExampleStyles.profile_status()
        )
      )
      |> Map.put(
        :input_style,
        LiveUi.Style.component_assigns(:text_input,
          theme: theme,
          style: StyledExampleStyles.profile_input()
        )
      )
      |> Map.put(
        :button_style,
        LiveUi.Style.component_assigns(:button,
          theme: theme,
          style: StyledExampleStyles.profile_button()
        )
      )

    ~H"""
    <LiveUi.Widgets.Box.render
      id="profile-shell"
      padding="lg"
      border="subtle"
      background="panel"
      {@box_style}
    >
      <LiveUi.Widgets.Text.render id="profile-title" content="Profile" {@title_style} />
      <LiveUi.Widgets.Text.render id="profile-status" content={@status} {@status_style} />
      <LiveUi.Widgets.TextInput.render
        id="profile-name"
        name="name"
        value={@name}
        placeholder="Name"
        {@input_style}
      />
      <LiveUi.Widgets.Button.render id="profile-save" label="Save" {@button_style} />
    </LiveUi.Widgets.Box.render>
    """
  end

  def metadata do
    %{
      id: :native_styled_profile,
      title: title(),
      families: [:styling, :input, :continuity],
      comparable_to: :canonical_styled_profile,
      summary: "Native styled profile screen paired with its canonical equivalent."
    }
  end
end
