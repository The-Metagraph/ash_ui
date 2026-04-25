defmodule AshUI.Phase20RuntimeRealismTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.Phase20
  alias AshUI.LiveView.{EventHandler, Integration, UpdateIntegration}

  @representative_directories ["dialog", "list", "status", "cluster_dashboard"]

  @action_events %{
    "dialog" => %{
      "action_id" => "action_confirm_dialog_button",
      "element_id" => "confirm-dialog-button",
      "signal" => "click"
    },
    "list" => %{
      "action_id" => "action_load_handoff_queue_button",
      "element_id" => "load-handoff-queue-button",
      "signal" => "click"
    },
    "status" => %{
      "action_id" => "action_load_risk_status_button",
      "element_id" => "load-risk-status-button",
      "signal" => "click"
    },
    "cluster_dashboard" => %{
      "action_id" => "action_load_incident_cluster_dashboard_button",
      "element_id" => "load-incident-cluster-dashboard-button",
      "signal" => "click"
    }
  }

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(@representative_directories, &load_example_module!/1)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    flush_mailbox()
    :ok
  end

  describe "Section 20.5 - Runtime, Authorization, and Seed Realism" do
    test "20.5.1.1 - active viewers can mount representative advanced examples while operator-only writes stay enforced" do
      Enum.each(@representative_directories, fn directory ->
        module = Phase20.example_module(directory)
        contract = module.runtime_contract()
        mounted = mount_seeded_as!(module, module.read_only_user())

        assert contract.mount_actor == :active_viewer_required
        assert contract.mutate_roles == [:operator, :admin]
        assert mounted.actor.role == :viewer
        assert mounted.socket.assigns.ash_ui_user.role == :viewer
        assert mounted.socket.assigns.ash_ui_screen.name == Phase20.screen_name(directory)
      end)

      dialog_module = Phase20.example_module("dialog")
      seeded = dialog_module.seed!()
      inactive_user = Map.put(dialog_module.read_only_user(), :active, false)

      inactive_socket =
        dialog_module.build_socket(%{
          current_user: inactive_user,
          ash_ui_storage: seeded.ui_storage,
          ash_ui_domains: dialog_module.runtime_domains()
        })

      assert {:error, %Ash.Error.Forbidden{}} =
               Integration.mount_ui_screen(inactive_socket, seeded.screen_name, %{})

      assert_unauthorized_action("dialog", :selected_value, "awaiting decision")
      assert_unauthorized_action("list", :current_value, "triage queue")
      assert_unauthorized_action("status", :current_value, "watching")
      assert_unauthorized_action("cluster_dashboard", :current_value, "stable cluster")
    end

    test "20.5.1.2 - notification-backed families refresh mounted viewer sessions through ExampleState subscriptions" do
      Enum.each(
        [
          {
            "list",
            %{
              current_value: "operator queue",
              status: "List refreshed from operator notification.",
              items: [
                %{
                  "title" => "Operator refreshed row",
                  "summary" => "Notification-driven refresh reached the mounted viewer.",
                  "meta" => "Operator"
                }
              ]
            },
            ["Operator refreshed row", "List refreshed from operator notification."]
          },
          {
            "status",
            %{
              current_value: "operator risk",
              status: "Status refreshed from operator notification.",
              metric: %{
                "label" => "Operator risk",
                "tone" => "danger",
                "detail" => "Operator notification forced a viewer-visible status refresh."
              }
            },
            ["Operator risk", "Status refreshed from operator notification."]
          },
          {
            "cluster_dashboard",
            %{
              current_value: "operator incident",
              status: "Cluster dashboard refreshed from operator notification.",
              payload: %{
                "headline" => "Operator incident snapshot",
                "detail" => "Notification-backed refresh reached the mounted viewer.",
                "regions" => [
                  %{"label" => "us-east", "status" => "Degraded", "load" => "91%"},
                  %{"label" => "us-west", "status" => "Healthy", "load" => "57%"}
                ],
                "alerts" => [
                  %{
                    "title" => "Operator escalation",
                    "message" => "Viewer session refreshed from runtime notifications."
                  }
                ]
              }
            },
            [
              "Operator incident snapshot",
              "Cluster dashboard refreshed from operator notification."
            ]
          }
        ],
        fn {directory, attrs, rendered_fragments} ->
          module = Phase20.example_module(directory)
          contract = module.runtime_contract()
          mounted = mount_seeded_as!(module, module.read_only_user())
          runtime_resource = runtime_resource(module)

          assert contract.subscription_mode == :notification_required

          assert Enum.any?(mounted.socket.assigns.ash_ui_subscriptions, fn subscription ->
                   subscription.resource == runtime_resource
                 end)

          assert {:ok, updated_record} =
                   Ash.update(
                     runtime_state!(module, directory),
                     attrs,
                     actor: module.operator_user(),
                     authorize?: true,
                     domain: runtime_domain(module)
                   )

          assert updated_record.id == "state-#{directory}"

          assert_receive %Ash.Notifier.Notification{
                           resource: ^runtime_resource,
                           action: %{type: :update}
                         } = notification

          assert UpdateIntegration.relevant_notification?(notification, mounted.socket)

          assert {:noreply, updated_socket} =
                   UpdateIntegration.handle_notification(notification, mounted.socket)

          rendered_ui = module.rendered_ui(updated_socket.assigns)

          Enum.each(rendered_fragments, fn fragment ->
            assert rendered_ui =~ fragment
          end)
        end
      )
    end

    test "20.5.1.3 - the flagship operational example keeps failure and recovery visible inside the shared shell" do
      module = Phase20.example_module("cluster_dashboard")
      contract = module.runtime_contract()
      mounted = mount_seeded_as!(module, module.operator_user())

      assert contract.shell_state_surface == :status_and_support_notice
      assert contract.shell_state_story.loading =~ "mounted snapshot"
      assert contract.shell_state_story.failure =~ "degraded copy"
      assert contract.shell_state_story.recovery =~ "healthy state"

      initial_ui = module.rendered_ui(mounted.socket.assigns)

      assert initial_ui =~ "Regional cluster stable"
      assert initial_ui =~ "Cluster dashboard mounted with the stable multi-region snapshot."

      assert {:reply, %{status: :ok}, incident_socket} =
               EventHandler.handle_action_event(
                 @action_events["cluster_dashboard"],
                 mounted.socket
               )

      incident_remount =
        remount_screen!(
          module,
          mounted.screen_name,
          mounted.actor,
          mounted.ui_storage
        )

      incident_ui = module.rendered_ui(incident_remount.assigns)

      assert incident_ui =~ "Regional cluster degraded"
      assert incident_ui =~ "Cluster dashboard switched to the incident response snapshot."

      assert {:reply, %{status: :ok}, _recovered_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "action_load_stable_cluster_dashboard_button",
                   "element_id" => "load-stable-cluster-dashboard-button",
                   "signal" => "click"
                 },
                 incident_socket
               )

      recovered_remount =
        remount_screen!(
          module,
          mounted.screen_name,
          mounted.actor,
          mounted.ui_storage
        )

      recovered_ui = module.rendered_ui(recovered_remount.assigns)

      assert recovered_ui =~ "Regional cluster stable"
      assert recovered_ui =~ "Cluster dashboard mounted with the stable multi-region snapshot."
    end

    test "20.5.1.4 - the checked-in phase contract stays aligned with the authored advanced families" do
      contract = Phase20.runtime_contract()

      assert Enum.sort(Map.keys(contract)) == [
               :data_surfaces,
               :feedback_charts,
               :operational_monitoring,
               :overlay_layered_flows
             ]

      assert Phase20.runtime_contract_for("dialog").subscription_mode == :seeded_action_refresh
      assert Phase20.runtime_contract_for("list").subscription_mode == :notification_required
      assert Phase20.runtime_contract_for("status").subscription_mode == :notification_required

      assert Phase20.runtime_contract_for("cluster_dashboard").shell_state_surface ==
               :status_and_support_notice
    end
  end

  defp assert_unauthorized_action(directory, field, expected_value) do
    module = Phase20.example_module(directory)
    mounted = mount_seeded_as!(module, module.read_only_user())

    assert {:reply, %{status: :error, reason: "unauthorized"}, unauthorized_socket} =
             EventHandler.handle_action_event(@action_events[directory], mounted.socket)

    assert unauthorized_socket.assigns.flash.error ==
             "You are not authorized to perform this action"

    assert Map.get(runtime_state!(module, directory), field) == expected_value
  end

  defp mount_seeded_as!(module, actor) do
    seeded = module.seed!()

    socket =
      module.build_socket(%{
        current_user: actor,
        ash_ui_storage: seeded.ui_storage,
        ash_ui_domains: module.runtime_domains()
      })

    {:ok, mounted_socket} = Integration.mount_ui_screen(socket, seeded.screen_name, %{})
    {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)

    seeded
    |> Map.put(:actor, actor)
    |> Map.put(:socket, mounted_socket)
  end

  defp runtime_state!(module, directory) do
    module
    |> runtime_resource()
    |> Ash.read!(domain: runtime_domain(module), authorize?: false)
    |> Enum.find(&(&1.id == "state-#{directory}"))
  end

  defp runtime_resource(module), do: Module.concat([module, Runtime, ExampleState])
  defp runtime_domain(module), do: Module.concat([module, RuntimeDomain])

  defp remount_screen!(module, screen_name, actor, ui_storage) do
    socket =
      module.build_socket(%{
        current_user: actor,
        ash_ui_storage: ui_storage,
        ash_ui_domains: module.runtime_domains()
      })

    {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen_name, %{})
    {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)
    mounted_socket
  end

  defp flush_mailbox do
    receive do
      _message -> flush_mailbox()
    after
      0 -> :ok
    end
  end

  defp load_example_module!(directory) do
    module = Phase20.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase20.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
