defmodule LiveUi.DocRightRailTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components
  alias LiveUi.Renderer

  describe "LiveUi.Widgets.DocRightRail metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.DocRightRail)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.DocRightRail.Component
      assert metadata.family == :navigation
      assert metadata.name == :doc_right_rail
    end
  end

  describe "Stage-4 Phoenix.Component rendering" do
    test "renders with data-live-ui-widget attribute" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-test",
          doc_id: "doc-abc",
          on_tab_change: "tab_changed"
        })

      assert html =~ ~s(data-live-ui-widget="doc-right-rail")
    end

    test "renders aside element with correct doc identity attribute" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-doc",
          doc_id: "doc-xyz",
          on_tab_change: "tab_changed"
        })

      assert html =~ ~s(data-doc-id="doc-xyz")
    end

    test "renders default three-tab strip when no tabs supplied" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-tabs",
          doc_id: "doc-1",
          on_tab_change: "tab_changed"
        })

      assert html =~ "Agents"
      assert html =~ "Sources"
      assert html =~ "History"
    end

    test "tab strip has tablist role and tab buttons have correct ARIA" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-aria",
          doc_id: "doc-1",
          on_tab_change: "tab_changed",
          active_tab: :sources
        })

      assert html =~ ~s(role="tablist")
      assert html =~ ~s(role="tab")
      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(aria-selected="false")
    end

    test "sets data-active-tab to reflect active_tab assign" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-active",
          doc_id: "doc-2",
          on_tab_change: "tab_changed",
          active_tab: :history
        })

      assert html =~ ~s(data-active-tab="history")
    end

    test "renders aside with aria-label for landmark" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-landmark",
          doc_id: "doc-3",
          on_tab_change: "tab_changed"
        })

      assert html =~ ~s(aria-label="Document companion panel")
    end

    test "renders body panel with tabpanel role" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-panel",
          doc_id: "doc-4",
          on_tab_change: "tab_changed",
          active_tab: :sources
        })

      assert html =~ ~s(role="tabpanel")
    end

    test "renders collapsed state as data attribute" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-collapsed",
          doc_id: "doc-5",
          on_tab_change: "tab_changed",
          collapsed?: true
        })

      assert html =~ ~s(data-collapsed="true")
    end

    test "renders width_variant as data attribute" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-width",
          doc_id: "doc-6",
          on_tab_change: "tab_changed",
          width_variant: :compact
        })

      assert html =~ ~s(data-width-variant="compact")
    end

    test "renders position as data attribute" do
      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-pos",
          doc_id: "doc-7",
          on_tab_change: "tab_changed",
          position: :sticky_top
        })

      assert html =~ ~s(data-position="sticky_top")
    end

    test "renders tab count badge when count is provided" do
      tabs = [
        %{kind: :agents, label: "Agents", count: 5},
        %{kind: :sources, label: "Sources", count: nil},
        %{kind: :history, label: "History", count: nil}
      ]

      html =
        render_component(&LiveUi.Widgets.DocRightRail.component/1, %{
          id: "rail-count",
          doc_id: "doc-8",
          on_tab_change: "tab_changed",
          tabs: tabs
        })

      assert html =~ "5"
      assert html =~ ~s(aria-label=", 5 items")
    end
  end

  describe "Stage-3 renderer clause" do
    test "doc_right_rail kind is in renderer supported_kinds" do
      assert :doc_right_rail in Renderer.supported_kinds()
    end

    test "renderer renders doc_right_rail element via dedicated clause" do
      element = Components.doc_right_rail(doc_id: "doc-r", on_tab_change: "tab_changed")

      html = render_component(&Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-widget="doc-right-rail")
      assert html =~ "Agents"
      assert html =~ "Sources"
      assert html =~ "History"
    end

    test "renderer does NOT use the generic component-kinds fallback for doc_right_rail" do
      element = Components.doc_right_rail(doc_id: "doc-r", on_tab_change: "tab_changed")

      html = render_component(&Renderer.render/1, %{element: element})

      # Should have the actual widget attr, not the fallback component-kind attr
      assert html =~ ~s(data-live-ui-widget="doc-right-rail")
      refute html =~ ~s(data-live-ui-component-kind="doc_right_rail")
    end
  end
end
