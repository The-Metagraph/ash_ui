defmodule AshUI.Phase20IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase20}
  alias AshUI.LiveView.{EventHandler, Integration, UpdateIntegration}

  @representative_examples [
    {"dialog", "ash-dialog-surface"},
    {"list", "ash-list"},
    {"status", "ash-status-surface"},
    {"cluster_dashboard", "ash-cluster-dashboard"}
  ]

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase20.definitions(), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    flush_mailbox()
    :ok
  end

  describe "Section 20.6 - Phase 20 Integration Tests" do
    test "20.6.1.1 - advanced examples boot as independent projects and mount seeded screens" do
      Enum.each(Phase20.definitions(), fn definition ->
        module = Phase20.example_module(definition.directory)
        project_path = Phase20.project_path(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert File.exists?(Path.join(project_path, "mix.exs"))
        assert File.exists?(Path.join(project_path, "README.md"))
        assert File.exists?(Path.join(project_path, "config/config.exs"))
        assert File.exists?(Path.join(project_path, "assets/css/app.css"))

        assert mounted.screen_name == Phase20.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_ui =~ expected_subject_fragment(definition.directory)
      end)
    end

    test "20.6.1.2 - representative apps demonstrate real action, transition, and notification runtime paths" do
      dialog_module = Phase20.example_module("dialog")
      dialog_mounted = mount_seeded_as!(dialog_module, dialog_module.operator_user())

      assert {:reply, %{status: :ok}, _dialog_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "action_confirm_dialog_button",
                   "element_id" => "confirm-dialog-button",
                   "signal" => "click"
                 },
                 dialog_mounted.socket
               )

      dialog_remount =
        remount_screen!(
          dialog_module,
          dialog_mounted.screen_name,
          dialog_mounted.actor,
          dialog_mounted.ui_storage
        )

      assert dialog_module.rendered_ui(dialog_remount.assigns) =~ "confirmed"

      list_module = Phase20.example_module("list")
      list_mounted = mount_seeded_as!(list_module, list_module.read_only_user())
      list_resource = runtime_resource(list_module)

      assert {:ok, _updated_list_state} =
               Ash.update(
                 runtime_state!(list_module, "list"),
                 %{
                   current_value: "operator queue",
                   status: "List refreshed through Phase 20 integration coverage.",
                   items: [
                     %{
                       "title" => "Integration refreshed row",
                       "summary" => "Viewer session updated through ExampleState notifications.",
                       "meta" => "Integration"
                     }
                   ]
                 },
                 actor: list_module.operator_user(),
                 authorize?: true,
                 domain: runtime_domain(list_module)
               )

      assert_receive %Ash.Notifier.Notification{
                       resource: ^list_resource,
                       action: %{type: :update}
                     } = list_notification

      assert {:noreply, list_socket} =
               UpdateIntegration.handle_notification(list_notification, list_mounted.socket)

      assert list_module.rendered_ui(list_socket.assigns) =~ "Integration refreshed row"

      status_module = Phase20.example_module("status")
      status_mounted = mount_seeded_as!(status_module, status_module.read_only_user())
      status_resource = runtime_resource(status_module)

      assert {:ok, _updated_status_state} =
               Ash.update(
                 runtime_state!(status_module, "status"),
                 %{
                   current_value: "integration risk",
                   status: "Status refreshed through Phase 20 integration coverage.",
                   metric: %{
                     "label" => "Integration risk",
                     "tone" => "danger",
                     "detail" => "Feedback state updated through runtime notifications."
                   }
                 },
                 actor: status_module.operator_user(),
                 authorize?: true,
                 domain: runtime_domain(status_module)
               )

      assert_receive %Ash.Notifier.Notification{
                       resource: ^status_resource,
                       action: %{type: :update}
                     } = status_notification

      assert {:noreply, status_socket} =
               UpdateIntegration.handle_notification(status_notification, status_mounted.socket)

      assert status_module.rendered_ui(status_socket.assigns) =~ "Integration risk"

      cluster_module = Phase20.example_module("cluster_dashboard")
      cluster_mounted = mount_seeded_as!(cluster_module, cluster_module.operator_user())

      assert {:reply, %{status: :ok}, _cluster_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "action_load_incident_cluster_dashboard_button",
                   "element_id" => "load-incident-cluster-dashboard-button",
                   "signal" => "click"
                 },
                 cluster_mounted.socket
               )

      cluster_remount =
        remount_screen!(
          cluster_module,
          cluster_mounted.screen_name,
          cluster_mounted.actor,
          cluster_mounted.ui_storage
        )

      cluster_ui = cluster_module.rendered_ui(cluster_remount.assigns)

      assert cluster_ui =~ "Regional cluster degraded"
      assert cluster_ui =~ "Gateway retries"
    end

    test "20.6.1.3 - representative advanced examples preserve the Ash HQ shell while foregrounding their primary subject" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(@representative_examples, fn {directory, subject_fragment} ->
        module = Phase20.example_module(directory)
        definition = Phase20.definition!(directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, directory, rendered_ui)

        assert module.theme_css() =~ "--ashui-example-primary-gradient"
        assert module.theme_css() =~ ".ashui-example-shell"
        assert module.theme_css() =~ ".ashui-example-review-grid"
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ "ashui-example-shell-title"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text
        assert rendered_ui =~ subject_fragment
      end)
    end

    test "20.6.1.4 - advanced examples compile from resource authority without document-first shortcuts or hidden runtime paths" do
      Enum.each(@representative_examples, fn {directory, _subject_fragment} ->
        module = Phase20.example_module(directory)
        mounted = module.mount_seeded!()
        screen = mounted.screen
        unified_dsl = screen.unified_dsl
        runtime_contract = module.runtime_contract()

        assert get_in(unified_dsl, ["screen", "inline_fragment"]) == nil
        refute Map.has_key?(unified_dsl, "screen_document")
        assert get_in(unified_dsl, ["composition", "roots"]) != []

        assert {:ok, compiled_iur} =
                 Compiler.compile(screen, use_cache: false, ui_storage: module.ui_storage())

        assert compiled_iur.metadata["ash_ui"]["authoring_source"]["kind"] == "resource_authority"
        assert runtime_contract.mount_actor == :active_viewer_required

        if runtime_contract.subscription_mode == :notification_required do
          assert Enum.any?(mounted.socket.assigns.ash_ui_subscriptions, fn subscription ->
                   subscription.resource == runtime_resource(module)
                 end)
        end
      end)
    end
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

  defp runtime_state!(module, directory) do
    module
    |> runtime_resource()
    |> Ash.read!(domain: runtime_domain(module), authorize?: false)
    |> Enum.find(&(&1.id == "state-#{directory}"))
  end

  defp runtime_resource(module), do: Module.concat([module, Runtime, ExampleState])
  defp runtime_domain(module), do: Module.concat([module, RuntimeDomain])

  defp expected_subject_fragment("overlay"), do: "ash-overlay-surface"
  defp expected_subject_fragment("dialog"), do: "ash-dialog-surface"
  defp expected_subject_fragment("alert_dialog"), do: "ash-alert-dialog-surface"
  defp expected_subject_fragment("context_menu"), do: "ash-context-menu"
  defp expected_subject_fragment("toast"), do: "ash-toast"
  defp expected_subject_fragment("list"), do: "ash-list"
  defp expected_subject_fragment("table"), do: "ash-table-surface"
  defp expected_subject_fragment("tree_view"), do: "ash-tree-view"
  defp expected_subject_fragment("markdown_viewer"), do: "ash-markdown-viewer"
  defp expected_subject_fragment("log_viewer"), do: "ash-log-viewer"
  defp expected_subject_fragment("status"), do: "ash-status-surface"
  defp expected_subject_fragment("progress"), do: "ash-progress-surface"
  defp expected_subject_fragment("gauge"), do: "ash-gauge-surface"
  defp expected_subject_fragment("inline_feedback"), do: "ash-inline-feedback"
  defp expected_subject_fragment("sparkline"), do: "ash-sparkline-surface"
  defp expected_subject_fragment("bar_chart"), do: "ash-bar-chart"
  defp expected_subject_fragment("line_chart"), do: "ash-line-chart"
  defp expected_subject_fragment("stream_widget"), do: "ash-stream-widget"
  defp expected_subject_fragment("process_monitor"), do: "ash-process-monitor"
  defp expected_subject_fragment("supervision_tree_viewer"), do: "ash-supervision-tree-viewer"
  defp expected_subject_fragment("cluster_dashboard"), do: "ash-cluster-dashboard"

  defp render_example_live(module, directory, rendered_ui) do
    live_module = Module.concat([module, Web, ExampleLive])

    live_module.render(%{
      __changed__: %{},
      page_title: module.title(),
      example_directory: directory,
      theme_css: module.theme_css(),
      rendered_ui: rendered_ui
    })
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
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
