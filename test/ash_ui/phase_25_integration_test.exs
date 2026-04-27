defmodule AshUI.Phase25IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.EventHandler
  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase25

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase25.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase25.chapter_project_path(number), Phase25.chapter_mix_project_module(number))
      load_source_module!(Phase25.chapter_source_path(number), Phase25.chapter_module(number))
    end)

    :ok
  end

  describe "Section 25.3 - Phase 25 Integration Tests" do
    test "25.3.1.1 - Chapters 6 and 7 boot as independent Mix projects and preserve the shared shell contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Phase25.validate_project_structure()

      expected_apps = %{
        6 => :ash_ui_tutorial_runbooks_and_attachments,
        7 => :ash_ui_tutorial_live_diagnostics
      }

      Enum.each(Phase25.implemented_checkpoint_numbers(), fn number ->
        chapter = Tutorials.chapter!(number)
        code_directory = Path.basename(chapter["code_path"])
        mix_module = Phase25.chapter_mix_project_module(number)
        project = project_definition(mix_module)
        module = Phase25.chapter_module(number)

        assert project[:app] == Map.fetch!(expected_apps, number)
        assert Keyword.has_key?(project[:aliases], :"example.start")
        assert dependency_path!(project[:deps], :ash_ui) == "../../.."
        assert apply(module, :default_runtime, []) == "live_ui"
        assert apply(module, :supported_runtimes, []) == ["live_ui", "elm_ui", "desktop_ui"]

        mounted_services = apply(module, :mount_seeded!, [:services])
        mounted_incidents = apply(module, :mount_seeded!, [:incidents])

        assert mounted_services.socket.assigns.ash_ui_screen.name ==
                 apply(module, :screen_name, [:services])

        assert mounted_incidents.socket.assigns.ash_ui_screen.name ==
                 apply(module, :screen_name, [:incidents])

        assert mounted_services.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
                 code_directory

        assert mounted_incidents.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
                 code_directory
      end)
    end

    test "25.3.1.2 - runbook, attachment, and detail surfaces remain resource-authored and update shared checkpoint state" do
      module = Phase25.chapter_module(6)
      mounted = module.mount_seeded!(:incidents)

      assert :ok = Phase25.validate_authoritative_resource_sources()
      assert Enum.all?(persisted_screens(module), &authoritative_screen_graph?/1)

      incident_screen =
        persisted_screens(module)
        |> Enum.find(&(&1.name == apply(module, :screen_name, [:incidents])))

      modules = composition_modules(incident_screen.unified_dsl)
      assert "Elixir.AshUITutorials.RunbooksAndAttachments.Examples.RunbookReviewPanelElement" in modules
      assert "Elixir.AshUITutorials.RunbooksAndAttachments.Examples.RunbookMarkdownViewerElement" in modules
      assert "Elixir.AshUITutorials.RunbooksAndAttachments.Examples.AttachmentFileInputElement" in modules

      rollback_binding = action_binding_by_message!(mounted.socket, "Rollback packet loaded")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(rollback_binding),
                   "element_id" => BindingRuntime.owner_element_id(rollback_binding),
                   "signal" => "click"
                 },
                 mounted.socket
               )

      state = state!(module)
      assert state.runbook_focus == "Rollback decision packet"
      assert state.attachment_filename == "rollback-decision-packet.md"
      assert state.attachment_support_notice =~ "binary upload transport"
      assert state.detail_status == "rollback-ready"
    end

    test "25.3.1.3 - live diagnostics stay explicit about seeded transport, stale data, and pressure scenarios" do
      module = Phase25.chapter_module(7)
      mounted = module.mount_seeded!(:incidents)

      initial_state = state!(module)
      assert initial_state.diagnostics_feedback_model["title"] == "Transport note"
      assert initial_state.diagnostics_status_copy =~ "seeded snapshots"

      stale_binding = action_binding_by_message!(mounted.socket, "Search diagnostics loaded")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(stale_binding),
                   "element_id" => BindingRuntime.owner_element_id(stale_binding),
                   "signal" => "click"
                 },
                 mounted.socket
               )

      stale_state = state!(module)
      assert stale_state.diagnostics_status_model["label"] == "Snapshot stale"
      assert stale_state.diagnostics_feedback_model["title"] == "Stale review window"
      assert stale_state.diagnostics_status_copy =~ "snapshot-only"

      pressure_binding = action_binding_by_message!(socket, "Pressure diagnostics loaded")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(pressure_binding),
                   "element_id" => BindingRuntime.owner_element_id(pressure_binding),
                   "signal" => "click"
                 },
                 socket
               )

      pressure_state = state!(module)
      assert pressure_state.diagnostics_status_model["tone"] == "danger"
      assert pressure_state.diagnostics_feedback_model["title"] == "Action recommended"
      assert pressure_state.diagnostics_process_model["summary"] =~ "direct supervisor tap"
      assert pressure_state.status =~ "Retry-pressure diagnostics loaded"
    end

    test "25.3.1.4 - Chapters 6 and 7 reference the correct checkpoint directories and supporting modules in prose" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase25.validate_implemented_chapter_artifacts()

      expected_pairs = %{
        6 => {"../code/06-runbooks-and-attachments/", "../code/05-safe-overlays-and-guards/"},
        7 => {"../code/07-live-diagnostics/", "../code/06-runbooks-and-attachments/"}
      }

      Enum.each(expected_pairs, fn {number, {checkpoint_path, previous_path}} ->
        body =
          number
          |> Tutorials.chapter!()
          |> Map.fetch!("chapter_path")
          |> Path.expand(repo_root())
          |> File.read!()

        assert body =~ checkpoint_path
        assert body =~ previous_path
      end)
    end
  end

  defp load_mix_project_module!(project_root, module) do
    if Code.ensure_loaded?(module) do
      module
    else
      capture_io(:stderr, fn ->
        project_root
        |> Path.join("mix.exs")
        |> Code.require_file()
      end)

      module
    end
  end

  defp load_source_module!(source_path, module) do
    if Code.ensure_loaded?(module) do
      module
    else
      capture_io(:stderr, fn -> Code.require_file(source_path) end)
      module
    end
  end

  defp dependency_path!(deps, dependency_name) do
    deps
    |> Enum.find_value(fn
      {^dependency_name, options} when is_list(options) -> Keyword.get(options, :path)
      _other -> nil
    end)
  end

  defp project_definition(module) do
    apply(module, :project, [])
  end

  defp persisted_screens(module) do
    resource = Module.concat(module, UiScreen)
    domain = Module.concat(module, UiStorageDomain)
    Ash.read!(resource, domain: domain, authorize?: false)
  end

  defp authoritative_screen_graph?(screen) do
    roots = get_in(screen.unified_dsl, ["composition", "roots"]) || []

    roots != [] and
      Enum.all?(roots, fn root ->
        is_binary(root["module"]) and String.contains?(root["module"], "Examples.")
      end)
  end

  defp composition_modules(iur) do
    iur
    |> get_in(["composition", "roots"])
    |> List.wrap()
    |> Enum.flat_map(&composition_modules_from_root/1)
  end

  defp composition_modules_from_root(%{"module" => module, "children" => children}) do
    [module | Enum.flat_map(List.wrap(children), &composition_modules_from_root/1)]
  end

  defp composition_modules_from_root(%{"module" => module}) do
    [module]
  end

  defp composition_modules_from_root(_other), do: []

  defp state!(module) do
    resource = Module.concat([module, Runtime, WorkspaceState])
    domain = Module.concat([module, RuntimeDomain])

    resource
    |> Ash.read!(domain: domain, authorize?: false)
    |> Enum.find(&(&1.id == "tutorial-services-incidents-state"))
  end

  defp action_binding_by_message!(socket, success_message) do
    socket.assigns.ash_ui_action_bindings
    |> Map.values()
    |> Enum.find(fn binding ->
      binding
      |> binding_metadata()
      |> Map.get("success_message", Map.get(binding_metadata(binding), :success_message))
      |> Kernel.==(success_message)
    end)
  end

  defp binding_id(binding) do
    Map.get(binding, :id) || Map.get(binding, "id")
  end

  defp binding_metadata(binding) do
    Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{}
  end

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
