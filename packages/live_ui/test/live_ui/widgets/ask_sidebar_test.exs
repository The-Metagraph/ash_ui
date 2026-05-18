defmodule LiveUi.Widgets.AskSidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  # ---------------------------------------------------------------------------
  # Component metadata
  # ---------------------------------------------------------------------------

  describe "component metadata" do
    test "has the ask_sidebar name" do
      metadata = Component.metadata(LiveUi.Widgets.AskSidebar)
      assert metadata.name == :ask_sidebar
    end

    test "is in the overlay family" do
      metadata = Component.metadata(LiveUi.Widgets.AskSidebar)
      assert metadata.family == :overlay
    end

    test "is mountable" do
      metadata = Component.metadata(LiveUi.Widgets.AskSidebar)
      assert metadata.mountable?
    end

    test "declares click events" do
      metadata = Component.metadata(LiveUi.Widgets.AskSidebar)
      assert :click in metadata.events
    end
  end

  # ---------------------------------------------------------------------------
  # Render: structural attributes
  # ---------------------------------------------------------------------------

  describe "render/1 structural HTML" do
    test "renders with data-live-ui-widget=ask-sidebar" do
      html = render_empty()
      assert html =~ ~s(data-live-ui-widget="ask-sidebar")
    end

    test "renders with data-sidebar-id" do
      html = render_empty()
      assert html =~ ~s(data-sidebar-id="sb-main")
    end

    test "renders aside element with aria-label=Ask sidebar" do
      html = render_empty()
      assert html =~ ~s(aria-label="Ask sidebar")
    end

    test "renders scroll wrapper" do
      html = render_empty()
      assert html =~ "live-ui-ask-sidebar__scroll"
    end
  end

  # ---------------------------------------------------------------------------
  # Render: Recent rail
  # ---------------------------------------------------------------------------

  describe "render/1 Recent rail" do
    test "renders Recent section with scoped heading id" do
      html = render_empty()
      assert html =~ ~s(id="ask-recent-h-sb-main")
      assert html =~ "Recent"
    end

    test "renders section with aria-labelledby pointing to heading" do
      html = render_empty()
      assert html =~ ~s(aria-labelledby="ask-recent-h-sb-main")
    end

    test "renders empty label when no recent items" do
      html = render_empty()
      assert html =~ "No recent queries"
    end

    test "renders recent items" do
      now = DateTime.utc_now()

      html =
        render_with_recent([
          %{
            id: "r1",
            query: "show blockers",
            last_run_at: now,
            status: :done,
            on_open_event: "open"
          }
        ])

      assert html =~ "show blockers"
    end

    test "renders data-item-id on recent item buttons" do
      now = DateTime.utc_now()

      html =
        render_with_recent([
          %{id: "r1", query: "q1", last_run_at: now, status: :done, on_open_event: "open"}
        ])

      assert html =~ ~s(data-item-id="r1")
    end

    test "caps recent items at 10" do
      now = DateTime.utc_now()

      items =
        for i <- 1..15,
            do: %{
              id: "r#{i}",
              query: "query #{i}",
              last_run_at: now,
              status: :done,
              on_open_event: "open"
            }

      html = render_with_recent(items)
      # item 11 through 15 should not appear
      refute html =~ "query 11"
      assert html =~ "query 10"
    end

    test "renders see-all button when recent > 6 and on_see_all_event provided" do
      now = DateTime.utc_now()

      items =
        for i <- 1..7,
            do: %{
              id: "r#{i}",
              query: "q#{i}",
              last_run_at: now,
              status: :done,
              on_open_event: "open"
            }

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          recent_items: items,
          on_see_all_event: "see_all"
        })

      assert html =~ "see all"
      assert html =~ ~s(data-live-ui-intent="see_all")
    end

    test "does NOT render see-all when recent <= 6" do
      now = DateTime.utc_now()

      items =
        for i <- 1..6,
            do: %{
              id: "r#{i}",
              query: "q#{i}",
              last_run_at: now,
              status: :done,
              on_open_event: "open"
            }

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          recent_items: items,
          on_see_all_event: "see_all"
        })

      refute html =~ "see all"
    end

    test "does NOT render see-all when on_see_all_event is nil" do
      now = DateTime.utc_now()

      items =
        for i <- 1..8,
            do: %{
              id: "r#{i}",
              query: "q#{i}",
              last_run_at: now,
              status: :done,
              on_open_event: "open"
            }

      html = render_with_recent(items)
      refute html =~ "see all"
    end

    test "recent item with status :running renders running status indicator" do
      now = DateTime.utc_now()

      html =
        render_with_recent([
          %{
            id: "r1",
            query: "running q",
            last_run_at: now,
            status: :running,
            on_open_event: "open"
          }
        ])

      assert html =~ "live-ui-ask-sidebar__status-running"
      assert html =~ ~s(aria-label="running")
    end

    test "recent item without :running status does NOT render status indicator" do
      now = DateTime.utc_now()

      html =
        render_with_recent([
          %{id: "r1", query: "done q", last_run_at: now, status: :done, on_open_event: "open"}
        ])

      refute html =~ "live-ui-ask-sidebar__status-running"
    end

    test "uses custom empty_recent_label" do
      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          empty_recent_label: "Nothing yet"
        })

      assert html =~ "Nothing yet"
    end
  end

  # ---------------------------------------------------------------------------
  # Render: Saved rail
  # ---------------------------------------------------------------------------

  describe "render/1 Saved rail" do
    test "renders Saved section with scoped heading id" do
      html = render_empty()
      assert html =~ ~s(id="ask-saved-h-sb-main")
      assert html =~ "Saved"
    end

    test "renders empty label when no saved items" do
      html = render_empty()
      assert html =~ "No saved queries yet"
    end

    test "renders saved items with star glyph" do
      html =
        render_with_saved([
          %{id: "s1", title: "Weekly blockers", query: "q", on_open_event: "open"}
        ])

      assert html =~ "Weekly blockers"
      assert html =~ "&#x2605;"
    end

    test "renders data-item-id on saved item buttons" do
      html = render_with_saved([%{id: "s1", title: "T1", query: "q", on_open_event: "open"}])
      assert html =~ ~s(data-item-id="s1")
    end

    test "renders + new button when on_new_saved_event provided" do
      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          on_new_saved_event: "new_saved"
        })

      assert html =~ "+ new"
      assert html =~ ~s(data-live-ui-intent="new_saved")
    end

    test "does NOT render + new button when on_new_saved_event is nil" do
      html = render_empty()
      refute html =~ "+ new"
    end

    test "saved item uses cadence when present" do
      html =
        render_with_saved([
          %{id: "s1", title: "T1", query: "q", cadence: "weekly", on_open_event: "open"}
        ])

      assert html =~ "weekly"
    end

    test "saved item falls back to relative_time when no cadence" do
      now = DateTime.utc_now()

      html =
        render_with_saved([
          %{id: "s1", title: "T1", query: "q", last_run_at: now, on_open_event: "open"}
        ])

      assert html =~ "just now"
    end

    test "uses custom empty_saved_label" do
      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          empty_saved_label: "No saves yet"
        })

      assert html =~ "No saves yet"
    end
  end

  # ---------------------------------------------------------------------------
  # Render: active item selection
  # ---------------------------------------------------------------------------

  describe "render/1 active item selection" do
    test "active recent item has --active class" do
      now = DateTime.utc_now()
      items = [%{id: "r1", query: "q1", last_run_at: now, status: :done, on_open_event: "open"}]

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          recent_items: items,
          active_item_id: "r1"
        })

      assert html =~ "live-ui-ask-sidebar__item--active"
    end

    test "active recent item has aria-current=true" do
      now = DateTime.utc_now()
      items = [%{id: "r1", query: "q1", last_run_at: now, status: :done, on_open_event: "open"}]

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          recent_items: items,
          active_item_id: "r1"
        })

      assert html =~ ~s(aria-current="true")
    end

    test "inactive items have aria-current=false" do
      now = DateTime.utc_now()
      items = [%{id: "r1", query: "q1", last_run_at: now, status: :done, on_open_event: "open"}]

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          recent_items: items,
          active_item_id: "r99"
        })

      assert html =~ ~s(aria-current="false")
      refute html =~ "live-ui-ask-sidebar__item--active"
    end

    test "active saved item has --active class" do
      items = [%{id: "s1", title: "T1", query: "q", on_open_event: "open"}]

      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          saved_items: items,
          active_item_id: "s1"
        })

      assert html =~ "live-ui-ask-sidebar__item--active"
      assert html =~ ~s(aria-current="true")
    end
  end

  # ---------------------------------------------------------------------------
  # Render: Map jump affordance
  # ---------------------------------------------------------------------------

  describe "render/1 Map jump affordance" do
    test "renders Map jump button with aria-label" do
      html = render_empty()
      assert html =~ ~s(aria-label="Switch to Map mode")
    end

    test "map jump button carries on_map_jump_event as data-live-ui-intent" do
      html = render_empty()
      assert html =~ ~s(data-live-ui-intent="map_jump")
    end

    test "map jump button has data-live-ui-value=map" do
      html = render_empty()
      assert html =~ ~s(data-live-ui-value="map")
    end

    test "renders Map label" do
      html = render_empty()
      assert html =~ "live-ui-ask-sidebar__map-jump-label"
    end

    test "renders blocker badge when blocker_count > 0" do
      html =
        render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
          id: "sb-test",
          sidebar_id: "sb-main",
          on_map_jump_event: "map_jump",
          blocker_count: 4
        })

      assert html =~ "live-ui-ask-sidebar__blocker-badge"
      assert html =~ ~s(aria-label="4 blockers")
      assert html =~ "4"
    end

    test "does NOT render blocker badge when blocker_count is 0" do
      html = render_empty()
      refute html =~ "live-ui-ask-sidebar__blocker-badge"
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp render_empty do
    render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
      id: "sb-test",
      sidebar_id: "sb-main",
      on_map_jump_event: "map_jump"
    })
  end

  defp render_with_recent(items) do
    render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
      id: "sb-test",
      sidebar_id: "sb-main",
      on_map_jump_event: "map_jump",
      recent_items: items
    })
  end

  defp render_with_saved(items) do
    render_component(&LiveUi.Widgets.AskSidebar.component/1, %{
      id: "sb-test",
      sidebar_id: "sb-main",
      on_map_jump_event: "map_jump",
      saved_items: items
    })
  end
end
