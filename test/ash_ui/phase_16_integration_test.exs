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

  @tag timeout: 120_000
  test "16.4.1.4 - governance and release assets trace to the restored architecture through .spec" do
    {output, status} = AshUI.TestShell.run_spec_validate(root_dir())
    state = Jason.decode!(File.read!(project_path(".spec/state.json")))
    checklist = File.read!(project_path("release/RELEASE_CHECKLIST.md"))
    contributing = File.read!(project_path("guides/developer/DG-0002-contributing.md"))
    package_spec = File.read!(project_path(".spec/specs/package.spec.md"))
    governance = File.read!(project_path(".spec/specs/governance.spec.md"))

    subject_ids =
      get_in(state, ["index", "subjects"])
      |> Enum.map(& &1["id"])
      |> MapSet.new()

    decision_ids =
      get_in(state, ["decisions", "items"])
      |> Enum.map(& &1["id"])
      |> MapSet.new()

    assert status == 0, output
    assert output =~ "Specs governance validation passed."
    assert state["summary"]["subjects"] >= 6
    assert length(get_in(state, ["decisions", "items"]) || []) >= 4

    assert MapSet.subset?(
             MapSet.new([
               "ashui.package",
               "ashui.architecture",
               "ashui.resource_authoring",
               "ashui.runtime_authorization",
               "ashui.rendering",
               "ashui.governance"
             ]),
             subject_ids
           )

    assert "ashui.decision.element_resource_authority" in decision_ids
    assert "ashui.decision.control_plane_authority" in decision_ids

    assert checklist =~ "screen and element resource authoring through `AshUI.Resource.DSL.*`"
    assert checklist =~ "Composition is expressed through Ash relationships plus `ui_relationships`"
    assert checklist =~ "`ui_bindings` and `ui_actions` stay local to the owning element resource"
    assert checklist =~ ".spec/state.json"

    assert contributing =~ ".spec/specs/"
    assert package_spec =~ "id: ashui.package"
    assert package_spec =~ "spec_led_ex"
    assert governance =~ ".spec/specs/*.spec.md"
    assert governance =~ "scripts/validate_specs_governance.sh"
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

    AshUI.TestShell.run(command, cd: root_dir(), env: env, stderr_to_stdout: true)
  end

  defp run_shell!(command, extra_env \\ %{}) do
    {output, status} = run_shell(command, extra_env)
    assert status == 0, output
    output
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
