defmodule LiveUi.AdvancedDiagnosticsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Element

  test "native advanced widgets emit readable diagnostics for invalid display inputs" do
    html =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Widgets.ContextMenu.render/1, %{id: "context", anchor: %{}, items: []})}
      #{render_component(&LiveUi.Widgets.ScrollBar.render/1, %{id: "scroll"})}
      #{render_component(&LiveUi.Widgets.Canvas.render/1, %{id: "canvas", operations: [%{kind: :bogus}]})}
      """)
      |> Phoenix.HTML.safe_to_string()

    assert html =~ "data-live-ui-diagnostic=\"invalid_layer_target\""
    assert html =~ "data-live-ui-diagnostic=\"missing_display_ref\""
    assert html =~ "data-live-ui-diagnostic=\"invalid_canvas_operation\""
  end

  test "canonical advanced constructs surface actionable diagnostics when invalid" do
    invalid_overlay =
      Element.new(:layer, :overlay,
        id: "broken-overlay",
        attributes: %{overlay: %{mode: :stacked}},
        children: []
      )

    invalid_context_menu =
      Element.new(:layer, :context_menu,
        id: "broken-context",
        attributes: %{context_menu: %{anchor: %{}}},
        children: []
      )

    invalid_canvas =
      Element.new(:widget, :canvas,
        id: "broken-canvas",
        attributes: %{canvas: %{operations: [%{kind: :bogus}]}}
      )

    html =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Renderer.render/1, %{element: invalid_overlay})}
      #{render_component(&LiveUi.Renderer.render/1, %{element: invalid_context_menu})}
      #{render_component(&LiveUi.Renderer.render/1, %{element: invalid_canvas})}
      """)
      |> Phoenix.HTML.safe_to_string()

    assert html =~ "overlay_surface requires a base slot"
    assert html =~ "layered widgets require an anchor target_id or explicit x/y coordinates"
    assert html =~ "canvas operation 0 is invalid"
  end
end
