defmodule LiveUi.Phase1IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule MinimalScreen do
    use LiveUi.Screen, id: :minimal_screen, title: "Minimal Screen"

    @impl true
    def mount_defaults do
      %{message: "ready"}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.ScreenShell.render id="minimal" title={title()}>
        <LiveUi.Widgets.Text.render id="message" content={@message} />
      </LiveUi.Widgets.ScreenShell.render>
      """
    end
  end

  defmodule BadDefaultsScreen do
    use LiveUi.Screen, id: :bad_defaults, title: "Bad Defaults"

    @impl true
    def mount_defaults do
      :invalid
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Text.render id="bad-defaults" content={inspect(@runtime_state)} />
      """
    end
  end

  defmodule BadHandlerScreen do
    use LiveUi.Screen, id: :bad_handler, title: "Bad Handler"

    @impl true
    def mount_defaults do
      %{count: 0}
    end

    @impl true
    def event_routes do
      %{"break" => :break}
    end

    @impl true
    def handle_event(:break, _payload, _assigns) do
      :not_a_valid_reply
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Text.render id="bad-handler" content={Integer.to_string(@count)} />
      """
    end
  end

  test "package compiles as a library and exposes runtime entrypoints without application takeover" do
    assert [extra_applications: [:logger]] = LiveUi.MixProject.application()
    assert LiveUi.runtime() == LiveUi.Runtime
    assert LiveUi.renderer() == LiveUi.Renderer
    assert LiveUi.transport() == LiveUi.Transport
    assert LiveUi.Runtime.component() == LiveUi.Runtime.ScreenComponent
  end

  test "minimal native screens mount and render through the shared runtime backbone" do
    assert {:ok, runtime_state} =
             LiveUi.Runtime.mount(MinimalScreen, assigns: %{message: "mounted"})

    html =
      render_component(LiveUi.Runtime.component(), id: "minimal", runtime_state: runtime_state)

    assert html =~ "Minimal Screen"
    assert html =~ "mounted"
    assert html =~ "data-live-ui-runtime=\"screen\""
  end

  test "malformed runtime wiring fails with deterministic diagnostics" do
    assert {:error, %LiveUi.Runtime.Error{reason: :invalid_mount_defaults}} =
             LiveUi.Runtime.mount(BadDefaultsScreen)

    assert {:ok, runtime_state} = LiveUi.Runtime.mount(BadHandlerScreen)

    assert {:error, %LiveUi.Runtime.Error{reason: :invalid_event_result}} =
             LiveUi.Runtime.handle_event(runtime_state, "break", %{})

    assert {:error, %LiveUi.Runtime.Error{reason: :invalid_event_route}} =
             LiveUi.Runtime.handle_event(runtime_state, "unknown", %{})
  end

  test "reference and inspection surfaces remain usable before canonical renderer coverage exists" do
    assert %{
             runtime: %{assumptions: %{server_authoritative?: true}},
             responsibilities: %{canonical_renderer: responsibilities}
           } = LiveUi.reference()

    assert :consume_canonical_iur in responsibilities

    assert %{
             id: :minimal_screen,
             mount_defaults: %{message: "ready"},
             metadata: %{server_authoritative?: true}
           } = LiveUi.Info.screen_summary(MinimalScreen)

    assert %{
             validation_state: %{
               canonical_renderer: :advanced_ready,
               advanced_diagnostics: :ready,
               mount: :ready
             }
           } =
             LiveUi.Info.package_summary()
  end
end
