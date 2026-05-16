defmodule LiveUi.DisplaySystemWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for display system widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "viewport widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Viewport)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Viewport.Component
      assert metadata.family == :display
      assert metadata.name == :viewport
    end

    test "viewport component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "test-viewport",
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Viewport content" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="viewport")
      assert html =~ "Viewport content"
    end

    test "viewport supports axis configuration" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "horizontal-viewport",
          inner_block: [],
          axis: "horizontal"
        })

      assert html =~ ~s(data-live-ui-axis="horizontal")
    end

    test "viewport supports offset positioning" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "offset-viewport",
          inner_block: [],
          offset_x: 100,
          offset_y: 200
        })

      assert html =~ ~s(data-live-ui-offset-x="100")
      assert html =~ ~s(data-live-ui-offset-y="200")
    end

    test "viewport supports clip mode" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "clipped-viewport",
          inner_block: [],
          clip: true
        })

      assert html =~ ~s(data-live-ui-clip)
    end

    test "viewport supports scrollbar configuration" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "scrolled-viewport",
          inner_block: [],
          scrollbars: "always"
        })

      assert html =~ ~s(data-live-ui-scrollbars="always")
    end
  end

  describe "scroll_bar widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ScrollBar)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ScrollBar.Component
      assert metadata.family == :display
      assert metadata.name == :scroll_bar
    end

    test "scroll_bar component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "test-scrollbar"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="scroll_bar")
    end

    test "scroll_bar supports orientation" do
      html_horizontal =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "horizontal-scrollbar",
          orientation: "horizontal"
        })

      html_vertical =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "vertical-scrollbar",
          orientation: "vertical"
        })

      assert html_horizontal =~ ~s(data-live-ui-orientation="horizontal")
      assert html_vertical =~ ~s(data-live-ui-orientation="vertical")
    end

    test "scroll_bar supports position tracking" do
      html =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "positioned-scrollbar",
          position_start: 0.25,
          position_end: 0.75
        })

      assert html =~ ~s(data-live-ui-position-start="0.25")
      assert html =~ ~s(data-live-ui-position-end="0.75")
    end

    test "scroll_bar supports viewport reference" do
      html =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "linked-scrollbar",
          viewport_ref: "my-viewport"
        })

      assert html =~ ~s(data-live-ui-viewport-ref="my-viewport")
    end

    test "scroll_bar supports sync groups" do
      html =
        render_component(&LiveUi.Widgets.ScrollBar.component/1, %{
          id: "synced-scrollbar",
          sync_group: "scroll-group-1"
        })

      assert html =~ ~s(data-live-ui-sync-group="scroll-group-1")
    end
  end

  describe "split_pane widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.SplitPane)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.SplitPane.Component
      assert metadata.family == :display
      assert metadata.name == :split_pane
    end

    test "split_pane component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "test-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "Primary pane" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "Secondary pane" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="split_pane")
      assert html =~ "Primary pane"
      assert html =~ "Secondary pane"
    end

    test "split_pane supports direction" do
      html_horizontal =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "horizontal-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "A" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "B" end}],
          direction: "horizontal"
        })

      html_vertical =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "vertical-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "A" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "B" end}],
          direction: "vertical"
        })

      assert html_horizontal =~ ~s(data-live-ui-direction="horizontal")
      assert html_vertical =~ ~s(data-live-ui-direction="vertical")
    end

    test "split_pane supports ratio configuration" do
      html =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "ratio-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "A" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "B" end}],
          ratio: 0.3
        })

      assert html =~ ~s(data-live-ui-ratio="0.3")
    end

    test "split_pane supports resizable mode" do
      html =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "resizable-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "A" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "B" end}],
          resizable: true
        })

      assert html =~ ~s(data-live-ui-resizable)
    end
  end

  describe "canvas widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Canvas)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Canvas.Component
      assert metadata.family == :display
      assert metadata.name == :canvas
    end

    test "canvas component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "test-canvas",
          operations: []
        })

      assert html =~ ~s(data-live-ui-widget-boundary="canvas")
    end

    test "canvas supports dimensions" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "sized-canvas",
          operations: [],
          width: 100,
          height: 50
        })

      assert html =~ ~s(data-live-ui-width="100")
      assert html =~ ~s(data-live-ui-height="50")
    end

    test "canvas supports unit configuration" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "unit-canvas",
          operations: [],
          unit: "pixel"
        })

      assert html =~ ~s(data-live-ui-unit="pixel")
    end

    test "canvas supports background options" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "background-canvas",
          operations: [],
          background: "surface"
        })

      assert html =~ ~s(data-live-ui-background="surface")
    end

    test "canvas supports drawing operations" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "drawing-canvas",
          operations: [
            %{kind: "text", position: %{x: 5, y: 10}, text: "Hello"}
          ]
        })

      assert html =~ "Hello"
      assert html =~ ~s(data-live-ui-canvas-op="text")
    end

    test "canvas supports clip mode" do
      html =
        render_component(&LiveUi.Widgets.Canvas.component/1, %{
          id: "clipped-canvas",
          operations: [],
          clip: true
        })

      assert html =~ ~s(data-live-ui-clip)
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders for viewport" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Viewport),
          %{id: "stable-viewport"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Viewport),
          %{id: "stable-viewport"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:display:viewport:stable-viewport:root"
    end

    test "widget identity includes mode in key for scroll_bar" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.ScrollBar),
          %{id: "mode-scrollbar"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.ScrollBar),
          %{id: "mode-scrollbar"},
          mode: :canonical
        )

      assert Identity.key(native_identity) == "native:display:scroll_bar:mode-scrollbar:root"

      assert Identity.key(canonical_identity) ==
               "canonical:display:scroll_bar:mode-scrollbar:root"
    end
  end

  describe "event semantics preservation" do
    test "scroll_bar has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.ScrollBar)

      assert :change in metadata.events
    end

    test "canvas has change events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Canvas)

      assert :change in metadata.events
    end
  end

  describe "bounded local state support" do
    test "display system widgets support local_state_keys for bounded state" do
      viewport_metadata = Component.metadata(LiveUi.Widgets.Viewport)
      scroll_bar_metadata = Component.metadata(LiveUi.Widgets.ScrollBar)
      split_pane_metadata = Component.metadata(LiveUi.Widgets.SplitPane)

      # Display system widgets can have local_state_keys for bounded UI state
      # like scroll position, split ratio, etc.
      assert is_list(viewport_metadata.local_state_keys)
      assert is_list(scroll_bar_metadata.local_state_keys)
      assert is_list(split_pane_metadata.local_state_keys)
    end
  end

  describe "display system interaction support" do
    test "viewport supports independent scroll mode" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "independent-viewport",
          inner_block: [],
          independent_scroll: true
        })

      assert html =~ ~s(data-live-ui-independent-scroll)
    end

    test "viewport supports sync groups" do
      html =
        render_component(&LiveUi.Widgets.Viewport.component/1, %{
          id: "synced-viewport",
          inner_block: [],
          sync_group: "viewport-group-1"
        })

      assert html =~ ~s(data-live-ui-sync-group="viewport-group-1")
    end

    test "split_pane supports minimum size constraints" do
      html =
        render_component(&LiveUi.Widgets.SplitPane.component/1, %{
          id: "constrained-split",
          primary: [%{__slot__: :primary, inner_block: fn _, _ -> "A" end}],
          secondary: [%{__slot__: :secondary, inner_block: fn _, _ -> "B" end}],
          min_primary: 200,
          min_secondary: 150
        })

      assert html =~ ~s(data-live-ui-min-primary="200")
      assert html =~ ~s(data-live-ui-min-secondary="150")
    end
  end
end
