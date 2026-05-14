defmodule LiveUi.Examples.NativeBoundaryScreen do
  @moduledoc """
  Maintained native screen example for direct-local and canonical-boundary
  transport flows.
  """

  use LiveUi.Screen, id: :native_boundary, title: "Native Boundary"

  @impl true
  def mount_defaults do
    %{name: "Pascal", width: 0, palette_open?: false}
  end

  @impl true
  def event_routes do
    %{
      "rename" => :rename_profile,
      "resize_observer" => :measure_viewport,
      "open_palette" => :open_palette
    }
  end

  @impl true
  def bridge_hooks do
    [:resize_observer]
  end

  @impl true
  def handle_event(:rename_profile, %{"name" => name}, assigns) do
    {:ok, %{assigns | name: name}}
  end

  def handle_event(:measure_viewport, %{width: width}, assigns) do
    {:ok, %{assigns | width: width}}
  end

  def handle_event(:open_palette, _payload, assigns) do
    {:ok, %{assigns | palette_open?: true}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LiveUi.Widgets.ScreenShell.render id="native-boundary" title={title()}>
      <LiveUi.Forms.FormBuilder.render id="profile-form">
        <LiveUi.Forms.Field.render id="profile-name-field" name="name">
          <:label>Name</:label>
          <:control>
            <LiveUi.Widgets.TextInput.render id="profile-name" name="name" value={@name} />
          </:control>
        </LiveUi.Forms.Field.render>
      </LiveUi.Forms.FormBuilder.render>
      <LiveUi.Widgets.Button.render id="open-palette" label="Open Palette" />
      <LiveUi.Widgets.Text.render id="viewport-width" content={"Width: #{@width}"} />
    </LiveUi.Widgets.ScreenShell.render>
    """
  end

  def local_event_example do
    [
      family: :change,
      intent: :rename_profile,
      screen: id(),
      element_id: :profile_name,
      widget: :text_input,
      runtime_event: "rename",
      payload: %{"name" => "Ari"}
    ]
  end

  def boundary_event_example do
    Keyword.put(local_event_example(), :boundary, :boundary)
  end

  def hook_event_example do
    %{
      hook: :resize_observer,
      payload: %{"width" => 120, "height" => 80},
      opts: [event: "resize_observer", family: :change, intent: :measure_viewport]
    }
  end

  def metadata do
    %{
      id: :native_boundary,
      title: title(),
      families: [:transport, :change, :command],
      comparable_to: :canonical_boundary,
      summary: "Native screen showing local and boundary-safe transport flows."
    }
  end
end
