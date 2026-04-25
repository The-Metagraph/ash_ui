defmodule AshUI.Phase20DataSurfaceExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase20}
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase20.definitions_for(:data_surfaces), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 20.2 - Data-Surface Example Apps" do
    test "20.2.1.4 - every data-surface app mounts through the shared shell and keeps the primary collection or document surface visible" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase20.definitions_for(:data_surfaces), fn definition ->
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

        assert File.exists?(
                 Path.join(Phase20.project_path(definition.directory), "assets/css/app.css")
               )
      end)
    end

    test "20.2.1.4 - representative data surfaces refresh correctly when bound data changes" do
      assert_data_transition(
        "list",
        %{
          "action_id" => "action_load_handoff_queue_button",
          "element_id" => "load-handoff-queue-button",
          "signal" => "click"
        },
        "state-list",
        %{current_value: "handoff queue", status: "List binding switched to the handoff queue."},
        ["items"],
        ["Shift summary packet", "List binding switched to the handoff queue."]
      )

      assert_data_transition(
        "table",
        %{
          "action_id" => "action_load_handoff_board_button",
          "element_id" => "load-handoff-board-button",
          "signal" => "click"
        },
        "state-table",
        %{
          current_value: "handoff board",
          status: "Table binding switched to the handoff board dataset."
        },
        ["items"],
        ["Ops notes", "Table binding switched to the handoff board dataset."]
      )

      assert_data_transition(
        "tree_view",
        %{
          "action_id" => "action_load_rollout_tree_button",
          "element_id" => "load-rollout-tree-button",
          "signal" => "click"
        },
        "state-tree_view",
        %{
          selected_value: "rollout graph",
          status: "Tree viewer switched to the rollout hierarchy."
        },
        ["model"],
        ["Rollout graph", "Tree viewer switched to the rollout hierarchy."]
      )

      assert_data_transition(
        "markdown_viewer",
        %{
          "action_id" => "action_load_release_notes_button",
          "element_id" => "load-release-notes-button",
          "signal" => "click"
        },
        "state-markdown_viewer",
        %{
          current_value: "release notes",
          status: "Markdown viewer switched to the release notes."
        },
        ["content"],
        ["Release Notes", "Markdown viewer switched to the release notes."]
      )

      assert_data_transition(
        "log_viewer",
        %{
          "action_id" => "action_load_deploy_stream_button",
          "element_id" => "load-deploy-stream-button",
          "signal" => "click"
        },
        "state-log_viewer",
        %{current_value: "deploy stream", status: "Log viewer switched to the deploy stream."},
        ["entries"],
        [
          "Canary deployment reached 25% of target traffic.",
          "Log viewer switched to the deploy stream."
        ]
      )
    end
  end

  defp assert_data_transition(
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

  defp expected_subject_fragment("list"), do: "ash-list"
  defp expected_subject_fragment("table"), do: "ash-table-surface"
  defp expected_subject_fragment("tree_view"), do: "ash-tree-view"
  defp expected_subject_fragment("markdown_viewer"), do: "ash-markdown-viewer"
  defp expected_subject_fragment("log_viewer"), do: "ash-log-viewer"

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
