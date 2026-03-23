defmodule AshUI.Examples.BasicDashboardAdapterRunnerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Rendering.ElmUIAdapter
  alias BasicDashboard.AdapterRunner

  test "renders the basic dashboard through the elm adapter" do
    assert {:ok, result} = AdapterRunner.render(:elm)

    assert result.renderer == :elm
    assert result.adapter_module == ElmUIAdapter
    assert is_binary(result.output)
    assert result.output =~ "<!DOCTYPE html>"
    assert result.screen.name == "basic_dashboard"
  end

  test "formats desktop output as JSON" do
    result = %{
      renderer: :desktop,
      output: %{"type" => "desktop_screen", "name" => "basic_dashboard"}
    }

    formatted = AdapterRunner.format_output(result, pretty: true)
    assert formatted =~ "\"type\": \"desktop_screen\""
  end
end
