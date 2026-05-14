defmodule UnifiedIUR.ViewportTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Container
  alias UnifiedIUR.Element
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Viewport
  alias UnifiedIUR.Widgets.Foundational

  test "exposes canonical viewport and split-region kinds" do
    assert [:viewport, :scroll_bar, :split_pane] == Viewport.kinds()
  end

  test "builds viewport regions with normalized offsets and clipping metadata" do
    content =
      Container.box(
        [
          {:content, Foundational.text("Large body", id: "body-copy")}
        ],
        id: "body-box"
      )

    viewport =
      Viewport.region(content,
        id: "body-viewport",
        offset: {4, 12},
        scrollbars: :always,
        height: 40,
        sync_group: :editor
      )

    assert %Element{
             kind: :viewport,
             children: [%{slot: :content, element: %Element{id: "body-box"}}],
             attributes: %{
               viewport: %{
                 axis: :vertical,
                 offset: %{x: 4, y: 12},
                 clip?: true,
                 scrollbars: :always,
                 height: 40,
                 sync_group: :editor
               }
             }
           } = viewport
  end

  test "builds scroll bars and split panes with richer divider and region metadata" do
    primary =
      Layout.scroll_region(
        Container.content([{:content, Foundational.text("Nav", id: "nav-copy")}],
          id: "nav-panel"
        ),
        id: "nav-viewport",
        sync_group: :workspace_nav
      )

    secondary =
      Layout.scroll_region(
        Container.content([{:content, Foundational.text("Detail", id: "detail-copy")}],
          id: "detail-panel"
        ),
        id: "detail-viewport",
        offset: 12,
        sync_group: :workspace_detail
      )

    scroll_bar =
      Viewport.scroll_bar(
        id: "detail-scrollbar",
        viewport_ref: "detail-viewport",
        position: {12, 52},
        viewport_size: 40,
        content_size: 120,
        sync_group: :workspace_detail
      )

    split =
      Viewport.split_pane(primary, secondary,
        id: "workspace-split",
        direction: :vertical,
        ratio: 0.3,
        divider_size: 1,
        divider_style: :solid,
        primary_size: 24,
        secondary_size: 56,
        sync_scroll: :independent
      )

    assert %Element{
             kind: :scroll_bar,
             attributes: %{
               scroll_bar: %{
                 viewport_ref: "detail-viewport",
                 position: %{start: 12, end: 52},
                 viewport_size: 40,
                 content_size: 120,
                 sync_group: :workspace_detail
               }
             }
           } = scroll_bar

    assert %Element{
             kind: :split_pane,
             children: [%{slot: :primary}, %{slot: :secondary}],
             attributes: %{
               split: %{
                 direction: :vertical,
                 ratio: 0.3,
                 resizable?: true,
                 primary_size: 24,
                 secondary_size: 56,
                 divider: %{size: 1, style: :solid},
                 sync_scroll: :independent
               }
             }
           } = split
  end
end
