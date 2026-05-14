defmodule LiveUi.ScreenTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule ExampleScreen do
    use LiveUi.Screen, id: :example_screen, title: "Example Screen"

    @impl true
    def mount_defaults do
      %{status: :ready}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="screen" title={title()}>
        <LiveUi.Widgets.Text.render id="status" content={Atom.to_string(@status)} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  test "screen definitions expose baseline mount and metadata contracts" do
    definition = LiveUi.Screen.definition(ExampleScreen)

    assert definition.id == :example_screen
    assert definition.title == "Example Screen"
    assert definition.mount_defaults == %{status: :ready}
    assert definition.metadata.server_authoritative?
    assert definition.event_routes == %{}
    assert definition.bridge_hooks == []
  end

  test "screens render through shared screen shell composition" do
    html = render_component(&ExampleScreen.render/1, %{status: :ready})

    assert html =~ "Example Screen"
    assert html =~ "ready"
    assert html =~ "data-live-ui-widget=\"screen-shell\""
  end
end
