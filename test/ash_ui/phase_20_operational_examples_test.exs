defmodule AshUI.Phase20OperationalExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase20}
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase20.definitions_for(:operational_monitoring), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 20.4 - Operational and Monitoring Example Apps" do
    test "20.4.1.4 - every operational app mounts through the shared shell and keeps the runtime surface visible" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase20.definitions_for(:operational_monitoring), fn definition ->
        module = Phase20.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase20.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text

        assert File.exists?(Path.join(Phase20.project_path(definition.directory), "mix.exs"))
        assert File.exists?(Path.join(Phase20.project_path(definition.directory), "README.md"))
      end)
    end

    test "20.4.1.4 - representative operational examples preserve snapshot updates and action-driven control flows" do
      assert_operational_transition(
        "stream_widget",
        %{
          "action_id" => "action_load_deploy_stream_widget_button",
          "element_id" => "load-deploy-stream-widget-button",
          "signal" => "click"
        },
        "state-stream_widget",
        %{
          current_value: "deploy stream",
          status: "Stream widget switched to the deploy feed snapshot."
        },
        ["entries"],
        [
          "Canary reached 25 percent of its target scope.",
          "Stream widget switched to the deploy feed snapshot."
        ]
      )

      assert_operational_transition(
        "process_monitor",
        %{
          "action_id" => "action_load_pressure_process_monitor_button",
          "element_id" => "load-pressure-process-monitor-button",
          "signal" => "click"
        },
        "state-process_monitor",
        %{
          current_value: "pressure state",
          status: "Process monitor switched to the restart-pressure snapshot."
        },
        ["model"],
        ["restart-pressure snapshot", "queue_worker"]
      )

      assert_operational_transition(
        "supervision_tree_viewer",
        %{
          "action_id" => "action_load_recovery_supervision_tree_button",
          "element_id" => "load-recovery-supervision-tree-button",
          "signal" => "click"
        },
        "state-supervision_tree_viewer",
        %{
          current_value: "recovery supervision",
          status: "Supervision tree viewer switched to the recovery supervision snapshot."
        },
        ["model"],
        ["Recovery supervisor", "rollback_worker"]
      )

      assert_operational_transition(
        "cluster_dashboard",
        %{
          "action_id" => "action_load_incident_cluster_dashboard_button",
          "element_id" => "load-incident-cluster-dashboard-button",
          "signal" => "click"
        },
        "state-cluster_dashboard",
        %{
          current_value: "incident cluster",
          status: "Cluster dashboard switched to the incident response snapshot."
        },
        ["model"],
        ["Regional cluster degraded", "Gateway retries"]
      )
    end
  end

  defp assert_operational_transition(
         directory,
         event_params,
         state_id,
         expected_state,
         hydrated_keys,
         rendered_fragments
       ) do
    module = Phase20.example_module(directory)
    mounted = module.mount_seeded!()

    assert {:reply, %{status: :ok}, updated_socket} =
             EventHandler.handle_action_event(event_params, mounted.socket)

    assert get_in(updated_socket.assigns, [:flash, :info]) == "Action completed successfully"

    state =
      Module.concat([module, Runtime, ExampleState])
      |> Ash.read!(domain: Module.concat([module, RuntimeDomain]), authorize?: false)
      |> Enum.find(&(&1.id == state_id))

    Enum.each(expected_state, fn {field, value} ->
      assert Map.get(state, field) == value
    end)

    remounted_socket =
      module.build_socket(%{
        current_user: mounted.actor,
        ash_ui_storage: module.ui_storage(),
        ash_ui_domains: module.runtime_domains()
      })
      |> then(fn socket ->
        {:ok, socket} = Integration.mount_ui_screen(socket, mounted.screen_name, %{})
        {:ok, socket} = EventHandler.wire_handlers(socket)
        socket
      end)

    subject =
      remounted_socket.assigns.ash_ui_iur
      |> find_iur_by_id("example-#{directory}-subject")

    Enum.each(hydrated_keys, fn key ->
      assert Map.has_key?(subject["props"], key)
    end)

    rendered_ui = module.rendered_ui(remounted_socket.assigns)

    Enum.each(rendered_fragments, fn fragment ->
      assert rendered_ui =~ fragment
    end)
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

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
