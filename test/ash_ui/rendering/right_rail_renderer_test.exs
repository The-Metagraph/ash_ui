defmodule AshUI.Rendering.RightRailRendererTest do
  use ExUnit.Case, async: true

  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.{Components, Foundational}

  @moduletag :conformance

  test "Live UI adapter renders canonical right rail natively" do
    assert {:ok, html} = LiveUIAdapter.render(canonical_rail())

    assert html =~ ~s(data-live-ui-widget="right-rail")
    assert html =~ "Summary body"
    refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
    refute html =~ ~s(data-live-ui-component-kind="right_rail")
  end

  test "Elm UI fallback preserves right rail component diagnostics" do
    assert {:ok, html} = ElmUIAdapter.render(canonical_rail(), force_fallback: true)

    assert html =~ ~s(data-ash-ui-renderer-diagnostic="unsupported_component_fallback")
    assert html =~ ~s(data-component-kind="right_rail")
    assert html =~ ~s(data-component-family="layer_shell_and_callout")
  end

  test "Desktop UI fallback preserves right rail component diagnostics" do
    assert {:ok, rail} = DesktopUIAdapter.render(canonical_rail(), force_fallback: true)

    assert rail["widget_type"] == "right_rail"

    assert rail["diagnostic"] == %{
             "code" => "unsupported_component_fallback",
             "component_kind" => :right_rail,
             "component_family" => :layer_shell_and_callout,
             "message" => "Desktop fallback preserved canonical component identity."
           }
  end

  defp canonical_rail do
    Components.right_rail(
      id: "workspace-rail",
      panels: [
        %{id: :summary, label: "Summary", content_slot: :summary_body},
        %{id: :activity, label: "Activity", content_slot: :activity_body}
      ],
      active_panel: :summary,
      children: [
        Element.Child.new(:summary_body, Foundational.text("Summary body", id: "summary-body")),
        Element.Child.new(:activity_body, Foundational.text("Activity body", id: "activity-body"))
      ]
    )
  end
end
