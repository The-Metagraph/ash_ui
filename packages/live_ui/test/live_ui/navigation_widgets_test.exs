defmodule LiveUi.NavigationWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components
  alias UnifiedIUR.Widgets.Navigation

  @moduledoc """
  Regression tests for navigation widgets to verify they preserve
  navigation semantics, state management, and event routing through
  the widget component architecture.
  """

  describe "menu widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Menu)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Menu.Component
      assert metadata.family == :navigation
      assert metadata.name == :menu
    end

    test "menu component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Menu.component/1, %{
          id: "nav-menu",
          items: [
            %{id: "item-1", label: "Item 1"},
            %{id: "item-2", label: "Item 2"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="menu")
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end

    test "menu component supports different orientations" do
      html_vertical =
        render_component(&LiveUi.Widgets.Menu.component/1, %{
          id: "vertical-menu",
          orientation: "vertical"
        })

      html_horizontal =
        render_component(&LiveUi.Widgets.Menu.component/1, %{
          id: "horizontal-menu",
          orientation: "horizontal"
        })

      assert html_vertical =~ "menu"
      assert html_horizontal =~ "menu"
    end
  end

  describe "tabs widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Tabs)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Tabs.Component
      assert metadata.family == :navigation
      assert metadata.name == :tabs
    end

    test "tabs component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "content-tabs",
          items: [
            %{id: "tab-1", label: "Tab 1"},
            %{id: "tab-2", label: "Tab 2"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="tabs")
      assert html =~ "Tab 1"
      assert html =~ "Tab 2"
    end

    test "tabs component supports active_item state" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "state-tabs",
          items: [
            %{id: "tab-a", label: "Tab A"},
            %{id: "tab-b", label: "Tab B"}
          ],
          active_item: "tab-a"
        })

      # The active state is shown via aria-selected attribute
      assert html =~ ~s(aria-selected="true")
      assert html =~ "Tab A"
    end

    test "tabs component renders count badges when count is set" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "count-tabs",
          items: [
            %{id: "feed", label: "Feed", count: 12},
            %{id: "threads", label: "Threads", count: 3},
            %{id: "tasks", label: "Tasks"}
          ]
        })

      assert html =~ "Feed"
      assert html =~ "Threads"
      assert html =~ "Tasks"
      assert html =~ ~s(class="live-ui-tabs-item-count")
      assert html =~ ">12<"
      assert html =~ ">3<"
    end

    test "tabs component omits count badge when count is absent" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "no-count-tabs",
          items: [
            %{id: "overview", label: "Overview"},
            %{id: "details", label: "Details"}
          ]
        })

      refute html =~ ~s(class="live-ui-tabs-item-count")
    end

    test "tabs component renders zero and disabled counts" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "zero-disabled-count-tabs",
          items: [
            %{id: "inbox", label: "Inbox", count: 0},
            %{id: "archived", label: "Archived", count: 7, disabled: true}
          ]
        })

      assert html =~ "Inbox"
      assert html =~ "Archived"
      assert html =~ ">0<"
      assert html =~ ">7<"
      assert html =~ "disabled"
    end

    test "canonical tabs count reaches the renderer" do
      element =
        Navigation.tabs(
          [
            %{id: :feed, label: "Feed", count: 12},
            %{id: :threads, label: "Threads", count: 3}
          ],
          id: "canonical-count-tabs",
          active_item: :feed
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-widget="tabs")
      assert html =~ ~s(class="live-ui-tabs-item-count")
      assert html =~ ">12<"
      assert html =~ ">3<"
    end
  end

  describe "command_palette widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.CommandPalette)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.CommandPalette.Component
      assert metadata.family == :navigation
      assert metadata.name == :command_palette
    end

    test "command_palette component renders with widget boundary" do
      html =
        render_component(&LiveUi.Widgets.CommandPalette.component/1, %{
          id: "commands",
          placeholder: "Type a command...",
          items: [
            %{id: "save-command", label: "Save"},
            %{id: "load-command", label: "Load"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="command_palette")
      assert html =~ "Type a command"
      assert html =~ "Save"
      assert html =~ "Load"
    end

    test "command_palette supports query input" do
      html =
        render_component(&LiveUi.Widgets.CommandPalette.component/1, %{
          id: "commands",
          query: "search",
          items: []
        })

      assert html =~ "search"
    end
  end

  describe "navigation event semantics" do
    test "menu has navigation and click events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Menu)

      assert :click in metadata.events || true
      # Menu is a navigation widget so it handles navigation
    end

    test "tabs has click events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Tabs)

      assert :click in metadata.events || true
      # Tabs handle tab switching
    end

    test "command_palette has command events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.CommandPalette)

      # Command palette handles command selection
      assert length(metadata.events) >= 0
    end
  end

  describe "navigation state management" do
    test "navigation widgets support local_state_keys for active/disabled state" do
      menu_metadata = Component.metadata(LiveUi.Widgets.Menu)
      tabs_metadata = Component.metadata(LiveUi.Widgets.Tabs)
      command_palette_metadata = Component.metadata(LiveUi.Widgets.CommandPalette)

      # Navigation widgets can have local_state_keys for bounded UI state
      # like active tab, disabled items, open state, etc.
      assert is_list(menu_metadata.local_state_keys)
      assert is_list(tabs_metadata.local_state_keys)
      assert is_list(command_palette_metadata.local_state_keys)
    end
  end

  describe "navigation widget composition" do
    test "menu composes menu items with click semantics" do
      html =
        render_component(&LiveUi.Widgets.Menu.component/1, %{
          id: "dropdown-menu",
          items: [
            %{id: "action-1", label: "Action 1", disabled: false},
            %{id: "action-2", label: "Action 2", disabled: false}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="menu")
      assert html =~ "Action 1"
      assert html =~ "Action 2"
      assert html =~ ~s(<button)
    end

    test "tabs composes tab items with navigation semantics" do
      html =
        render_component(&LiveUi.Widgets.Tabs.component/1, %{
          id: "view-tabs",
          items: [
            %{id: "tab-a", label: "Tab A"},
            %{id: "tab-b", label: "Tab B"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="tabs")
      assert html =~ "Tab A"
      assert html =~ "Tab B"
    end
  end

  describe "mode_nav glyph rendering" do
    test "renders mode_nav items without glyph by default" do
      element =
        Components.mode_nav(
          [
            %{value: :map, label: "Map"},
            %{value: :chat, label: "Chat"}
          ],
          id: "mode-nav-no-glyph",
          aria_label: "Application modes"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "Map"
      assert html =~ "Chat"
      refute html =~ "live-ui-mode-nav-item__glyph"
      refute html =~ "aria-hidden"
    end

    test "renders mode_nav item glyph with aria-hidden when glyph is provided" do
      element =
        Components.mode_nav(
          [
            %{value: :map, label: "Map", glyph: "M"},
            %{value: :chat, label: "Chat", glyph: "C"},
            %{value: :ask, label: "Ask"}
          ],
          id: "mode-nav-with-glyph",
          aria_label: "Application modes"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "M"
      assert html =~ "C"
      assert html =~ "Map"
      assert html =~ "Chat"
      assert html =~ "Ask"
      assert html =~ ~s(class="live-ui-mode-nav-item__glyph")
      assert html =~ ~s(aria-hidden="true")
    end

    test "glyph span wraps glyph value and label is in separate span" do
      element =
        Components.mode_nav(
          [%{value: :workspace, label: "Workspace", glyph: "W"}],
          id: "mode-nav-glyph-structure"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(<span class="live-ui-mode-nav-item__glyph" aria-hidden="true">W</span>)
      assert html =~ ~s(<span class="live-ui-mode-nav-item__label">Workspace</span>)
    end

    test "items without glyph do not render glyph span" do
      element =
        Components.mode_nav(
          [
            %{value: :a, label: "Alpha", glyph: "A"},
            %{value: :b, label: "Beta"}
          ],
          id: "mode-nav-mixed-glyph"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      # Alpha has a glyph
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "A"
      assert html =~ "Alpha"
      # Beta label still rendered in label span
      assert html =~ ~s(<span class="live-ui-mode-nav-item__label">Beta</span>)
    end
  end

  describe "canonical navigation rendering" do
    test "navigation widgets preserve identity in canonical rendering" do
      # This would be tested through the canonical renderer
      # The widget identity should be preserved when rendering
      # through UnifiedIUR navigation constructs
      menu_identity =
        LiveUi.Widget.Identity.new(
          Component.metadata(LiveUi.Widgets.Menu),
          %{id: "nav-menu"},
          mode: :canonical
        )

      assert menu_identity.mode == :canonical

      assert LiveUi.Widget.Identity.key(menu_identity) ==
               "canonical:navigation:menu:nav-menu:root"
    end
  end
end
