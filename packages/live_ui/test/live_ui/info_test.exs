defmodule LiveUi.InfoTest do
  use ExUnit.Case, async: true

  defmodule InspectableScreen do
    use LiveUi.Screen, id: :inspectable_screen, title: "Inspectable"

    @impl true
    def mount_defaults do
      %{status: :ready}
    end

    @impl true
    def event_routes do
      %{"refresh" => :refresh}
    end

    @impl true
    def bridge_hooks do
      [:resize_observer]
    end

    @impl true
    def handle_event(:refresh, _payload, assigns) do
      {:ok, assigns}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="inspectable" title={title()}>
        <LiveUi.Widgets.Text.render id="status" content={Atom.to_string(@status)} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  test "widget summaries expose metadata contracts" do
    assert %{
             module: LiveUi.Widgets.ScreenShell,
             component_module: LiveUi.Widgets.ScreenShell.Component,
             mountable?: true,
             runtime_boundary: :live_component,
             family: :layout,
             name: :screen_shell,
             slots: [:inner_block],
             style_hooks: [:tone, :variant, :state]
           } = LiveUi.Info.widget_summary(LiveUi.Widgets.ScreenShell)
  end

  test "screen summaries expose mount defaults and bridge rules" do
    assert %{
             module: InspectableScreen,
             id: :inspectable_screen,
             title: "Inspectable",
             mount_defaults: %{status: :ready},
             event_routes: %{"refresh" => :refresh},
             bridge_hooks: [:resize_observer]
           } = LiveUi.Info.screen_summary(InspectableScreen)
  end

  test "package summary exposes validation state" do
    assert %{
             validation_state: %{
               mount: :ready,
               canonical_renderer: :advanced_ready,
               advanced_diagnostics: :ready
             }
           } =
             LiveUi.Info.package_summary()
  end
end
