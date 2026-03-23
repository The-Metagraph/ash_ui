defmodule AshUI.Examples.BasicDashboardMixTaskTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "renders the dashboard with the elm renderer by default" do
    Mix.Task.reenable("ash_ui.example.basic_dashboard")

    output =
      capture_io(fn ->
        Mix.Tasks.AshUi.Example.BasicDashboard.run([])
      end)

    assert output =~ "Renderer: elm"
    assert output =~ "<!DOCTYPE html>"
  end

  test "rejects removed html renderer flag" do
    Mix.Task.reenable("ash_ui.example.basic_dashboard")

    assert_raise Mix.Error, ~r/Unsupported renderer \"html\"/, fn ->
      capture_io(fn ->
        Mix.Tasks.AshUi.Example.BasicDashboard.run(["--renderer", "html"])
      end)
    end
  end
end
