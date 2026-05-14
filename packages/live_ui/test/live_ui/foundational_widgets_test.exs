defmodule LiveUi.FoundationalWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Component.Metadata
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for foundational widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "foundational content widgets" do
    test "text widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Text)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Text.Component
      assert metadata.family == :content
      assert metadata.name == :text
      assert :content in metadata.assigns
    end

    test "text widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Text.component/1, %{
          id: "test-text",
          content: "Hello World"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="text")
      assert html =~ ~s(data-live-ui-widget-key="native:content:text:test-text:root")
      assert html =~ "Hello World"
    end

    test "label widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Label)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Label.Component
      assert metadata.family == :content
      assert metadata.name == :label
    end

    test "label widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Label.component/1, %{
          id: "test-label",
          for: "input-id",
          content: "Label Text"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="label")
      assert html =~ ~s(data-live-ui-widget-key="native:content:label:test-label:root")
      assert html =~ "Label Text"
      assert html =~ ~s(for="input-id")
    end

    test "image widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Image)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Image.Component
      assert metadata.family == :content
      assert metadata.name == :image
    end

    test "image widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Image.component/1, %{
          id: "test-image",
          src: "/test.png",
          alt: "Test Image"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="image")
      assert html =~ ~s(data-live-ui-widget-key="native:content:image:test-image:root")
      assert html =~ ~s(src="/test.png")
      assert html =~ ~s(alt="Test Image")
    end

    test "icon widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Icon)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Icon.Component
      assert metadata.family == :content
      assert metadata.name == :icon
    end

    test "icon widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Icon.component/1, %{
          id: "test-icon",
          name: :star
        })

      assert html =~ ~s(data-live-ui-widget-boundary="icon")
      assert html =~ ~s(data-live-ui-widget-key="native:content:icon:test-icon:root")
      assert html =~ ~s(data-live-ui-icon="star")
    end

    test "button widget has mountable component boundary with click event" do
      metadata = Component.metadata(LiveUi.Widgets.Button)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Button.Component
      assert metadata.family == :content
      assert metadata.name == :button
      assert :click in metadata.events
    end

    test "button widget component renders with widget boundary attributes and click event" do
      html =
        render_component(&LiveUi.Widgets.Button.component/1, %{
          id: "test-button",
          label: "Click Me"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="button")
      assert html =~ ~s(data-live-ui-widget-key="native:content:button:test-button:root")
      assert html =~ "Click Me"
      # Button has click event defined in metadata
      assert :click in Component.metadata(LiveUi.Widgets.Button).events
    end

    test "button component preserves tone and variant styling" do
      html =
        render_component(&LiveUi.Widgets.Button.component/1, %{
          id: "styled-button",
          label: "Styled",
          tone: "primary",
          variant: "solid"
        })

      assert html =~ ~s(data-live-ui-tone="primary")
      assert html =~ ~s(data-live-ui-variant="solid")
    end

    test "link widget has mountable component boundary with click and navigate events" do
      metadata = Component.metadata(LiveUi.Widgets.Link)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Link.Component
      assert metadata.family == :content
      assert metadata.name == :link
      assert :click in metadata.events
      assert :navigate in metadata.events
    end

    test "link widget component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Link.component/1, %{
          id: "test-link",
          label: "Link Text",
          href: "/test"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="link")
      assert html =~ ~s(data-live-ui-widget-key="native:content:link:test-link:root")
      assert html =~ "Link Text"
      assert html =~ ~s(href="/test")
    end
  end

  describe "foundational container widgets" do
    test "content widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Content)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Content.Component
      assert metadata.family == :content
      assert metadata.name == :content
    end

    test "content widget component renders with inner_block slot" do
      html =
        render_component(&LiveUi.Widgets.Content.component/1, %{
          id: "test-content",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> Phoenix.HTML.raw("Nested content") end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="content")
      assert html =~ ~s(data-live-ui-widget-key="native:content:content:test-content:root")
      assert html =~ "Nested content"
    end

    test "container widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Container)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Container.Component
      assert metadata.family == :layout
      assert metadata.name == :container
    end

    test "container widget component renders with inner_block" do
      html =
        render_component(&LiveUi.Widgets.Container.component/1, %{
          id: "test-container",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> Phoenix.HTML.raw("Container content") end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="container")
      assert html =~ "Container content"
    end

    test "box widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Box)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Box.Component
      assert metadata.family == :layout
      assert metadata.name == :box
    end

    test "box widget component renders with padding and inner_block" do
      html =
        render_component(&LiveUi.Widgets.Box.component/1, %{
          id: "test-box",
          padding: "lg",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> Phoenix.HTML.raw("Boxed content") end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ "Boxed content"
    end

    test "screen_shell widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ScreenShell)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ScreenShell.Component
      assert metadata.family == :layout
      assert metadata.name == :screen_shell
    end

    test "screen_shell component renders with title and inner_block" do
      html =
        render_component(&LiveUi.Widgets.ScreenShell.component/1, %{
          id: "test-screen",
          title: "Test Screen",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ -> Phoenix.HTML.raw("Screen content") end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="screen_shell")
      assert html =~ "Test Screen"
      assert html =~ "Screen content"
    end

    test "separator widget has component boundary (structural)" do
      metadata = Component.metadata(LiveUi.Widgets.Separator)

      # Separator is structural, not interactive
      refute Component.interactive?(LiveUi.Widgets.Separator)
      assert Component.structural?(LiveUi.Widgets.Separator)
    end

    test "separator component renders with orientation" do
      # Separator uses function component, not LiveComponent
      html =
        render_component(&LiveUi.Widgets.Separator.render/1, %{
          id: "test-separator",
          orientation: "horizontal"
        })

      assert html =~ "separator"
    end

    test "spacer widget has component boundary (structural)" do
      metadata = Component.metadata(LiveUi.Widgets.Spacer)

      # Spacer is structural, not interactive
      refute Component.interactive?(LiveUi.Widgets.Spacer)
      assert Component.structural?(LiveUi.Widgets.Spacer)
    end

    test "spacer component renders with size" do
      # Spacer uses function component, not LiveComponent
      html =
        render_component(&LiveUi.Widgets.Spacer.render/1, %{
          id: "test-spacer",
          size: "md"
        })

      assert html =~ "spacer"
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Text),
          %{id: "stable-text"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Text),
          %{id: "stable-text"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:content:text:stable-text:root"
    end

    test "widget identity includes mode in key" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Button),
          %{id: "mode-button"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Button),
          %{id: "mode-button"},
          mode: :canonical
        )

      assert Identity.key(native_identity) == "native:content:button:mode-button:root"
      assert Identity.key(canonical_identity) == "canonical:content:button:mode-button:root"
    end

    test "widget identity includes path for nested widgets" do
      nested_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Text),
          %{id: "nested-text"},
          path: ["container", "row"]
        )

      assert Identity.key(nested_identity) == "native:content:text:nested-text:container/row"
    end
  end

  describe "nested widget composition" do
    test "container can nest multiple content widgets" do
      html =
        render_component(&LiveUi.Widgets.Container.component/1, %{
          id: "outer-container",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw("""
                #{render_component(&LiveUi.Widgets.Text.component/1, %{id: "text-1", content: "First"})}
                #{render_component(&LiveUi.Widgets.Text.component/1, %{id: "text-2", content: "Second"})}
                """)
              end
            }
          ]
        })

      assert html =~ "First"
      assert html =~ "Second"
      # Both text widgets should have their own boundaries
      assert html =~ ~s(data-live-ui-widget-key="native:content:text:text-1:root")
      assert html =~ ~s(data-live-ui-widget-key="native:content:text:text-2:root")
    end

    test "box can nest content and preserve styling" do
      html =
        render_component(&LiveUi.Widgets.Box.component/1, %{
          id: "styled-box",
          tone: "surface",
          padding: "lg",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                render_component(&LiveUi.Widgets.Text.component/1, %{id: "inner-text", content: "Boxed"})
              end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-tone="surface")
      assert html =~ "Boxed"
    end
  end

  describe "event semantics preservation" do
    test "button component has click event in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Button)

      assert :click in metadata.events
    end

    test "button component disabled state is preserved" do
      html =
        render_component(&LiveUi.Widgets.Button.component/1, %{
          id: "disabled-button",
          label: "Disabled",
          disabled: true
        })

      assert html =~ ~s(disabled)
    end

    test "link component has click and navigate events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Link)

      assert :click in metadata.events
      assert :navigate in metadata.events
    end

    test "link component renders with href" do
      html =
        render_component(&LiveUi.Widgets.Link.component/1, %{
          id: "nav-link",
          label: "Navigate",
          href: "/target"
        })

      assert html =~ ~s(href="/target")
    end
  end
end
