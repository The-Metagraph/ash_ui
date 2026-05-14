defmodule LiveUi.Examples.NativeDisplayScreen do
  @moduledoc """
  Baseline native display example.
  """

  use LiveUi.Screen, id: :native_display, title: "Native Display"

  @impl true
  def mount_defaults do
    %{status: "online"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LiveUi.Widgets.ScreenShell.render id="native-display" title={title()}>
      <LiveUi.Layout.Column.render id="display-column">
        <LiveUi.Widgets.Label.render id="status-label" for="status-value" content="Status" />
        <LiveUi.Widgets.Text.render id="status-value" content={@status} tone="positive" />
        <LiveUi.Widgets.Button.render id="refresh" label="Refresh" />
      </LiveUi.Layout.Column.render>
    </LiveUi.Widgets.ScreenShell.render>
    """
  end

  def metadata do
    %{
      id: :native_display,
      title: title(),
      families: [:content, :layout],
      comparable_to: :canonical_display,
      summary: "Native foundational display workflow."
    }
  end
end
