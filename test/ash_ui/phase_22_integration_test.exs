defmodule AshUI.Phase22IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Examples.{Contract, Phase18, Phase19, Phase20, Suite}

  @catalog_path "specs/conformance/scenario_catalog.md"
  @traceability_path "specs/conformance/scenario_test_matrix.md"

  @representative_examples [
    %{family: "content", directory: "button", subject_fragment: "ashui-example-primary-cta"},
    %{family: "forms", directory: "form_builder", subject_fragment: "ashui-example-form"},
    %{family: "input", directory: "text_input", subject_fragment: "ashui-example-input"},
    %{family: "layout", directory: "grid", subject_fragment: "ashui-example-grid-layout"},
    %{family: "navigation", directory: "tabs", subject_fragment: "ashui-example-tabs-shell"},
    %{family: "display", directory: "viewport", subject_fragment: "ashui-example-viewport-shell"},
    %{family: "overlay", directory: "dialog", subject_fragment: "ashui-example-dialog-shell"},
    %{family: "data", directory: "list", subject_fragment: "ashui-example-list-surface"},
    %{family: "feedback", directory: "status", subject_fragment: "ashui-example-status-shell"},
    %{
      family: "operational",
      directory: "cluster_dashboard",
      subject_fragment: "ashui-example-cluster-dashboard-shell"
    }
  ]

  @moduletag :integration
  @moduletag :examples
  @moduletag :conformance

  setup_all do
    {:ok, _} = Application.ensure_all_started(:ash_ui)

    Enum.each(@representative_examples, fn %{directory: directory} ->
      load_example_module!(directory)
    end)

    :ok
  end

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    :ok
  end

  describe "Section 22.4 - Phase 22 Integration Tests" do
    test "22.4.1.1 - representative apps from every major family boot independently and mount seeded screens" do
      actual_families =
        Suite.catalog_entries()
        |> Enum.map(& &1.family)
        |> Enum.uniq()
        |> Enum.sort()

      assert Enum.sort(Enum.map(@representative_examples, & &1.family)) == actual_families

      Enum.each(@representative_examples, fn %{family: family, directory: directory} ->
        module = example_module!(directory)
        mounted = module.mount_seeded!()

        assert Suite.entry!(directory).family == family
        assert File.exists?(Path.join(Suite.project_path(directory), "mix.exs"))
        assert File.exists?(Path.join(Suite.project_path(directory), "README.md"))
        assert File.exists?(Path.join(Suite.project_path(directory), "config/config.exs"))
        assert File.exists?(Path.join(Suite.project_path(directory), "assets/css/app.css"))

        assert mounted.screen_name == screen_name(directory)
        assert mounted.screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.name == mounted.screen_name
        assert mounted.socket.assigns.ash_ui_screen.route == "/"

        assert mounted.socket.assigns.ash_ui_screen.metadata["shell_id"] ==
                 "example-#{directory}-shell"
      end)
    end

    test "22.4.1.2 - representative apps keep the shared Ash HQ shell while foregrounding their primary subject and story" do
      assert :ok = Contract.validate_theme_baseline()

      Enum.each(@representative_examples, fn %{directory: directory, subject_fragment: fragment} ->
        module = example_module!(directory)
        definition = Suite.definition!(directory)
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
        assert rendered_ui =~ fragment
      end)
    end

    test "22.4.1.3 - the machine-readable catalog, root index, and directory tree stay synchronized across the full suite" do
      assert :ok = Suite.validate_suite()
      assert :ok = Suite.validate_directory_tree_alignment()
      assert :ok = Suite.validate_catalog_projects()
      assert :ok = Suite.validate_catalog_metadata_snapshot()
      assert :ok = Suite.validate_readme_index()
      assert :ok = Suite.validate_review_metadata_alignment()

      actual_directories =
        Suite.examples_root()
        |> File.ls!()
        |> Enum.filter(&File.dir?(Path.join(Suite.examples_root(), &1)))
        |> Enum.sort()

      assert actual_directories == Enum.sort(Suite.directories())
    end

    test "22.4.1.4 - release and governance workflows fail clearly when examples, docs, theme baselines, or traceability drift apart" do
      assert :ok =
               validate_example_suite_traceability(
                 File.read!(@catalog_path),
                 File.read!(@traceability_path)
               )

      entry = Suite.entry!("button")
      temp_root = temp_dir!("suite_drift")
      copy_example!("button", temp_root)
      File.mkdir_p!(Path.join(temp_root, "stale_example"))

      assert {:error, {:example_directory_drift, directory_drift}} =
               Suite.validate_directory_tree_alignment(entries: [entry], examples_root: temp_root)

      assert directory_drift.extra == ["stale_example"]

      broken_readme = Path.join(temp_root, "README.md")

      File.write!(
        broken_readme,
        String.replace(
          File.read!(Suite.readme_path()),
          "Button Example",
          "Drifted Button Example",
          global: false
        )
      )

      assert {:error, {:readme_index_drift, _}} = Suite.validate_readme_index(broken_readme)

      broken_doc = Path.join(temp_root, "ash_hq_theme_baseline.md")
      broken_css = Path.join(temp_root, "ash_hq_theme_tokens.css")

      File.write!(broken_doc, "# Broken Theme\n")
      File.write!(broken_css, ":root { --ashui-example-bg-base: #020617; }\n")

      assert {:error, {:theme_drift, theme_drift}} =
               Contract.validate_theme_baseline(broken_doc, broken_css)

      assert ".ashui-example-shell" in theme_drift.missing_css_classes

      drifted_traceability =
        File.read!(@traceability_path)
        |> String.replace(", test/ash_ui/phase_20_integration_test.exs", "", global: false)

      assert {:error, {:traceability_drift, traceability_drift}} =
               validate_example_suite_traceability(
                 File.read!(@catalog_path),
                 drifted_traceability
               )

      assert traceability_drift.missing_catalog_scenarios == []

      assert traceability_drift.missing_traceability_files["SCN-052"] == [
               "test/ash_ui/phase_20_integration_test.exs"
             ]
    end
  end

  defp example_module!(directory) do
    phase_module(directory).example_module(directory)
  end

  defp screen_name(directory) do
    phase_module(directory).screen_name(directory)
  end

  defp phase_module(directory) do
    case Suite.entry!(directory).phase do
      18 -> Phase18
      19 -> Phase19
      20 -> Phase20
    end
  end

  defp load_example_module!(directory) do
    module = example_module!(directory)

    if Code.ensure_loaded?(module) do
      module
    else
      directory
      |> phase_module()
      |> then(& &1.project_path(directory))
      |> Path.join("lib/ash_ui_examples/#{directory}.ex")
      |> Code.require_file()

      module
    end
  end

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

  defp temp_dir!(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "ash_ui_phase22_integration_#{suffix}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end

  defp copy_example!(directory, temp_root) do
    File.cp_r!(Suite.project_path(directory), Path.join(temp_root, directory))
  end

  defp validate_example_suite_traceability(catalog_body, traceability_body) do
    suite_phase_files =
      Suite.catalog_entries()
      |> Enum.map(& &1.phase)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(&"test/ash_ui/phase_#{&1}_integration_test.exs")

    required_scenarios = %{
      "SCN-052" => suite_phase_files ++ ["test/ash_ui/phase_22_integration_test.exs"],
      "SCN-054" =>
        ["test/ash_ui/phase_17_integration_test.exs"] ++
          suite_phase_files ++ ["test/ash_ui/phase_22_integration_test.exs"],
      "SCN-055" => [
        "test/ash_ui/phase_22_governance_test.exs",
        "test/ash_ui/phase_22_integration_test.exs"
      ]
    }

    missing_catalog_scenarios =
      required_scenarios
      |> Map.keys()
      |> Enum.reject(&String.contains?(catalog_body, "#### #{&1}:"))

    missing_traceability_files =
      Enum.reduce(required_scenarios, %{}, fn {scenario, files}, acc ->
        row = traceability_row(traceability_body, scenario)

        missing =
          case row do
            nil -> files
            row -> Enum.reject(files, &String.contains?(row, &1))
          end

        if missing == [] do
          acc
        else
          Map.put(acc, scenario, missing)
        end
      end)

    if missing_catalog_scenarios == [] and missing_traceability_files == %{} do
      :ok
    else
      {:error,
       {:traceability_drift,
        %{
          missing_catalog_scenarios: missing_catalog_scenarios,
          missing_traceability_files: missing_traceability_files
        }}}
    end
  end

  defp traceability_row(body, scenario) do
    case Regex.run(~r/^\|\s*#{scenario}\s*\|.*$/m, body) do
      [row] -> row
      _ -> nil
    end
  end
end
