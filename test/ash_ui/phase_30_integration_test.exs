defmodule AshUI.Phase30IntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  alias AshUI.Compilation.IUR
  alias AshUI.Navigation.Intent
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias AshUI.Runtime.Navigation
  alias AshUI.Test.RuntimeFixtures
  alias UnifiedIUR.Interactions.Transport

  describe "Section 30.6 - Phase 30 integration tests" do
    test "upgraded packages, Spark, and resource-authored navigation compile together" do
      assert Code.ensure_loaded?(Spark.Dsl)
      assert Code.ensure_loaded?(UnifiedIUR.Element)
      assert Code.ensure_loaded?(UnifiedIUR.Interaction)
      assert Code.ensure_loaded?(UnifiedUi.Signal)

      assert Code.ensure_loaded?(LiveUi.Renderer)
      assert Code.ensure_loaded?(ElmUi.Renderer)
      assert Code.ensure_loaded?(DesktopUi.Renderer)

      assert :spark in Application.spec(:ash, :applications)

      assert {:ok, element} =
               AshUI.Resource.Info.element_definition(
                 AshUI.Test.ResourceAuthorityNavigationButtonElement
               )

      assert {:ok, [action]} =
               AshUI.Resource.Info.element_actions(
                 AshUI.Test.ResourceAuthorityNavigationButtonElement
               )

      ash_iur =
        IUR.new(:screen,
          id: "resource-authored-navigation",
          name: "resource_authored_navigation",
          children: [
            IUR.new(element.type,
              id: element.metadata.id,
              props: Map.put(element.props, :actions, [action])
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert {:ok, normalized} = UnifiedIUR.Normalize.element(canonical)
      assert :ok = UnifiedIUR.Validate.element(normalized)

      [child] = normalized.children
      [interaction] = child.element.attributes.interactions

      assert interaction.family == :navigation
      assert get_in(interaction.target, [:navigation, :action]) == :navigate_to
      assert get_in(interaction.target, [:navigation, :screen]) == :settings
    end

    test "canonical navigation scenarios compile, validate, and resolve at runtime" do
      canonical = canonical_navigation_suite()

      assert {:ok, local_entry} =
               Navigation.find_interaction(
                 canonical,
                 :show_details,
                 "local-details-button",
                 :click
               )

      assert %{
               kind: :local_destination,
               binding: :active_panel,
               destination: :details_panel
             } =
               Intent.descriptor!(%{binding: :active_panel, destination: :details_panel})

      local_navigation = local_entry.interaction.target.navigation
      assert local_navigation.kind == :local_destination

      assert get_in(local_entry.interaction.payload, [:mapping, :active_panel]) == %{
               from: :binding,
               key: :active_panel
             }

      navigation_graph = %{
        screens: [
          %{id: "settings-screen", name: "settings", route: "/settings"},
          %{id: "dashboard-screen", name: "dashboard", route: "/dashboard"}
        ],
        modals: [
          %{id: "confirm-delete-modal", name: "confirm_delete", modal: :confirm_delete}
        ]
      }

      for {action_id, element_id} <- [
            {:open_settings, "settings-button"},
            {:replace_dashboard, "replace-dashboard-button"},
            {:go_back, "back-button"},
            {:go_forward, "forward-button"},
            {:open_confirm, "open-confirm-button"},
            {:close_confirm, "close-confirm-button"}
          ] do
        assert {:ok, entry} =
                 Navigation.find_interaction(canonical, action_id, element_id, :click)

        descriptor = Transport.boundary_descriptor(entry.interaction)

        assert :ok = Transport.validate_boundary_descriptor(descriptor)

        assert {:ok, result} =
                 Navigation.execute(entry.interaction, %{navigation_graph: navigation_graph})

        assert result.transport_summary.action ==
                 get_in(descriptor, [:target, :navigation, :action])
      end

      assert {:ok, open_modal_entry} =
               Navigation.find_interaction(
                 canonical,
                 :open_confirm,
                 "open-confirm-button",
                 :click
               )

      assert {:ok, open_modal_result} =
               Navigation.execute(open_modal_entry.interaction, %{
                 navigation_graph: navigation_graph
               })

      assert open_modal_result.resolution.target.id == "confirm-delete-modal"
      assert open_modal_result.resolution.params.record_id == "user-1"

      assert {:ok, close_modal_entry} =
               Navigation.find_interaction(
                 canonical,
                 :close_confirm,
                 "close-confirm-button",
                 :click
               )

      assert close_modal_entry.interaction.target.navigation.modal_stack.stack_effect ==
               :close_topmost_or_named_modal
    end

    test "renderer adapters and LiveView event handling consume the same canonical root" do
      canonical = canonical_navigation_suite()

      assert {:ok, heex} = LiveUIAdapter.render(canonical)
      assert heex =~ "data-live-ui-runtime"
      assert {:ok, %ElmUi.Widget{}} = ElmUIAdapter.render(canonical)
      assert {:ok, %DesktopUi.Widget{}} = DesktopUIAdapter.render(canonical)

      socket =
        RuntimeFixtures.socket(
          ash_ui_base_iur: canonical,
          ash_ui_navigation_graph: %{
            screens: [%{id: "settings-screen", name: "settings", route: "/settings"}],
            modals: [%{id: "confirm-delete-modal", name: "confirm_delete"}]
          }
        )

      assert {:reply, %{status: :ok, navigation: summary}, socket} =
               AshUI.LiveView.EventHandler.handle_action_event(
                 %{
                   "action_id" => "open_settings",
                   "element_id" => "settings-button",
                   "signal" => "click"
                 },
                 socket
               )

      assert summary.action == :navigate_to
      assert socket.assigns.ash_ui_navigation.resolution.target.route == "/settings"
      assert [latest | _history] = socket.assigns.ash_ui_navigation_history
      assert latest.transport_summary.action == :navigate_to
    end

    test "forbidden host and runtime fields are rejected before canonical transport" do
      for intent <- [
            %{action: :navigate_to, screen: :settings, route: "/settings"},
            %{action: :navigate_to, screen: :settings, url: "https://example.invalid/settings"},
            %{action: :navigate_to, screen: :settings, helper: :settings_path},
            %{action: :navigate_to, screen: :settings, runtime_module: MyApp.Navigation},
            %{action: :open_modal, modal: :confirm_delete, modal_stack: %{stack_id: "runtime"}}
          ] do
        assert_raise ArgumentError, fn ->
          Intent.normalize!(intent)
        end
      end
    end
  end

  defp canonical_navigation_suite do
    ash_iur =
      IUR.new(:screen,
        id: "phase-30-navigation-suite",
        name: "phase_30_navigation_suite",
        children: [
          button("local-details-button", "Details", %{
            id: :show_details,
            navigation: %{binding: :active_panel, destination: :details_panel},
            payload_mapping: %{active_panel: %{from: :binding, key: :active_panel}},
            binding_refs: [:active_panel]
          }),
          button("settings-button", "Settings", %{
            id: :open_settings,
            navigation: %{action: :navigate_to, screen: :settings, params: %{tab: :profile}}
          }),
          button("replace-dashboard-button", "Dashboard", %{
            id: :replace_dashboard,
            navigation: %{action: :replace_with, screen: :dashboard}
          }),
          button("back-button", "Back", %{
            id: :go_back,
            navigation: %{action: :go_back, metadata: %{source: :phase_30}}
          }),
          button("forward-button", "Forward", %{
            id: :go_forward,
            navigation: %{action: :go_forward}
          }),
          button("open-confirm-button", "Confirm", %{
            id: :open_confirm,
            navigation: %{
              action: :open_modal,
              modal: :confirm_delete,
              params: %{record_id: "user-1"}
            }
          }),
          button("close-confirm-button", "Close", %{
            id: :close_confirm,
            navigation: %{action: :close_modal}
          })
        ]
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
    canonical
  end

  defp button(id, label, action) do
    IUR.new(:button,
      id: id,
      props: %{
        label: label,
        actions: [
          action
          |> Map.put_new(:signal, :click)
          |> Map.put_new(:summary, label)
        ]
      }
    )
  end
end
