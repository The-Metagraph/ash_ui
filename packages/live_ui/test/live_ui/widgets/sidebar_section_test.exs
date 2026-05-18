defmodule LiveUi.Widgets.SidebarSectionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  @moduledoc """
  Tests for LiveUi.Widgets.SidebarSection — the collapsible sidebar section widget.

  Covers:
  - Widget metadata: family, name, mountable boundary
  - Non-collapsible (default): label in <h3>, no toggle button, no aria-expanded
  - Non-collapsible with action_intent: action button rendered
  - Collapsible + expanded: toggle button with aria-expanded="true", ▼ chevron
  - Collapsible + collapsed: toggle button with aria-expanded="false", ▶ chevron
  - ARIA: aria-controls linkage between toggle button and section body
  - aria-hidden on section body when collapsible? is true
  - Section body id derivation from parent id
  - Renderer IUR integration: sidebar_section constructor → renderer
  - IUR constructor new props: collapsible?, expanded?, on_toggle
  """

  describe "SidebarSection widget metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.SidebarSection)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.SidebarSection.Component
      assert metadata.name == :sidebar_section
    end

    test "family is navigation (layer-shell navigation widget)" do
      metadata = Component.metadata(LiveUi.Widgets.SidebarSection)

      assert metadata.family == :navigation
    end

    test "toggle event is declared" do
      metadata = Component.metadata(LiveUi.Widgets.SidebarSection)

      assert :toggle in metadata.events
    end
  end

  describe "non-collapsible mode (collapsible?: false, default)" do
    test "renders label in <h3>, no toggle button" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-docs",
          label: "Documentation"
        })

      assert html =~ "<h3"
      assert html =~ "Documentation"
      refute html =~ ~s(role="button")
      refute html =~ "aria-expanded"
    end

    test "data-live-ui-collapsible attribute absent when not collapsible" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-settings",
          label: "Settings"
        })

      # Phoenix renders boolean false attrs as absent (not "false")
      refute html =~ ~s(data-live-ui-collapsible="true")
    end

    test "section body has no aria-hidden when not collapsible" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-nav",
          label: "Navigation"
        })

      refute html =~ "aria-hidden"
    end

    test "action button rendered when action_intent provided" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-with-action",
          label: "Projects",
          action_intent: "new_project",
          action_label: "New"
        })

      assert html =~ "live-ui-sidebar-section-action"
      assert html =~ "New"
    end

    test "action glyph used as fallback label when action_label absent" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-glyph",
          label: "Workspaces",
          action_intent: "new_workspace",
          action_glyph: "+"
        })

      assert html =~ "+"
    end

    test "no action button when action_intent is nil" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "section-no-action",
          label: "Workspaces"
        })

      refute html =~ "live-ui-sidebar-section-action"
    end
  end

  describe "collapsible + expanded mode (collapsible?: true, expanded?: true)" do
    test "renders toggle button with role=button, not <h3>" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "collapsible-section",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(role="button")
      refute html =~ "<h3"
    end

    test "aria-expanded is true when expanded" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "expanded-section",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(aria-expanded="true")
    end

    test "shows ▼ chevron when expanded" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "chevron-expanded",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ "▼"
      refute html =~ "▶"
    end

    test "section body does NOT have collapsed class when expanded" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "body-expanded",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      refute html =~ "live-ui-sidebar-section-body--collapsed"
    end

    test "section body aria-hidden is false when expanded" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "aria-expanded",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(aria-hidden="false")
    end
  end

  describe "collapsible + collapsed mode (collapsible?: true, expanded?: false)" do
    test "aria-expanded is false when collapsed" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "collapsed-section",
          label: "Advanced",
          collapsible?: true,
          expanded?: false
        })

      assert html =~ ~s(aria-expanded="false")
    end

    test "shows ▶ chevron when collapsed" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "chevron-collapsed",
          label: "Advanced",
          collapsible?: true,
          expanded?: false
        })

      assert html =~ "▶"
      refute html =~ "▼"
    end

    test "section body has collapsed class when collapsed" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "body-collapsed",
          label: "Advanced",
          collapsible?: true,
          expanded?: false
        })

      assert html =~ "live-ui-sidebar-section-body--collapsed"
    end

    test "section body aria-hidden is true when collapsed" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "aria-collapsed",
          label: "Advanced",
          collapsible?: true,
          expanded?: false
        })

      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "ARIA disclosure pattern linkage" do
    test "toggle button aria-controls matches section body id" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "aria-linked-section",
          label: "Linked",
          collapsible?: true,
          expanded?: true
        })

      # section body id is "{parent_id}-body"
      assert html =~ ~s(aria-controls="aria-linked-section-body")
      assert html =~ ~s(id="aria-linked-section-body")
    end

    test "data-live-ui-collapsible attribute present when collapsible" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "collapsible-data",
          label: "Collapsible",
          collapsible?: true,
          expanded?: true
        })

      # Phoenix renders boolean true as presence-only (no ="true")
      assert html =~ "data-live-ui-collapsible"
    end
  end

  describe "on_toggle event routing" do
    test "uses default phx-click event when on_toggle not supplied" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "default-toggle",
          label: "Section",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(phx-click="ui_relationship_toggle_section")
    end

    test "uses custom on_toggle event when supplied" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "custom-toggle",
          label: "Section",
          collapsible?: true,
          expanded?: true,
          on_toggle: "my_custom_toggle"
        })

      assert html =~ ~s(phx-click="my_custom_toggle")
      refute html =~ ~s(phx-click="ui_relationship_toggle_section")
    end

    test "phx-value-section-id carries the section element id" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "target-toggle",
          label: "Section",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(phx-value-section-id="target-toggle")
    end
  end

  describe "widget boundary" do
    test "data-live-ui-widget-boundary present when rendered via component/1" do
      html =
        render_component(&LiveUi.Widgets.SidebarSection.component/1, %{
          id: "boundary-section",
          label: "Boundary"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="sidebar_section")
    end
  end

  describe "IUR constructor collapsible? / expanded? / on_toggle props" do
    test "collapsible? defaults to false in constructor" do
      element = Components.sidebar_section("Docs", [], id: "s1")

      assert get_in(element.attributes, [:section, :collapsible?]) == false
    end

    test "expanded? defaults to true in constructor" do
      element = Components.sidebar_section("Docs", [], id: "s1")

      assert get_in(element.attributes, [:section, :expanded?]) == true
    end

    test "on_toggle is absent when not supplied" do
      element = Components.sidebar_section("Docs", [], id: "s1")

      refute Map.has_key?(element.attributes.section, :on_toggle)
    end

    test "collapsible? opt round-trips through constructor" do
      element = Components.sidebar_section("Docs", [], id: "s2", collapsible?: true)

      assert get_in(element.attributes, [:section, :collapsible?]) == true
    end

    test "expanded?: false round-trips through constructor" do
      element =
        Components.sidebar_section("Docs", [],
          id: "s3",
          collapsible?: true,
          expanded?: false
        )

      assert get_in(element.attributes, [:section, :expanded?]) == false
    end

    test "on_toggle round-trips through constructor when supplied" do
      element =
        Components.sidebar_section("Docs", [],
          id: "s4",
          on_toggle: "my_event"
        )

      assert get_in(element.attributes, [:section, :on_toggle]) == "my_event"
    end
  end

  describe "renderer IUR integration" do
    test "renderer renders non-collapsible sidebar_section with <h3> label" do
      element = Components.sidebar_section("Overview", [], id: "render-static")

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "Overview"
      assert html =~ "live-ui-sidebar-section"
      refute html =~ "aria-expanded"
    end

    test "renderer renders collapsible sidebar_section with toggle button" do
      element =
        Components.sidebar_section("Collapsible", [],
          id: "render-collapsible",
          collapsible?: true,
          expanded?: true
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "Collapsible"
      assert html =~ ~s(aria-expanded="true")
      # Phoenix renders boolean true as presence-only attribute
      assert html =~ "data-live-ui-collapsible"
    end

    test "renderer renders collapsed section with aria-expanded=false" do
      element =
        Components.sidebar_section("Hidden", [],
          id: "render-collapsed",
          collapsible?: true,
          expanded?: false
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(aria-expanded="false")
      assert html =~ "live-ui-sidebar-section-body--collapsed"
    end
  end
end
