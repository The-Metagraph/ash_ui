defmodule AshUI.Phase12IntegrationTest do
  use ExUnit.Case, async: false

  alias BasicDashboard.Data

  @moduletag :integration

  @tag timeout: 120_000
  test "12.4.1.1 - standalone example app runs with relationship-authored screens" do
    run_shell!(
      "cd examples/basic_dashboard && MIX_ENV=test mix deps.get && MIX_ENV=test mix compile"
    )

    Data.seed!()
    screen = BasicDashboard.seed!()

    assert File.exists?(project_path("examples/basic_dashboard/mix.exs"))
    assert screen.name == "basic_dashboard"

    assert get_in(screen.unified_dsl, ["screen", "module"]) ==
             "Elixir.BasicDashboard.Screen"
  end

  @tag timeout: 120_000
  test "12.4.1.2 - adapter tooling works against relationship-authored screens" do
    liveview_output =
      run_shell!("MIX_ENV=test mix ash_ui.example.basic_dashboard --renderer liveview")

    elm_output = run_shell!("MIX_ENV=test mix ash_ui.example.basic_dashboard --renderer elm")

    assert liveview_output =~ "Renderer: liveview"
    assert liveview_output =~ "Screen module: BasicDashboard.Screen"
    assert liveview_output =~ "phx-change=\"ash_ui_change\""

    assert elm_output =~ "Renderer: elm"
    assert elm_output =~ "Screen module: BasicDashboard.Screen"
    assert elm_output =~ "<!DOCTYPE html>"
  end

  @tag timeout: 120_000
  test "12.4.1.3 - governance checks reject builder-first public examples" do
    regression_path = project_path("examples/phase12_builder_regression.md")

    on_exit(fn ->
      File.rm(regression_path)
    end)

    File.write!(
      regression_path,
      """
      # Regression Fixture

      AshUI.DSL.Builder should not appear in public example docs.
      """
    )

    {output, status} = run_shell("./scripts/validate_guides_governance.sh")

    refute status == 0
    assert output =~ "authoring governance validation failed"
    assert output =~ "legacy authoring reference outside approved historical docs"
  end

  test "12.4.1.4 - conformance coverage documents the resource-first architecture accurately" do
    catalog = File.read!(project_path("specs/conformance/scenario_catalog.md"))
    matrix = File.read!(project_path("specs/conformance/spec_conformance_matrix.md"))
    traceability = File.read!(project_path("specs/conformance/scenario_test_matrix.md"))

    assert catalog =~ "#### SCN-050: Persisted Screen Authority Graph"
    assert catalog =~ "#### SCN-051: Relational Compiler Delegation"
    assert catalog =~ "#### SCN-052: Element-Resource-First Example Authoring"
    assert catalog =~ "#### SCN-053: Relationship-Driven Composition Semantics"
    assert catalog =~ "#### SCN-071: Renderer Parity For Resource Screens"

    assert matrix =~ "| REQ-COMP-001 | Compilation Pipeline |"
    assert matrix =~ "SCN-041, SCN-050, SCN-051, SCN-052"
    assert matrix =~ "SCN-068, SCN-071"
    assert matrix =~ "SCN-061, SCN-071"
    assert matrix =~ "SCN-062, SCN-071"
    assert matrix =~ "SCN-044, SCN-053"

    assert matrix =~
             "| REQ-SCREEN-001 | Screen Definition | resources/ui_screen.md | SCN-004, SCN-050, SCN-052 |"

    assert traceability =~
             "| SCN-050 | Persisted Screen Authority Graph | test/ash_ui/examples/basic_dashboard_test.exs, test/ash_ui/phase_13_integration_test.exs, test/ash_ui/phase_16_integration_test.exs |"

    assert traceability =~
             "| SCN-051 | Relational Compiler Delegation | test/ash_ui/compiler_test.exs, test/ash_ui/phase_11_integration_test.exs, test/ash_ui/phase_15_integration_test.exs |"

    assert traceability =~
             "| SCN-052 | Element-Resource-First Example Authoring | test/ash_ui/examples/basic_dashboard_test.exs, test/ash_ui/phase_13_integration_test.exs, test/ash_ui/phase_16_integration_test.exs |"

    assert traceability =~
             "| SCN-053 | Relationship-Driven Composition Semantics | test/ash_ui/phase_14_integration_test.exs, test/ash_ui/examples/basic_dashboard_test.exs, test/ash_ui/phase_16_integration_test.exs |"

    assert traceability =~
             "| SCN-071 | Renderer Parity For Resource Screens | test/ash_ui/examples/basic_dashboard_adapter_runner_test.exs |"

    assert File.read!(project_path("test/ash_ui/examples/basic_dashboard_test.exs")) =~
             "@moduletag :conformance"

    assert File.read!(project_path("test/ash_ui/phase_11_integration_test.exs")) =~
             "@moduletag :conformance"

    assert File.read!(project_path("test/ash_ui/phase_15_integration_test.exs")) =~
             "@moduletag :conformance"

    assert File.read!(
             project_path("test/ash_ui/examples/basic_dashboard_adapter_runner_test.exs")
           ) =~
             "@moduletag :conformance"

    assert File.read!(project_path("test/ash_ui/phase_16_integration_test.exs")) =~
             "@moduletag :conformance"
  end

  defp project_path(path) do
    Path.expand(path, root_dir())
  end

  defp root_dir do
    Path.expand("../..", __DIR__)
  end

  defp run_shell!(command, extra_env \\ %{}) do
    {output, status} = run_shell(command, extra_env)
    assert status == 0, output
    output
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
