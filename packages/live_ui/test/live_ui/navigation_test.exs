defmodule LiveUi.NavigationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "menu, tabs, and command palette expose active-state and action surfaces" do
    html =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Widgets.Menu.render/1, %{id: "menu", active_item: "dashboard", items: [%{id: "dashboard", label: "Dashboard"}, %{id: "settings", label: "Settings"}]})}
      #{render_component(&LiveUi.Widgets.Tabs.render/1, %{id: "tabs", active_item: "details", items: [%{id: "details", label: "Details"}, %{id: "activity", label: "Activity"}]})}
      #{render_component(&LiveUi.Widgets.CommandPalette.render/1, %{id: "palette", query: "de", items: [%{id: "details", label: "Open Details", active: true}]})}
      """)
      |> Phoenix.HTML.safe_to_string()

    assert html =~ "data-live-ui-widget=\"menu\""
    assert html =~ "data-live-ui-widget=\"tabs\""
    assert html =~ "data-live-ui-widget=\"command-palette\""
    assert html =~ "aria-selected=\"true\""
    assert html =~ "data-command-id=\"details\""
  end

  test "navigation widgets are registered as native modules" do
    metadata = Enum.map(LiveUi.Widgets.navigation_modules(), &LiveUi.Component.metadata/1)

    assert Enum.any?(metadata, &(&1.name == :menu))
    assert Enum.any?(metadata, &(&1.name == :tabs))
    assert Enum.any?(metadata, &(&1.name == :command_palette))
  end
end
