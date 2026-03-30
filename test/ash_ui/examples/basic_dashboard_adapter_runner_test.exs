defmodule AshUI.Examples.BasicDashboardAdapterRunnerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Rendering.Registry
  alias AshUI.Rendering.ElmUIAdapter
  alias AshUI.Rendering.LiveUIAdapter
  alias BasicDashboard.AdapterRunner

  @moduletag :conformance

  defp widget_types(%{"type" => type} = node) do
    child_types =
      node
      |> Map.get("children", [])
      |> Enum.flat_map(&widget_types/1)

    [type | child_types]
  end

  defp widget_types(_node), do: []

  test "renders the basic dashboard through the liveview adapter" do
    assert {:ok, result} = AdapterRunner.render(:liveview)

    assert result.renderer == :liveview
    assert result.adapter_module == LiveUIAdapter
    assert result.screen_module == "BasicDashboard.Screen"
    assert "BasicDashboard.HeroElement" in result.element_modules
    assert "BasicDashboard.SaveProfileButtonElement" in result.element_modules
    assert result.graph_element_count >= 10
    assert result.graph_binding_count >= 2
    assert is_binary(result.output)
    assert result.output =~ "Model your dashboard. Let the runtime do the wiring."
    assert result.output =~ "phx-change=\"ash_ui_change\""
    assert result.screen.name == "basic_dashboard"
  end

  test "renders the basic dashboard through the elm adapter" do
    assert {:ok, result} = AdapterRunner.render(:elm)

    assert result.renderer == :elm
    assert result.adapter_module == ElmUIAdapter
    assert result.screen_module == "BasicDashboard.Screen"
    assert is_binary(result.output)
    assert result.output =~ "<!DOCTYPE html>"
    assert result.screen.name == "basic_dashboard"
  end

  test "renders the same dashboard through liveview and elm from one canonical IUR" do
    assert {:ok, results} = AdapterRunner.render_many([:liveview, :elm])

    assert Map.keys(results) |> Enum.sort() == [:elm, :liveview]
    assert results.liveview.screen.id == results.elm.screen.id
    assert results.liveview.canonical_iur == results.elm.canonical_iur
    assert results.liveview.screen_module == "BasicDashboard.Screen"
    assert results.elm.screen_module == "BasicDashboard.Screen"
    assert results.liveview.element_modules == results.elm.element_modules
    assert results.liveview.graph_element_count == results.elm.graph_element_count
    assert results.liveview.graph_binding_count == results.elm.graph_binding_count

    Enum.each(
      [
        "Model your dashboard. Let the runtime do the wiring.",
        "Interactive profile editor",
        "Current dashboard state"
      ],
      fn copy ->
        assert results.liveview.output =~ copy
        assert results.elm.output =~ copy
      end
    )

    assert results.liveview.output =~ "phx-change=\"ash_ui_change\""
    assert results.elm.output =~ "<!DOCTYPE html>"
    assert results.elm.output =~ "ash-ui-elm-flags"
    assert "BasicDashboard.HeroElement" in results.liveview.element_modules
    assert "BasicDashboard.SaveProfileButtonElement" in results.liveview.element_modules

    widget_types = widget_types(results.liveview.canonical_iur)
    assert "hero" in widget_types
    assert "stat" in widget_types
    assert "key_value" in widget_types
    assert "info_list" in widget_types
    assert "card" in widget_types
    assert "form_field" in widget_types
    assert "input" in widget_types
    assert "button" in widget_types
  end

  test "reports terminal_ui as unavailable because it is not implemented yet" do
    assert {:error, :not_found} = Registry.renderer_info(:terminal)
    refute :terminal in AdapterRunner.supported_renderers()
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
