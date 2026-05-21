defmodule LiveUi.Widgets.SidebarSectionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widgets.SidebarSection
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Widgets.Components

  describe "metadata" do
    test "is a layer shell widget exposed through the family registry" do
      metadata = Component.metadata(SidebarSection)

      assert metadata.mountable?
      assert metadata.component_module == SidebarSection.Component
      assert metadata.family == :layer_shell_and_callout
      assert metadata.name == :sidebar_section
      assert metadata.events == [:change]
      assert SidebarSection in LiveUi.Widgets.LayerShellAndCallout.modules()
      assert SidebarSection in LiveUi.Widgets.layer_shell_and_callout_modules()
      assert SidebarSection in LiveUi.Widgets.modules()
    end
  end

  describe "component rendering" do
    test "renders a non-collapsible section as a static heading" do
      html =
        render_component(&SidebarSection.component/1, %{
          id: "section-docs",
          label: "Documentation"
        })

      assert html =~ "<h3"
      assert html =~ "Documentation"
      refute html =~ ~s(role="button")
      refute html =~ "aria-expanded"
      refute html =~ "phx-click"
    end

    test "renders action attributes only when the renderer supplies them" do
      html =
        render_component(&SidebarSection.component/1, %{
          id: "section-with-action",
          label: "Projects",
          action_intent: :new_project,
          action_label: "New",
          action_attrs: %{:"phx-click" => "canonical_interaction"}
        })

      assert html =~ "live-ui-sidebar-section-action"
      assert html =~ "New"
      assert html =~ ~s(phx-click="canonical_interaction")
    end

    test "renders a collapsible expanded section without owning LiveView events" do
      html =
        render_component(&SidebarSection.component/1, %{
          id: "collapsible-section",
          label: "Specs",
          collapsible?: true,
          expanded?: true
        })

      assert html =~ ~s(role="button")
      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(aria-controls="collapsible-section-body")
      assert html =~ ~s(id="collapsible-section-body")
      assert html =~ "live-ui-sidebar-section-indicator"
      refute html =~ "<h3"
      refute html =~ "phx-click"
      refute html =~ "ui_relationship_toggle_section"
    end

    test "renders supplied toggle attributes at the button boundary" do
      html =
        render_component(&SidebarSection.component/1, %{
          id: "toggle-section",
          label: "Specs",
          collapsible?: true,
          expanded?: true,
          toggle_attrs: %{
            :"phx-click" => "canonical_change_interaction",
            :"phx-value-expanded" => "false"
          }
        })

      assert html =~ ~s(phx-click="canonical_change_interaction")
      assert html =~ ~s(phx-value-expanded="false")
    end

    test "renders a collapsed section body with hidden state" do
      html =
        render_component(&SidebarSection.component/1, %{
          id: "collapsed-section",
          label: "Advanced",
          collapsible?: true,
          expanded?: false
        })

      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "live-ui-sidebar-section-body--collapsed"
    end
  end

  describe "canonical constructor shape" do
    test "keeps collapsible state in section attributes" do
      element =
        Components.sidebar_section("Docs", [],
          id: "s1",
          collapsible?: true,
          expanded?: false
        )

      assert get_in(element.attributes, [:section, :label]) == "Docs"
      assert get_in(element.attributes, [:section, :collapsible?]) == true
      assert get_in(element.attributes, [:section, :expanded?]) == false
    end

    test "does not persist renderer event names as canonical attributes" do
      element =
        Components.sidebar_section("Docs", [],
          id: "s2",
          collapsible?: true,
          on_toggle: "ui_relationship_toggle_section"
        )

      refute Map.has_key?(element.attributes.section, :on_toggle)
    end

    test "adds a semantic change interaction for collapsible sections" do
      element = Components.sidebar_section("Docs", [], id: "s3", collapsible?: true)

      assert [%Interaction{family: :change, intent: :toggle_sidebar_section} = interaction] =
               element.attributes.interactions

      assert interaction.source == %{element_id: "s3"}
      assert interaction.target == %{entity: "s3"}
      assert interaction.payload == %{mapping: %{expanded?: :expanded}}
    end

    test "preserves explicit interaction descriptors" do
      interaction =
        Interaction.change(
          intent: :toggle_docs,
          element_id: "s4",
          entity: "docs",
          mapping: %{expanded?: :expanded}
        )

      element =
        Components.sidebar_section("Docs", [],
          id: "s4",
          collapsible?: true,
          interactions: [interaction]
        )

      assert element.attributes.interactions == [interaction]
    end
  end

  describe "renderer integration" do
    test "renders non-collapsible sidebar sections without change transport" do
      element = Components.sidebar_section("Overview", [], id: "render-static")

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ "Overview"
      assert html =~ "live-ui-sidebar-section"
      refute html =~ "aria-expanded"
      refute html =~ "phx-click"
    end

    test "maps canonical change interaction to LiveView transport at the renderer boundary" do
      element =
        Components.sidebar_section("Collapsible", [],
          id: "render-collapsible",
          collapsible?: true,
          expanded?: true
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#screen"
        })

      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(phx-click="canonical_change_interaction")
      assert html =~ ~s(phx-target="#screen")
      assert html =~ ~s(phx-value-widget="sidebar_section")
      assert html =~ ~s(phx-value-element_id="render-collapsible")
      assert html =~ ~s(phx-value-expanded="false")
      refute html =~ "ui_relationship_toggle_section"
    end

    test "does not emit change transport without a runtime event target" do
      element =
        Components.sidebar_section("Collapsible", [],
          id: "render-no-target",
          collapsible?: true,
          expanded?: true
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      refute html =~ ~s(phx-click="canonical_change_interaction")
    end

    test "keeps action interactions on the section action button" do
      element =
        Components.sidebar_section("Actions", [],
          id: "render-action",
          action_intent: :new_item,
          action_label: "New",
          interaction:
            Interaction.click(
              intent: :new_item,
              element_id: "render-action"
            )
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#screen"
        })

      assert html =~ "live-ui-sidebar-section-action"
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#screen")
      assert html =~ ~s(phx-value-widget="sidebar_section")
    end
  end
end
