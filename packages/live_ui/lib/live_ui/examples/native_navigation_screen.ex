defmodule LiveUi.Examples.NativeNavigationScreen do
  @moduledoc """
  Baseline native navigation example.
  """

  use LiveUi.Screen, id: :native_navigation, title: "Native Navigation"

  @impl true
  def mount_defaults do
    %{active: "details"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LiveUi.Widgets.ScreenShell.render id="native-navigation" title={title()}>
      <LiveUi.Widgets.Menu.render
        id="menu"
        active_item={@active}
        items={[%{id: "details", label: "Details"}, %{id: "activity", label: "Activity"}]}
      />
      <LiveUi.Widgets.Tabs.render
        id="tabs"
        active_item={@active}
        items={[%{id: "details", label: "Details"}, %{id: "activity", label: "Activity"}]}
      />
    </LiveUi.Widgets.ScreenShell.render>
    """
  end

  def metadata do
    %{
      id: :native_navigation,
      title: title(),
      families: [:navigation],
      comparable_to: :canonical_navigation,
      summary: "Native foundational navigation workflow."
    }
  end
end
