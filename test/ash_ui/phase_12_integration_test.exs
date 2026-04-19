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

  test "12.4.1.4 - the .spec workspace documents the resource-first architecture accurately" do
    workspace = File.read!(project_path(".spec/README.md"))
    architecture = File.read!(project_path(".spec/specs/architecture.spec.md"))
    resource_authoring = File.read!(project_path(".spec/specs/resource_authoring.spec.md"))
    runtime = File.read!(project_path(".spec/specs/runtime_authorization.spec.md"))
    rendering = File.read!(project_path(".spec/specs/rendering.spec.md"))
    governance = File.read!(project_path(".spec/specs/governance.spec.md"))

    element_decision =
      File.read!(project_path(".spec/decisions/ashui.decision.element_resource_authority.md"))

    superseded_decision =
      File.read!(project_path(".spec/decisions/ashui.decision.unified_ui_dsl_authority.md"))

    assert workspace =~ "mix spec.prime --base HEAD"

    assert architecture =~ "id: ashui.architecture"
    assert architecture =~ "relationship graph"
    assert architecture =~ "ashui.decision.element_resource_authority"

    assert resource_authoring =~ "id: ashui.resource_authoring"
    assert resource_authoring =~ "ui_bindings"
    assert resource_authoring =~ "ui_actions"
    assert resource_authoring =~ "AshUI.Resource.Authority"

    assert runtime =~ "mount_ui_screen/3"
    assert runtime =~ "check_mount_authorization"
    assert runtime =~ "handle_action_event"

    assert rendering =~ "canonical unified_iur-compatible maps"
    assert rendering =~ "elm_ui"
    assert rendering =~ "optional path dependencies"

    assert governance =~ ".spec/state.json"
    assert governance =~ "scripts/validate_specs_governance.sh"

    assert element_decision =~ "status: accepted"
    assert element_decision =~ "resource-first architecture"
    assert superseded_decision =~ "status: superseded"
    assert superseded_decision =~ "superseded_by: ashui.decision.element_resource_authority"

    assert File.read!(project_path("test/ash_ui/examples/basic_dashboard_test.exs")) =~
             "@moduletag :conformance"

    assert File.read!(project_path("test/ash_ui/phase_13_integration_test.exs")) =~
             "@moduletag :conformance"

    assert File.read!(project_path("test/ash_ui/phase_14_integration_test.exs")) =~
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

    AshUI.TestShell.run(command, cd: root_dir(), env: env, stderr_to_stdout: true)
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
