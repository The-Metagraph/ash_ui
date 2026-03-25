defmodule AshUI.Examples.BasicDashboardAdapterRunnerTest do
  use AshUI.DataCase, async: false

  alias AshUI.Rendering.Registry
  alias AshUI.Rendering.ElmUIAdapter
  alias AshUI.Rendering.LiveUIAdapter
  alias BasicDashboard.AdapterRunner

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
    assert result.authoring_module == "BasicDashboard.AuthoredScreen"
    assert is_binary(result.output)
    assert result.output =~ "Model your dashboard. Let the runtime do the wiring."
    assert result.output =~ "phx-change=\"ash_ui_change\""
    assert result.screen.name == "basic_dashboard"
  end

  test "renders the basic dashboard through the elm adapter" do
    assert {:ok, result} = AdapterRunner.render(:elm)

    assert result.renderer == :elm
    assert result.adapter_module == ElmUIAdapter
    assert result.authoring_module == "BasicDashboard.AuthoredScreen"
    assert is_binary(result.output)
    assert result.output =~ "<!DOCTYPE html>"
    assert result.screen.name == "basic_dashboard"
  end

  test "renders the same dashboard through liveview and elm from one canonical IUR" do
    assert {:ok, results} = AdapterRunner.render_many([:liveview, :elm])

    assert Map.keys(results) |> Enum.sort() == [:elm, :liveview]
    assert results.liveview.screen.id == results.elm.screen.id
    assert results.liveview.canonical_iur == results.elm.canonical_iur
    assert results.liveview.authoring_module == "BasicDashboard.AuthoredScreen"
    assert results.elm.authoring_module == "BasicDashboard.AuthoredScreen"

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

    widget_types = widget_types(results.liveview.canonical_iur)
    assert "hero" in widget_types
    assert "stat" in widget_types
    assert "key_value" in widget_types
    assert "info_list" in widget_types
    assert "form_builder" in widget_types
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
