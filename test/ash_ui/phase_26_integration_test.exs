defmodule AshUI.Phase26IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.EventHandler
  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase26

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase26.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase26.chapter_project_path(number), Phase26.chapter_mix_project_module(number))
      load_source_module!(Phase26.chapter_source_path(number), Phase26.chapter_module(number))
    end)

    :ok
  end

  describe "Section 26.3 - Phase 26 Integration Tests" do
    test "26.3.1.1 - Chapters 8 and 9 boot as independent Mix projects and preserve the shared shell contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Phase26.validate_project_structure()

      expected_apps = %{
        8 => :ash_ui_tutorial_topology_and_navigation,
        9 => :ash_ui_tutorial_metrics_and_capacity
      }

      Enum.each(Phase26.implemented_checkpoint_numbers(), fn number ->
        chapter = Tutorials.chapter!(number)
        code_directory = Path.basename(chapter["code_path"])
        mix_module = Phase26.chapter_mix_project_module(number)
        project = project_definition(mix_module)
        module = Phase26.chapter_module(number)

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

    test "26.3.1.2 - topology review stays resource-authored and the checkpoint stylesheets keep the split review usable on smaller layouts" do
      assert :ok = Phase26.validate_authoritative_resource_sources()
      assert :ok = Phase26.validate_responsive_stylesheets()

      Enum.each(Phase26.implemented_checkpoint_numbers(), fn number ->
        module = Phase26.chapter_module(number)
        apply(module, :seed!, [])

        service_screen =
          persisted_screens(module)
          |> Enum.find(&(&1.name == apply(module, :screen_name, [:services])))

        modules = composition_modules(service_screen.unified_dsl)

        assert Enum.all?(persisted_screens(module), &authoritative_screen_graph?/1)
        assert Enum.any?(modules, &String.ends_with?(&1, "Examples.TopologyReviewPanelElement"))
      end)

      chapter9_modules =
        Phase26.chapter_module(9)
        |> then(fn module ->
          apply(module, :seed!, [])
          module
        end)
        |> persisted_screens()
        |> Enum.find(&(&1.name == apply(Phase26.chapter_module(9), :screen_name, [:services])))
        |> then(&composition_modules(&1.unified_dsl))

      assert Enum.any?(chapter9_modules, &String.ends_with?(&1, "Examples.MetricsReviewPanelElement"))
    end

    test "26.3.1.3 - metrics dashboards and chart surfaces stay synchronized with the seeded operational story they claim to represent" do
      module = Phase26.chapter_module(9)
      mounted = module.mount_seeded!(:services)

      initial_state = state!(module)
      assert initial_state.metrics_focus == "gateway saturation"
      assert initial_state.metrics_dashboard_model["headline"] == "Core East gateway elevated"
      assert initial_state.metrics_support_notice =~ "tutorial-shaped"
      assert initial_state.gauge_metric["value"] == 82

      search_binding = action_binding_by_message!(mounted.socket, "Search metrics snapshot loaded")

      assert {:reply, %{status: :ok}, socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(search_binding),
                   "element_id" => BindingRuntime.owner_element_id(search_binding),
                   "signal" => "click"
                 },
                 mounted.socket
               )

      search_state = state!(module)
      assert search_state.metrics_focus == "search recovery"
      assert search_state.detail_title == "Search recovery"
      assert search_state.metrics_dashboard_model["headline"] == "Search recovery in progress"
      assert search_state.sparkline_series |> List.last() |> Map.fetch!("value") == 14
      assert search_state.metrics_support_notice =~ "sampled snapshots"

      fleet_binding = action_binding_by_message!(socket, "Fleet metrics snapshot loaded")

      assert {:reply, %{status: :ok}, _socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => binding_id(fleet_binding),
                   "element_id" => BindingRuntime.owner_element_id(fleet_binding),
                   "signal" => "click"
                 },
                 socket
               )

      fleet_state = state!(module)
      assert fleet_state.metrics_focus == "fleet capacity"
      assert fleet_state.detail_title == "Fleet capacity"
      assert fleet_state.gauge_metric["value"] == 71

      region_labels =
        fleet_state.metrics_dashboard_model["regions"]
        |> Enum.map(&Map.fetch!(&1, "label"))

      bar_labels = Enum.map(fleet_state.bar_chart_series, &Map.fetch!(&1, "label"))

      assert region_labels == bar_labels
      assert fleet_state.metrics_status_copy =~ "regional load mix"
    end

    test "26.3.1.4 - Chapters 8 and 9 reference the correct checkpoint directories and supporting modules in prose" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase26.validate_implemented_chapter_artifacts()

      expected_pairs = %{
        8 => {"../code/08-topology-and-navigation/", "../code/07-live-diagnostics/"},
        9 => {"../code/09-metrics-and-capacity/", "../code/08-topology-and-navigation/"}
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
