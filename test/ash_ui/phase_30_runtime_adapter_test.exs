defmodule AshUI.Phase30RuntimeAdapterTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  alias AshUI.Compilation.IUR
  alias AshUI.LiveView.{EventHandler, IURHydration}
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias AshUI.Runtime.Navigation
  alias AshUI.Test.RuntimeFixtures

  describe "Section 30.4 - runtime and renderer adapter realignment" do
    test "renderer adapters dispatch canonical Unified IUR structs to upgraded packages" do
      canonical = canonical_navigation_root()

      assert LiveUIAdapter.available?()
      assert ElmUIAdapter.available?()
      assert DesktopUIAdapter.available?()

      assert {:ok, heex} = LiveUIAdapter.render(canonical)
      assert is_binary(heex)
      assert heex =~ "data-live-ui-runtime"

      assert {:ok, %ElmUi.Widget{}} = ElmUIAdapter.render(canonical)
      assert {:ok, %DesktopUi.Widget{}} = DesktopUIAdapter.render(canonical)
    end

    test "adapter configuration helpers accept canonical roots without legacy map callers" do
      canonical = canonical_navigation_root()

      live_config = LiveUIAdapter.configure_event_bindings(canonical)
      assert live_config.event_prefix == "ash_ui"

      elm_config = ElmUIAdapter.configure_elm_integration(canonical)
      assert elm_config.flags["screen"]["type"] == "screen"
      [button] = elm_config.flags["screen"]["children"]
      assert [%{family: :navigation}] = button["interactions"]

      desktop_config = DesktopUIAdapter.configure_events(canonical)
      assert desktop_config.enable_shortcuts
    end

    test "LiveView hydration projects canonical roots into legacy hydrated assigns" do
      ash_iur =
        IUR.new(:screen,
          name: "profile",
          children: [
            IUR.new(:input,
              id: "display_name_input",
              props: %{name: "display_name"}
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      hydrated =
        IURHydration.hydrate(canonical, %{
          "display_name_input" => %{
            element_id: "display_name_input",
            binding_type: :value,
            target: "display_name",
            value: "Pascal"
          }
        })

      assert %{"type" => "screen", "children" => [%{"props" => %{"value" => "Pascal"}}]} =
               hydrated
    end

    test "navigation transport resolves symbolic screen targets at runtime boundary" do
      canonical = canonical_navigation_root()
      [interaction] = Navigation.interactions(canonical)

      assert {:ok, result} =
               Navigation.execute(interaction, %{
                 navigation_graph: %{
                   screens: [%{id: "settings-screen", name: "settings", route: "/settings"}]
                 }
               })

      assert result.transport_summary.action == :navigate_to
      assert result.resolution.target.route == "/settings"
      assert result.resolution.params.tab == :profile

      assert {:error, {:unresolved_navigation_target, :screen, :settings}} =
               Navigation.execute(interaction, %{navigation_graph: %{screens: []}})
    end

    test "LiveView action events fall through to canonical navigation when no Ash action binding exists" do
      canonical = canonical_navigation_root()

      socket =
        RuntimeFixtures.socket(
          ash_ui_base_iur: canonical,
          ash_ui_navigation_graph: %{
            screens: [%{id: "settings-screen", name: "settings", route: "/settings"}]
          }
        )

      assert {:reply, %{status: :ok, navigation: summary}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "open_settings",
                   "element_id" => "settings-button",
                   "signal" => "click"
                 },
                 socket
               )

      assert summary.action == :navigate_to
      assert socket.assigns.ash_ui_navigation.resolution.target.id == "settings-screen"
    end
  end

  defp canonical_navigation_root do
    ash_iur =
      IUR.new(:screen,
        name: "dashboard",
        children: [
          IUR.new(:button,
            id: "settings-button",
            props: %{
              label: "Settings",
              actions: [
                %{
                  id: :open_settings,
                  signal: :click,
                  navigation: %{
                    action: :navigate_to,
                    screen: :settings,
                    params: %{tab: :profile}
                  }
                }
              ]
            }
          )
        ]
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
    canonical
  end
end
