defmodule AshUI.Phase23IntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger

  alias AshUI.Tutorials
  alias AshUI.Tutorials.Phase23

  @moduletag :integration
  @moduletag :tutorials

  setup_all do
    previous_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(Phase23.implemented_checkpoint_numbers(), fn number ->
      load_mix_project_module!(Phase23.chapter_project_path(number), Phase23.chapter_mix_project_module(number))
      load_source_module!(Phase23.chapter_source_path(number), Phase23.chapter_module(number))
    end)

    load_mix_project_module!(Phase23.final_app_path(), Phase23.final_mix_project_module())
    load_source_module!(Phase23.final_app_source_path(), Phase23.final_app_module())

    :ok
  end

  describe "Section 23.4 - Phase 23 Integration Tests" do
    test "23.4.1.1 - tutorial directories, chapters, final app, and checkpoint projects follow the documented contract" do
      assert :ok = Tutorials.validate_directory_contract()
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase23.validate_baseline_doc()
      assert :ok = Phase23.validate_project_structure()

      Enum.each(Phase23.implemented_checkpoint_numbers(), fn number ->
        chapter = Tutorials.chapter!(number)
        checkpoint_root = Phase23.chapter_project_path(number)

        assert File.exists?(Path.expand(chapter["chapter_path"], repo_root()))
        assert File.dir?(checkpoint_root)
      end)

      assert File.dir?(Phase23.final_app_path())
    end

    test "23.4.1.2 - Chapters 1 and 2 boot as independent Mix projects and mount seeded screens successfully" do
      chapter1_mix = Phase23.chapter_mix_project_module(1)
      chapter2_mix = Phase23.chapter_mix_project_module(2)
      chapter1 = Phase23.chapter_module(1)
      chapter2 = Phase23.chapter_module(2)
      chapter1_project = project_definition(chapter1_mix)
      chapter2_project = project_definition(chapter2_mix)

      assert chapter1_project[:app] == :ash_ui_tutorial_project_shell
      assert chapter2_project[:app] == :ash_ui_tutorial_services_and_incidents
      assert Keyword.has_key?(chapter1_project[:aliases], :"example.start")
      assert Keyword.has_key?(chapter2_project[:aliases], :"example.start")
      assert dependency_path!(chapter1_project[:deps], :ash_ui) == "../../.."
      assert dependency_path!(chapter2_project[:deps], :ash_ui) == "../../.."

      mounted_home = apply(chapter1, :mount_seeded!, [])
      mounted_services = apply(chapter2, :mount_seeded!, [:services])
      mounted_incidents = apply(chapter2, :mount_seeded!, [:incidents])

      assert apply(chapter1, :default_runtime, []) == "live_ui"
      assert apply(chapter2, :default_runtime, []) == "live_ui"
      assert apply(chapter1, :supported_runtimes, []) == ["live_ui", "elm_ui", "desktop_ui"]
      assert apply(chapter2, :supported_runtimes, []) == ["live_ui", "elm_ui", "desktop_ui"]

      assert mounted_home.screen_name == apply(chapter1, :screen_name, [])
      assert mounted_home.screen.name == mounted_home.screen_name
      assert mounted_home.socket.assigns.ash_ui_screen.name == mounted_home.screen_name
      assert mounted_home.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
               "tutorial-project-shell-shell"

      assert mounted_services.socket.assigns.ash_ui_screen.name ==
               apply(chapter2, :screen_name, [:services])

      assert mounted_services.services_screen.name == apply(chapter2, :screen_name, [:services])
      assert mounted_services.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "02-services-and-incidents"

      assert mounted_incidents.socket.assigns.ash_ui_screen.name ==
               apply(chapter2, :screen_name, [:incidents])

      assert mounted_incidents.incidents_screen.name ==
               apply(chapter2, :screen_name, [:incidents])

      assert mounted_incidents.socket.assigns.ash_ui_screen.metadata["tutorial_directory"] ==
               "02-services-and-incidents"
    end

    test "23.4.1.3 - the Chapter 2 checkpoint and maintained final app compile from authoritative screens and persisted elements" do
      final_mix = Phase23.final_mix_project_module()
      chapter2 = Phase23.chapter_module(2)
      final_app = Phase23.final_app_module()
      final_project = project_definition(final_mix)

      assert final_project[:app] == :ash_ui_tutorial_operations_control_center
      assert Keyword.has_key?(final_project[:aliases], :"example.start")
      assert dependency_path!(final_project[:deps], :ash_ui) == "../.."
      assert :ok = Phase23.validate_authoritative_resource_sources()

      chapter2_seeded = apply(chapter2, :seed!, [])
      final_seeded = apply(final_app, :seed!, [])

      assert Enum.sort(Enum.map(persisted_screens(chapter2), & &1.name)) == [
               apply(chapter2, :screen_name, [:incidents]),
               apply(chapter2, :screen_name, [:services])
             ]

      assert Enum.sort(Enum.map(persisted_screens(final_app), & &1.name)) == [
               apply(final_app, :screen_name, [:incidents]),
               apply(final_app, :screen_name, [:services])
             ]

      assert Enum.all?(persisted_screens(chapter2), &authoritative_screen_graph?/1)
      assert Enum.all?(persisted_screens(final_app), &authoritative_screen_graph?/1)

      assert chapter2_seeded.services_screen.name == apply(chapter2, :screen_name, [:services])
      assert chapter2_seeded.incidents_screen.name == apply(chapter2, :screen_name, [:incidents])
      assert final_seeded.services_screen.name == apply(final_app, :screen_name, [:services])
      assert final_seeded.incidents_screen.name == apply(final_app, :screen_name, [:incidents])

      assert apply(final_app, :mount_seeded!, [:services]).socket.assigns.ash_ui_screen.metadata[
               "tutorial_directory"
             ] == "operations_control_center"

      assert apply(final_app, :mount_seeded!, [:incidents]).socket.assigns.ash_ui_screen.metadata[
               "tutorial_directory"
             ] == "operations_control_center"
    end

    test "23.4.1.4 - Chapters 1 and 2 reference their checkpoint directories, supporting examples, and exact code artifacts explicitly" do
      assert :ok = Tutorials.validate_chapter_reference_contract()
      assert :ok = Phase23.validate_implemented_chapter_artifacts()

      assert File.read!(Path.expand(Tutorials.chapter!(1)["chapter_path"], repo_root())) =~
               "../code/01-project-shell/"

      assert File.read!(Path.expand(Tutorials.chapter!(2)["chapter_path"], repo_root())) =~
               "../code/02-services-and-incidents/"
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

  defp repo_root do
    Path.expand("../..", __DIR__)
  end
end
