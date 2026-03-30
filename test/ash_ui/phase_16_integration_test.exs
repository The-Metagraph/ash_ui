defmodule AshUI.Phase16IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Rendering.IURAdapter
  alias BasicDashboard.Data

  @moduletag :integration
  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()
    Data.seed!()

    :ok
  end

  test "16.4.1.1 - flagship example compiles from screen and element resources" do
    screen = BasicDashboard.seed!()
    graph = BasicDashboard.authority_graph!()

    assert get_in(screen.unified_dsl, ["screen", "module"]) == "Elixir.BasicDashboard.Screen"
    assert graph.screen.id == screen.id
    assert Enum.any?(graph.elements, &(&1["module"] == "Elixir.BasicDashboard.HeroElement"))

    assert Enum.any?(graph.elements, fn element ->
             element["module"] == "Elixir.BasicDashboard.SaveProfileButtonElement"
           end)

    assert Enum.any?(graph.bindings, &(Map.get(&1, "id") == "display_name_input"))

    assert {:ok, iur} =
             Compiler.compile(screen, ui_storage: BasicDashboard.Storage.config(), use_cache: false)

    assert {:ok, canonical_iur} = IURAdapter.to_canonical(iur)
    assert :ok = UnifiedIUR.validate(canonical_iur)
    assert Enum.any?(canonical_iur["bindings"], &(Map.get(&1, "id") == "save_profile"))
  end

  test "16.4.1.2 - public docs describe resource-local authoring and relationship-driven composition" do
    readme = File.read!(project_path("README.md"))
    getting_started = File.read!(project_path("guides/user/UG-0001-getting-started.md"))
    resources_guide = File.read!(project_path("guides/user/UG-0002-resources.md"))
    bindings_guide = File.read!(project_path("guides/user/UG-0003-data-binding.md"))
    example_readme = File.read!(project_path("examples/basic_dashboard/README.md"))

    assert readme =~ "AshUI.Resource.DSL.Screen"
    assert readme =~ "AshUI.Resource.DSL.Element"
    assert readme =~ "ui_bindings"
    assert readme =~ "ui_actions"

    assert getting_started =~ "ui_relationships"
    assert getting_started =~ "AshUI.Resource.Authority"
    assert resources_guide =~ "Bindings are authored on screens or elements through"
    assert bindings_guide =~ "Use `ui_actions` when the UI should trigger an Ash-side operation."
    assert example_readme =~ "define a screen resource with `AshUI.Resource.DSL.Screen`"
    assert example_readme =~ "define related element resources with `AshUI.Resource.DSL.Element`"

    refute readme =~ "AshUI.DSL.Builder"
    refute getting_started =~ "AshUI.DSL.Builder"
    refute resources_guide =~ "Domain.create(Element"
    refute bindings_guide =~ "AshUI.Data.create(AshUI.Resources.Binding"
  end

  @tag timeout: 120_000
  test "16.4.1.3 - governance rejects reintroduction of the superseded model" do
    regression_path = project_path("examples/phase16_document_regression.md")

    on_exit(fn ->
      File.rm(regression_path)
    end)

    File.write!(
      regression_path,
      """
      # Regression Fixture

      UnifiedUi.Dsl should not appear in public example docs.
      """
    )

    {output, status} = run_shell("./scripts/validate_authoring_governance.sh")

    refute status == 0
    assert output =~ "legacy authoring reference outside approved historical docs"
  end

  test "16.4.1.4 - conformance traces to the restored architecture" do
    catalog = File.read!(project_path("specs/conformance/scenario_catalog.md"))
    matrix = File.read!(project_path("specs/conformance/spec_conformance_matrix.md"))
    traceability = File.read!(project_path("specs/conformance/scenario_test_matrix.md"))
    checklist = File.read!(project_path("release/RELEASE_CHECKLIST.md"))

    assert catalog =~ "#### SCN-050: Persisted Screen Authority Graph"
    assert catalog =~ "#### SCN-052: Element-Resource-First Example Authoring"
    assert catalog =~ "#### SCN-053: Relationship-Driven Composition Semantics"

    assert matrix =~ "SCN-041, SCN-050, SCN-051, SCN-052"
    assert matrix =~ "| REQ-COMP-004 | Resource Resolution | compilation/README.md | SCN-044, SCN-053 |"

    assert matrix =~
             "| REQ-SCREEN-003 | Element Composition | resources/ui_screen.md | SCN-005, SCN-053 |"

    assert traceability =~
             "| SCN-052 | Element-Resource-First Example Authoring | test/ash_ui/examples/basic_dashboard_test.exs, test/ash_ui/phase_13_integration_test.exs, test/ash_ui/phase_16_integration_test.exs |"

    assert traceability =~
             "| SCN-053 | Relationship-Driven Composition Semantics | test/ash_ui/phase_14_integration_test.exs, test/ash_ui/examples/basic_dashboard_test.exs, test/ash_ui/phase_16_integration_test.exs |"

    assert traceability =~
             "| SCN-071 | Renderer Parity For Resource Screens | test/ash_ui/examples/basic_dashboard_adapter_runner_test.exs |"

    assert checklist =~ "screen and element resource authoring through `AshUI.Resource.DSL.*`"
    assert checklist =~ "Composition is expressed through Ash relationships plus `ui_relationships`"
    assert checklist =~ "`ui_bindings` and `ui_actions` stay local to the owning element resource"
  end

  defp project_path(path) do
    Path.expand(path, root_dir())
  end

  defp root_dir do
    Path.expand("../..", __DIR__)
  end

  defp run_shell(command, extra_env \\ %{}) do
    env =
      %{
        "RELEASE_REPORT_DIR" => temp_dir("release-report"),
        "ROLLBACK_REPORT_DIR" => temp_dir("rollback-report")
      }
      |> Map.merge(extra_env)
      |> Enum.to_list()

    System.cmd("bash", ["-lc", command], cd: root_dir(), env: env, stderr_to_stdout: true)
  end

  defp temp_dir(prefix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "#{prefix}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end
end
