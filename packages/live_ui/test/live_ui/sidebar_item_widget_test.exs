defmodule LiveUi.SidebarItemWidgetTest do
  @moduledoc """
  Stage-4 tests for `LiveUi.Widgets.SidebarItem`.

  Verifies:
  - `data-live-ui-widget="sidebar-item"` root attribute (true-widget, not component-kind fallback)
  - Label renders inside the button
  - `aria-current="page"` on the button when `selected?` is `true`
  - `live-ui-sidebar-item--selected` BEM modifier class when selected
  - Avatar `<img>` rendered with correct class + `aria-hidden="true"` when `avatar_url` present
  - Avatar `<img>` omitted when `avatar_url` is `nil`
  - `data-live-ui-item-state` hook present when `item_state` is `:stalled`, `:blocked`, `:errored`
  - `data-live-ui-item-state` absent when `item_state` is `nil` or `:default`
  - BEM state modifier class applied for each non-default state
  - Renderer dispatches to `LiveUi.Widgets.SidebarItem` (not generic fallback)
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Widgets.Components

  # ---------------------------------------------------------------------------
  # Stage-4 Phoenix.Component direct render tests
  # ---------------------------------------------------------------------------

  describe "SidebarItem Phoenix.Component" do
    test "renders with the true-widget data attribute (not component-kind fallback)" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-1",
          label: "Overview",
          selected?: false,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      assert html =~ ~s(data-live-ui-widget="sidebar-item")
      refute html =~ ~s(data-live-ui-component-kind)
    end

    test "renders the label text inside the button" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-2",
          label: "Design Docs",
          selected?: false,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      assert html =~ "Design Docs"
      assert html =~ "live-ui-sidebar-item-button"
    end

    test "renders aria-current=page and --selected class when selected" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-3",
          label: "Active Item",
          selected?: true,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      assert html =~ ~s(aria-current="page")
      assert html =~ "live-ui-sidebar-item--selected"
    end

    test "omits aria-current and --selected class when not selected" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-4",
          label: "Inactive",
          selected?: false,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      refute html =~ ~s(aria-current)
      refute html =~ "live-ui-sidebar-item--selected"
    end

    test "renders avatar img with aria-hidden when avatar_url is present" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-5",
          label: "Alice DM",
          selected?: false,
          avatar_url: "https://example.com/alice.png",
          item_state: nil,
          item_intent: nil
        })

      assert html =~ ~s(<img)
      assert html =~ "live-ui-sidebar-item__avatar"
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "https://example.com/alice.png"
    end

    test "omits avatar img when avatar_url is nil" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-6",
          label: "No Avatar",
          selected?: false,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      refute html =~ "live-ui-sidebar-item__avatar"
      refute html =~ ~s(<img)
    end

    test "renders data-live-ui-item-state hook for :stalled" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-7",
          label: "Stalled Task",
          selected?: false,
          avatar_url: nil,
          item_state: :stalled,
          item_intent: nil
        })

      assert html =~ ~s(data-live-ui-item-state="stalled")
      assert html =~ "live-ui-sidebar-item--state-stalled"
    end

    test "renders data-live-ui-item-state hook for :blocked" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-8",
          label: "Blocked Task",
          selected?: false,
          avatar_url: nil,
          item_state: :blocked,
          item_intent: nil
        })

      assert html =~ ~s(data-live-ui-item-state="blocked")
      assert html =~ "live-ui-sidebar-item--state-blocked"
    end

    test "renders data-live-ui-item-state hook for :errored" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-9",
          label: "Errored Task",
          selected?: false,
          avatar_url: nil,
          item_state: :errored,
          item_intent: nil
        })

      assert html =~ ~s(data-live-ui-item-state="errored")
      assert html =~ "live-ui-sidebar-item--state-errored"
    end

    test "omits data-live-ui-item-state when item_state is nil" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-10",
          label: "Normal",
          selected?: false,
          avatar_url: nil,
          item_state: nil,
          item_intent: nil
        })

      refute html =~ "data-live-ui-item-state"
      refute html =~ "live-ui-sidebar-item--state-"
    end

    test "omits data-live-ui-item-state when item_state is :default" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-11",
          label: "Default State",
          selected?: false,
          avatar_url: nil,
          item_state: :default,
          item_intent: nil
        })

      refute html =~ "data-live-ui-item-state"
      refute html =~ "live-ui-sidebar-item--state-"
    end

    test "renders avatar and state together" do
      html =
        render_component(&LiveUi.Widgets.SidebarItem.render/1, %{
          id: "si-12",
          label: "Bob DM (stalled)",
          selected?: false,
          avatar_url: "https://example.com/bob.png",
          item_state: :stalled,
          item_intent: nil
        })

      assert html =~ "live-ui-sidebar-item__avatar"
      assert html =~ ~s(data-live-ui-item-state="stalled")
      assert html =~ "live-ui-sidebar-item--state-stalled"
    end
  end

  # ---------------------------------------------------------------------------
  # Renderer dispatch tests (Stage 3 → Stage 4 wiring)
  # ---------------------------------------------------------------------------

  describe "Renderer dispatches :sidebar_item to LiveUi.Widgets.SidebarItem" do
    test "renderer produces true-widget attr (not component-kind fallback) for sidebar_item IUR" do
      element = Components.sidebar_item("Docs", [], id: "sb-render-1")
      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-widget="sidebar-item")
      refute html =~ ~s(data-live-ui-component-kind="sidebar_item")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end

    test "renderer propagates label and selected? from IUR element" do
      element =
        Components.sidebar_item("Specs", [], id: "sb-render-2", selected?: true)

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "Specs"
      assert html =~ ~s(aria-current="page")
    end

    test "renderer propagates avatar_url from IUR element" do
      element =
        Components.sidebar_item("Alice", [],
          id: "sb-render-3",
          avatar_url: "https://example.com/alice.png"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "live-ui-sidebar-item__avatar"
      assert html =~ "https://example.com/alice.png"
    end

    test "renderer propagates item_state from IUR element" do
      element =
        Components.sidebar_item(
          "Blocked",
          [],
          id: "sb-render-4",
          item_state: :blocked
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-item-state="blocked")
      assert html =~ "live-ui-sidebar-item--state-blocked"
    end
  end
end
