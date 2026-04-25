defmodule AshUI.Phase19LayoutNavigationExamplesTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase19}
  alias AshUI.LiveView.EventHandler

  @moduletag :integration
  @moduletag :examples

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase19.definitions_for(:layout_navigation), fn definition ->
      load_example_module!(definition.directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 19.2 - Layout and Navigation Example Apps" do
    test "19.2.1.4 - every layout and navigation app mounts through the shared shell and independent project scaffold" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(Phase19.definitions_for(:layout_navigation), fn definition ->
        module = Phase19.example_module(definition.directory)
        mounted = module.mount_seeded!()
        rendered_ui = module.rendered_ui(mounted.socket.assigns)
        rendered_shell = render_example_live(module, definition.directory, rendered_ui)

        assert mounted.screen_name == Phase19.screen_name(definition.directory)
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{definition.directory}-shell"

        assert rendered_ui =~ expected_subject_fragment(definition.directory)
        assert rendered_shell =~ "ashui-example-shell"
        assert rendered_shell =~ definition.title
        assert rendered_shell =~ definition.story_text

        assert File.exists?(Path.join(Phase19.project_path(definition.directory), "mix.exs"))
        assert File.exists?(Path.join(Phase19.project_path(definition.directory), "README.md"))

        assert File.exists?(
                 Path.join(Phase19.project_path(definition.directory), "assets/css/app.css")
               )
      end)
    end

    test "19.2.1.4 - representative layout apps preserve declared relationship order in the compiled tree and rendered output" do
      assert_layout_order(
        "row",
        ["primary-lane", "inspector-lane", "action-lane"],
        ["Primary lane", "Inspector lane", "Action lane"]
      )

      assert_layout_order(
        "column",
        ["incident-summary", "approval-queue", "handoff-notes"],
        ["Incident summary", "Approval queue", "Handoff notes"]
      )

      assert_layout_order(
        "grid",
        ["queue-tile", "trend-tile", "sla-tile", "handoff-tile"],
        ["Queue tile", "Trend tile", "SLA tile", "Handoff tile"]
      )
    end

    test "19.2.1.3 - navigation examples keep actions and bindings local to nested child resources" do
      menu_module = Phase19.example_module("menu")
      menu_mounted = menu_module.mount_seeded!()

      assert {:reply, %{status: :ok}, menu_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "select_monitoring",
                   "element_id" => "monitoring-button",
                   "signal" => "click"
                 },
                 menu_mounted.socket
               )

      assert get_in(menu_socket.assigns, [:flash, :info]) == "Action completed successfully"
      assert menu_module.rendered_ui(menu_socket.assigns) =~ "monitoring"

      tabs_module = Phase19.example_module("tabs")
      tabs_mounted = tabs_module.mount_seeded!()

      assert {:reply, %{status: :ok}, tabs_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "select_metrics",
                   "element_id" => "metrics-tab-button",
                   "signal" => "click"
                 },
                 tabs_mounted.socket
               )

      assert get_in(tabs_socket.assigns, [:flash, :info]) == "Action completed successfully"
      assert tabs_module.rendered_ui(tabs_socket.assigns) =~ "metrics"

      command_module = Phase19.example_module("command_palette")
      command_mounted = command_module.mount_seeded!()

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{
                   "target" => "query",
                   "value" => "prepare status page",
                   "element_id" => "palette-query-input",
                   "signal" => "change"
                 },
                 command_mounted.socket
               )

      assert {:reply, %{status: :ok}, action_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "run_triage_command",
                   "element_id" => "triage-command-button",
                   "signal" => "click"
                 },
                 changed_socket
               )

      assert get_in(action_socket.assigns, [:flash, :info]) == "Action completed successfully"
      assert command_module.rendered_ui(action_socket.assigns) =~ "prepare status page"

      state =
        Module.concat([command_module, Runtime, ExampleState])
        |> Ash.read!(domain: Module.concat([command_module, RuntimeDomain]), authorize?: false)
        |> Enum.find(&(&1.id == "state-command_palette"))

      assert state.current_value == "prepare status page"
      assert state.submitted_value == "prepare status page"
      assert state.status == "Triage command executed."
    end
  end

  defp assert_layout_order(directory, expected_ids, expected_fragments) do
    module = Phase19.example_module(directory)
    mounted = module.mount_seeded!()
    rendered_ui = module.rendered_ui(mounted.socket.assigns)

    subject =
      mounted.socket.assigns.ash_ui_iur
      |> find_iur_by_id("example-#{directory}-subject")

    assert Enum.map(subject["children"], & &1["id"]) == expected_ids
    assert_fragments_in_order(rendered_ui, expected_fragments)
  end

  defp assert_fragments_in_order(body, fragments) do
    {_last_index, _fragment} =
      Enum.reduce(fragments, {-1, nil}, fn fragment, {last_index, _last_fragment} ->
        assert {index, _length} = :binary.match(body, fragment)
        assert index > last_index
        {index, fragment}
      end)
  end

  defp find_iur_by_id(nil, _id), do: nil

  defp find_iur_by_id(%{"id" => id} = iur, id), do: iur

  defp find_iur_by_id(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_iur_by_id(&1, id))
  end

  defp find_iur_by_id(_iur, _id), do: nil

  defp expected_subject_fragment("row"), do: "ash-row"
  defp expected_subject_fragment("column"), do: "ash-column"
  defp expected_subject_fragment("grid"), do: "ash-grid"
  defp expected_subject_fragment("menu"), do: "ash-menu"
  defp expected_subject_fragment("tabs"), do: "ash-tabs"
  defp expected_subject_fragment("command_palette"), do: "ash-command-palette"

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
    module = Phase19.example_module(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> Phase19.project_path()
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end
end
