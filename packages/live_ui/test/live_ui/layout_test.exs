defmodule LiveUi.LayoutTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "row, column, and grid preserve child ordering and layout metadata" do
    html =
      render_component(&LiveUi.Layout.Grid.render/1, %{
        id: "grid",
        columns: 2,
        inner_block: [
          %{
            __slot__: :inner_block,
            inner_block: fn _, _ ->
              Phoenix.HTML.raw("""
              #{render_component(&LiveUi.Layout.Row.render/1, %{id: "row", inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Row Child" end}]})}
              #{render_component(&LiveUi.Layout.Column.render/1, %{id: "column", inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Column Child" end}]})}
              """)
            end
          }
        ]
      })

    assert html =~ "data-live-ui-widget=\"grid\""
    assert html =~ "data-live-ui-widget=\"row\""
    assert html =~ "data-live-ui-widget=\"column\""
    assert html =~ "Row Child"
    assert html =~ "Column Child"
  end

  test "layout primitives realize geometry attrs into browser-visible style output" do
    html =
      render_component(&LiveUi.Layout.Grid.render/1, %{
        id: "grid",
        columns: 3,
        rows: 2,
        gap: "lg",
        padding: "md",
        align: "center",
        justify: "between",
        width: "100%",
        min_height: "12rem",
        inner_block: [
          %{
            __slot__: :inner_block,
            inner_block: fn _, _ ->
              Phoenix.HTML.raw("""
              #{render_component(&LiveUi.Layout.Row.render/1, %{id: "row", gap: "sm", padding: "lg", align: "center", justify: "between", width: "80%", inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Row Child" end}]})}
              #{render_component(&LiveUi.Layout.Column.render/1, %{id: "column", gap: "md", padding: "sm", align: "end", justify: "start", max_width: "28rem", inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Column Child" end}]})}
              """)
            end
          }
        ]
      })

    assert html =~ "--live-ui-grid-columns: 3"
    assert html =~ "--live-ui-grid-rows: 2"
    assert html =~ "--live-ui-gap: 1rem"
    assert html =~ "--live-ui-padding: 0.75rem"
    assert html =~ "--live-ui-align-items: center"
    assert html =~ "--live-ui-justify-content: space-between"
    assert html =~ "--live-ui-width: 100%"
    assert html =~ "--live-ui-min-height: 12rem"
    assert html =~ "--live-ui-max-width: 28rem"
  end

  test "box authored attrs combine with browser style defaults and nested widgets reset inherited vars" do
    html =
      render_component(&LiveUi.Widgets.Box.render/1, %{
        id: "shell",
        padding: "lg",
        border: "subtle",
        background: "panel",
        inner_block: [
          %{
            __slot__: :inner_block,
            inner_block: fn _, _ ->
              Phoenix.HTML.raw(
                render_component(&LiveUi.Widgets.Text.render/1, %{id: "copy", content: "Nested"})
              )
            end
          }
        ]
      })

    css = LiveUi.Stylesheet.css()

    assert html =~ "--live-ui-padding: 1rem"
    assert html =~ "--live-ui-border-color: var(--live-ui-theme-border-muted)"
    assert html =~ "--live-ui-background: linear-gradient"
    assert css =~ "--live-ui-background: initial"
    assert css =~ "--live-ui-gap: initial"
  end
end
