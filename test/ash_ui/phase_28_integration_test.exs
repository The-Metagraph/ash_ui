defmodule AshUI.Phase28IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.EventHandler
  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase28

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase28.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase28.chapter_project_path(number), Phase28.chapter_mix_project_module(number))
      load_source_module!(Phase28.chapter_source_path(number), Phase28.chapter_module(number))
    end)

    load_mix_project_module!(Phase28.final_app_project_path(), Phase28.final_app_mix_project_module())
    load_source_module!(Phase28.final_app_source_path(), Phase28.final_app_module())

    :ok
  end

  describe "Section 28.3 - Phase 28 Integration Tests" do
    test "28.3.1.1 - Chapter 12 and the maintained final app boot independently and preserve the shared shell and seed contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Phase28.validate_project_structure()

      checkpoint_module = Phase28.chapter_module(12)
      final_module = Phase28.final_app_module()

      checkpoint_project = project_definition(Phase28.chapter_mix_project_module(12))
      final_project = project_definition(Phase28.final_app_mix_project_module())

      assert checkpoint_project[:app] == :ash_ui_tutorial_production_polish
      assert final_project[:app] == :ash_ui_tutorial_operations_control_center
      assert Keyword.has_key?(checkpoint_project[:aliases], :"example.start")
      assert Keyword.has_key?(final_project[:aliases], :"example.start")
      assert dependency_path!(checkpoint_project[:deps], :ash_ui) == "../../.."
      assert dependency_path!(final_project[:deps], :ash_ui) == "../.."

      Enum.each([checkpoint_module, final_module], fn module ->
        assert apply(module, :default_runtime, []) == "live_ui"
        assert apply(module, :supported_runtimes, []) == ["live_ui", "elm_ui", "desktop_ui"]
      end)

      checkpoint_services = apply(checkpoint_module, :mount_seeded!, [:services])
      checkpoint_incidents = apply(checkpoint_module, :mount_seeded!, [:incidents])
      final_services = apply(final_module, :mount_seeded!, [:services])
      final_incidents = apply(final_module, :mount_seeded!, [:incidents])

      assert checkpoint_services.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "12-production-polish"

      assert checkpoint_incidents.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "12-production-polish"

      assert final_services.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "operations_control_center"

      assert final_incidents.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "operations_control_center"

      assert apply(checkpoint_module, :page_path, ["incidents", apply(checkpoint_module, :actor_profile_value, ["viewer"]), "elm_ui"]) ==
               "/incidents?actor=viewer-ren&runtime=elm_ui"

      assert apply(final_module, :runtime_path, ["services", apply(final_module, :actor_profile_value, ["admin"]), "desktop_ui"]) ==
               "/?actor=admin-jules&runtime=desktop_ui"
    end

    test "28.3.1.2 - the maintained final app stays aligned with the Chapter 12 checkpoint within the documented differences" do
      assert :ok = Phase28.validate_authoritative_resource_sources()
      assert :ok = Phase28.validate_final_app_documentation()

      checkpoint_module = Phase28.chapter_module(12)
      final_module = Phase28.final_app_module()

      apply(checkpoint_module, :seed!, [])
      apply(final_module, :seed!, [])

      assert File.read!(Phase28.chapter_stylesheet_path(12)) ==
               File.read!(Phase28.final_app_stylesheet_path())

      assert normalized_composition_modules(checkpoint_module, :services) ==
               normalized_composition_modules(final_module, :services)

      assert normalized_composition_modules(checkpoint_module, :incidents) ==
               normalized_composition_modules(final_module, :incidents)

      assert aligned_state_after_message(checkpoint_module, final_module, :services, "Services loading state previewed")
      assert aligned_state_after_message(checkpoint_module, final_module, :services, "Services empty state previewed")
      assert aligned_state_after_message(checkpoint_module, final_module, :services, "Services support issue previewed")
      assert aligned_state_after_message(checkpoint_module, final_module, :incidents, "Incidents loading state previewed")
      assert aligned_state_after_message(checkpoint_module, final_module, :incidents, "Incidents empty state previewed")
      assert aligned_state_after_message(checkpoint_module, final_module, :incidents, "Incidents support issue previewed")
    end

    test "28.3.1.3 - the polished shell keeps responsive and explicit support-state markers on both chapter and final surfaces" do
      assert :ok = Phase28.validate_responsive_stylesheets()

      checkpoint_source = File.read!(Phase28.chapter_source_path(12))
      final_source = File.read!(Phase28.final_app_source_path())

      assert checkpoint_source =~ "ashui-tutorial-skip-link"
      assert checkpoint_source =~ "Runtime preview selection"
      assert final_source =~ "ashui-tutorial-skip-link"
      assert final_source =~ "Runtime preview selection"

      Enum.each([Phase28.chapter_stylesheet_path(12), Phase28.final_app_stylesheet_path()], fn stylesheet_path ->
        body = File.read!(stylesheet_path)
        assert body =~ "width: 100%;"
        assert body =~ ".ashui-tutorial-runtime-link,"
      end)

      checkpoint_module = Phase28.chapter_module(12)

      loading_state =
        checkpoint_module
        |> trigger_message(:services, "Services loading state previewed")
        |> then(fn _socket -> state!(checkpoint_module) end)

      assert loading_state.review_status_model["label"] == "Refreshing seeded review"
      assert loading_state.review_feedback_model["title"] == "Loading state is explicit"
      assert loading_state.experience_mode == "loading"
      assert loading_state.services == []

      empty_state =
        checkpoint_module
        |> trigger_message(:services, "Services empty state previewed")
        |> then(fn _socket -> state!(checkpoint_module) end)

      assert empty_state.review_status_model["label"] == "Empty state in review"
      assert empty_state.detail_title == "No matching services"
      assert empty_state.services == []

      error_state =
        checkpoint_module
        |> trigger_message(:incidents, "Incidents support issue previewed")
        |> then(fn _socket -> state!(checkpoint_module) end)

      assert error_state.review_status_model["label"] == "Support issue surfaced"
      assert error_state.review_feedback_model["title"] == "Error state stays honest"
      assert error_state.experience_mode == "error"
    end

    test "28.3.1.4 - Chapter 12 and the final app README reference the checkpoint and maintained-app paths clearly" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase28.validate_implemented_chapter_artifacts()

      chapter_body =
        12
        |> Tutorials.chapter!()
        |> Map.fetch!("chapter_path")
        |> Path.expand(repo_root())
        |> File.read!()

      assert chapter_body =~ "../code/12-production-polish/"
      assert chapter_body =~ "../code/11-roles-and-policies/"
      assert chapter_body =~ "../operations_control_center/"

      final_readme = File.read!(Path.join(Phase28.final_app_project_path(), "README.md"))
      assert final_readme =~ "../code/12-production-polish/"

      Enum.each(Phase28.documented_final_app_differences(), fn marker ->
        assert final_readme =~ marker
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

  defp normalized_composition_modules(module, screen_kind) do
    persisted_screens(module)
    |> Enum.find(&(&1.name == apply(module, :screen_name, [screen_kind])))
    |> then(&composition_modules(&1.unified_dsl))
    |> Enum.map(fn module_name ->
      Regex.replace(~r/^Elixir\.AshUITutorials\.(ProductionPolish|OperationsControlCenter)\.Examples\./, module_name, "")
      |> String.replace("OperationsControlCenter", "ProductionPolish")
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
      |> Map.get("success_message")
      |> Kernel.==(success_message)
    end) || raise "missing action binding with success message #{inspect(success_message)}"
  end

  defp binding_id(binding) do
    Map.get(binding, :id) || Map.get(binding, "id") || raise "binding missing id"
  end

  defp binding_metadata(binding) do
    Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{}
  end

  defp aligned_state_after_message(checkpoint_module, final_module, screen_kind, success_message) do
    checkpoint_state =
      checkpoint_module
      |> trigger_message(screen_kind, success_message)
      |> then(fn _socket -> state!(checkpoint_module) end)
      |> comparable_state()

    final_state =
      final_module
      |> trigger_message(screen_kind, success_message)
      |> then(fn _socket -> state!(final_module) end)
      |> comparable_state()

    checkpoint_state == final_state
  end

  defp trigger_message(module, screen_kind, success_message) do
    mounted = apply(module, :mount_seeded!, [screen_kind])
    binding = action_binding_by_message!(mounted.socket, success_message)

    assert {:reply, %{status: :ok}, socket} =
             EventHandler.handle_action_event(
               %{
                 "action_id" => binding_id(binding),
                 "element_id" => BindingRuntime.owner_element_id(binding),
                 "signal" => "click"
               },
               mounted.socket
             )

    socket
  end

  defp comparable_state(state) do
    %{
      experience_mode: state.experience_mode,
      detail_title: state.detail_title,
      detail_status: state.detail_status,
      status: state.status,
      review_status_label: state.review_status_model["label"],
      review_feedback_title: state.review_feedback_model["title"],
      services_count: length(state.services),
      incidents_count: length(state.incidents)
    }
  end

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
