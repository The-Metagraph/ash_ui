defmodule LiveUi.Phase12IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.{Component, Runtime}

  @moduledoc """
  End-to-end integration tests for Phase 12 widget migrations.

  Verifies that foundational, input, and navigation widgets work correctly
  together in realistic screen scenarios through the widget component
  architecture.
  """

  defmodule FoundationalInputScreen do
    use LiveUi.Screen, id: :foundational_input_screen, title: "Foundational Input Screen"

    @impl true
    def mount_defaults do
      %{
        email: "",
        accepted_terms: false,
        submit_count: 0
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component
        id="screen-box"
        padding="lg"
        tone="surface"
      >
        <LiveUi.Widgets.Text.component id="title" content="Sign Up" />
        <LiveUi.Widgets.TextInput.component
          id="email-input"
          name="email"
          label="Email"
          placeholder="you@example.com"
        />
        <LiveUi.Widgets.Button.component
          id="submit"
          label="Sign Up"
          tone="primary"
        />
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  defmodule NavigationScreen do
    use LiveUi.Screen, id: :navigation_screen, title: "Navigation Screen"

    @impl true
    def mount_defaults do
      %{
        active_tab: "home",
        menu_open: false
      }
    end

    @impl true
    def render(assigns) do
      ~H"""
      <LiveUi.Widgets.Box.component id="nav-box" padding="lg" tone="surface">
        <LiveUi.Widgets.Text.component id="nav-title" content="Navigation Demo" />

        <LiveUi.Widgets.Tabs.component
          id="main-tabs"
          items={[
            %{id: "home-tab", label: "Home"},
            %{id: "profile-tab", label: "Profile"},
            %{id: "settings-tab", label: "Settings"}
          ]}
          active_item={@active_tab}
        />

        <section id="tab-content">
          <%= case @active_tab do %>
            <% "home" -> %>
              <LiveUi.Widgets.Menu.component
                id="home-menu"
                items={[
                  %{id: "item-1", label: "View Profile"},
                  %{id: "item-2", label: "Settings"}
                ]}
              />
            <% "profile-tab" -> %>
              <LiveUi.Widgets.Text.component id="profile-info" content="Profile content goes here" />
            <% "settings-tab" -> %>
              <LiveUi.Widgets.CommandPalette.component
                id="settings-commands"
                placeholder="Search settings..."
                items={[
                  %{id: "toggle-theme", label: "Toggle Theme"},
                  %{id: "change-language", label: "Change Language"}
                ]}
              />
          <% end %>
        </section>
      </LiveUi.Widgets.Box.component>
      """
    end
  end

  describe "foundational and input widget integration" do
    test "foundational and input widgets compose correctly in realistic screens" do
      # Mount the screen with runtime state
      assert {:ok, runtime_state} = Runtime.mount(FoundationalInputScreen)

      # Render the screen
      html =
        render_component(Runtime.component(),
          id: "foundational-input-runtime",
          runtime_state: runtime_state
        )

      # Verify foundational widgets are present
      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ ~s(data-live-ui-widget-boundary="text")
      assert html =~ "Sign Up"

      # Verify input widgets are present
      assert html =~ ~s(data-live-ui-widget-boundary="text_input")
      assert html =~ ~s(data-live-ui-widget-boundary="button")

      # Verify styling attributes propagate
      assert html =~ ~s(data-live-ui-tone="surface")
      assert html =~ ~s(data-live-ui-tone="primary")
    end
  end

  describe "navigation widget integration" do
    test "navigation widgets compose correctly with foundational widgets" do
      assert {:ok, runtime_state} = Runtime.mount(NavigationScreen)

      html =
        render_component(Runtime.component(),
          id: "navigation-runtime",
          runtime_state: runtime_state
        )

      # Verify navigation widgets are present
      assert html =~ ~s(data-live-ui-widget-boundary="tabs")
      assert html =~ ~s(data-live-ui-widget-boundary="text")

      # Verify menu items are rendered
      assert html =~ "View Profile"
      assert html =~ "Settings"

      # Verify tabs are rendered
      assert html =~ "Home"
      assert html =~ "Profile"
      assert html =~ "Settings"
    end
  end

  describe "widget identity preservation" do
    test "widget identity includes mode differentiation" do
      native_identity =
        Component.widget_identity(
          LiveUi.Widgets.Button,
          %{id: "test-button"},
          mode: :native
        )

      canonical_identity =
        Component.widget_identity(
          LiveUi.Widgets.Button,
          %{id: "test-button"},
          mode: :canonical
        )

      # Keys should be different based on mode
      native_key = LiveUi.Widget.Identity.key(native_identity)
      canonical_key = LiveUi.Widget.Identity.key(canonical_identity)

      refute native_key == canonical_key
      assert native_key == "native:content:button:test-button:root"
      assert canonical_key == "canonical:content:button:test-button:root"
    end

    test "widget identity is stable across renders" do
      identity1 =
        Component.widget_identity(
          LiveUi.Widgets.Text,
          %{id: "stable-text"}
        )

      identity2 =
        Component.widget_identity(
          LiveUi.Widgets.Text,
          %{id: "stable-text"}
        )

      assert identity1.id == identity2.id

      # Use the Identity.key/1 function to get the key
      key1 = LiveUi.Widget.Identity.key(identity1)
      key2 = LiveUi.Widget.Identity.key(identity2)

      assert key1 == key2
      assert key1 == "native:content:text:stable-text:root"
    end
  end

  describe "event routing through widget boundaries" do
    test "button click events route through component boundary" do
      # This tests that the widget boundary attribute is correctly set
      html =
        render_component(&LiveUi.Widgets.Button.component/1, %{
          id: "click-test",
          label: "Click Me"
        })

      # The widget boundary should be present
      assert html =~ ~s(data-live-ui-widget-boundary="button")

      # The button itself should have the label
      assert html =~ "Click Me"
    end

    test "link navigate events route correctly" do
      html =
        render_component(&LiveUi.Widgets.Link.component/1, %{
          id: "link-test",
          label: "Navigate",
          href: "/target"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="link")
      assert html =~ "Navigate"
      assert html =~ ~s(href="/target")
    end
  end

  describe "nested widget composition" do
    test "container can nest multiple foundational and input widgets" do
      html =
        render_component(&LiveUi.Widgets.Container.component/1, %{
          id: "outer-container",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw("""
                #{render_component(&LiveUi.Widgets.Text.component/1, %{id: "title", content: "Container Title"})}
                #{render_component(&LiveUi.Widgets.TextInput.component/1, %{id: "input", name: "field", label: "Field Label"})}
                #{render_component(&LiveUi.Widgets.Button.component/1, %{id: "action", label: "Action"})}
                """)
              end
            }
          ]
        })

      # All widgets should have their own boundaries
      assert html =~ ~s(data-live-ui-widget-boundary="container")
      assert html =~ ~s(data-live-ui-widget-boundary="text")
      assert html =~ ~s(data-live-ui-widget-boundary="text_input")
      assert html =~ ~s(data-live-ui-widget-boundary="button")

      # Content should be preserved
      assert html =~ "Container Title"
      assert html =~ "Field Label"
      assert html =~ "Action"
    end
  end

  describe "canonical rendering integration" do
    test "canonical rendering preserves widget boundaries for migrated widgets" do
      # This verifies that when UnifiedIUR is rendered, it uses the
      # widget component boundaries for the migrated widgets
      alias UnifiedIUR.{Layout, Widgets.Foundational}

      element =
        Layout.column([
          Foundational.text("Hello World", id: "greeting"),
          Foundational.button("Click Me", id: "action")
        ])

      assert {:ok, runtime_state} = Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "canonical-runtime",
          runtime_state: runtime_state
        )

      # Widget boundaries should be present in canonical rendering
      assert html =~ ~s(data-live-ui-widget="column")
      assert html =~ ~s(data-live-ui-widget="text")
      assert html =~ ~s(data-live-ui-widget="button")

      # Content should be preserved
      assert html =~ "Hello World"
      assert html =~ "Click Me"

      # Mode should be canonical
      assert runtime_state.mode == :canonical
    end
  end
end
