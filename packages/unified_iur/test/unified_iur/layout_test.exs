defmodule UnifiedIUR.LayoutTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Container
  alias UnifiedIUR.Element
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Widgets.Foundational

  test "exposes the canonical layout constructor family" do
    assert [:row, :column, :stack, :grid, :split_pane, :viewport, :scroll_bar] == Layout.kinds()
  end

  test "builds box and directional layouts with spacing, alignment, sizing, and ordering metadata" do
    heading = Foundational.label("Toolbar", id: "toolbar-label")
    primary = Foundational.button("Save", id: "save-button")
    secondary = Foundational.button("Cancel", id: "cancel-button")

    box =
      Container.box(
        [
          {:content, heading},
          {:content, primary}
        ],
        id: "toolbar-box",
        padding: 2,
        border: :solid,
        gap: 1,
        width: 80
      )

    row =
      Layout.row(
        [
          {:leading, primary},
          {:trailing, secondary}
        ],
        id: "toolbar-row",
        gap: 2,
        align: :center,
        justify: :space_between,
        width: 80,
        order: :visual
      )

    column =
      Layout.column(
        [
          {:header, heading},
          {:body, row}
        ],
        id: "toolbar-column",
        gap: 1,
        align: :stretch
      )

    stack =
      Layout.stack(
        [
          {:base, box},
          {:overlay, secondary}
        ],
        id: "toolbar-stack",
        stacking: :overlay
      )

    grid =
      Layout.grid(
        [
          {:cell, heading},
          {:cell, primary},
          {:cell, secondary}
        ],
        id: "toolbar-grid",
        columns: 2,
        rows: 2,
        gap: 1
      )

    assert %Element{
             kind: :box,
             attributes: %{
               container: %{padding: 2, border: :solid},
               layout: %{gap: 1, width: 80}
             }
           } = box

    assert %Element{
             kind: :row,
             attributes: %{
               layout: %{
                 direction: :horizontal,
                 gap: 2,
                 align: :center,
                 justify: :space_between,
                 width: 80,
                 order: :visual
               }
             }
           } = row

    assert %Element{
             kind: :column,
             attributes: %{layout: %{direction: :vertical, gap: 1, align: :stretch}}
           } =
             column

    assert %Element{kind: :stack, attributes: %{layout: %{stacking: :overlay}}} = stack

    assert %Element{
             kind: :grid,
             attributes: %{layout: %{columns: 2, rows: 2, auto_flow: :row, gap: 1}}
           } = grid
  end

  test "builds split and scroll-oriented baseline layout structures" do
    navigation =
      Container.content([Foundational.label("Nav", id: "nav-label")], id: "nav-content")

    detail = Container.content([Foundational.text("Body", id: "body-copy")], id: "body-content")

    split =
      Layout.split_pane(navigation, detail,
        id: "workspace-split",
        direction: :vertical,
        ratio: 0.3,
        resizable?: true,
        min_primary: 10,
        min_secondary: 20
      )

    viewport =
      Layout.scroll_region(detail,
        id: "detail-viewport",
        axis: :vertical,
        offset: 12,
        scrollbars: :always,
        height: 40
      )

    scroll_bar =
      Layout.scroll_bar(
        id: "detail-scrollbar",
        orientation: :vertical,
        position: 12,
        viewport_size: 40,
        content_size: 120
      )

    assert %Element{
             kind: :split_pane,
             children: [primary, secondary],
             attributes: %{
               split: %{
                 direction: :vertical,
                 ratio: 0.3,
                 resizable?: true,
                 min_primary: 10,
                 min_secondary: 20
               }
             }
           } = split

    assert primary.slot == :primary
    assert secondary.slot == :secondary
    assert primary.element.id == "nav-content"
    assert secondary.element.id == "body-content"

    assert %Element{
             kind: :viewport,
             children: [content],
             attributes: %{
               viewport: %{
                 axis: :vertical,
                 offset: %{x: 0, y: 12},
                 clip?: true,
                 scrollbars: :always,
                 height: 40
               }
             }
           } = viewport

    assert content.slot == :content
    assert content.element.id == "body-content"

    assert %Element{
             kind: :scroll_bar,
             attributes: %{
               scroll_bar: %{
                 orientation: :vertical,
                 position: %{start: 12, end: 12},
                 viewport_size: 40,
                 content_size: 120
               }
             }
           } = scroll_bar
  end
end
