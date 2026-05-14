defmodule LiveUi.Examples.NativeFormScreen do
  @moduledoc """
  Baseline native form example.
  """

  use LiveUi.Screen, id: :native_form, title: "Native Form"

  @impl true
  def mount_defaults do
    %{name: "Pascal"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LiveUi.Widgets.ScreenShell.render id="native-form" title={title()}>
      <LiveUi.Forms.FormBuilder.render id="profile-form">
        <LiveUi.Forms.FieldGroup.render id="identity" legend="Identity">
          <LiveUi.Forms.Field.render id="name-field" name="name">
            <:label>Name</:label>
            <:control>
              <LiveUi.Widgets.TextInput.render id="name" name="name" value={@name} />
            </:control>
          </LiveUi.Forms.Field.render>
        </LiveUi.Forms.FieldGroup.render>
      </LiveUi.Forms.FormBuilder.render>
    </LiveUi.Widgets.ScreenShell.render>
    """
  end

  def metadata do
    %{
      id: :native_form,
      title: title(),
      families: [:input, :forms],
      comparable_to: :canonical_form,
      summary: "Native foundational form workflow."
    }
  end
end
