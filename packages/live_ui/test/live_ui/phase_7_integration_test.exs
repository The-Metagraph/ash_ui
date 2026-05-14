defmodule LiveUi.Phase7IntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Container
  alias UnifiedIUR.Widgets.{Foundational, Input}

  test "foundational direct-native and canonical rendering converge on browser-visible style output" do
    native_text =
      render_component(
        &LiveUi.Widgets.Text.render/1,
        %{
          id: "native-text",
          content: "Ready"
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:text,
            theme: LiveUi.Theme.default(),
            style: %{foreground: "#22c55e", text: %{underline?: true}}
          )
        )
      )

    canonical_text =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Foundational.text("Ready",
            id: "canonical-text",
            style: %{foreground: "#22c55e", text: %{underline?: true}}
          )
      )

    for fragment <- [
          "data-live-ui-browser-style=\"mixed\"",
          "--live-ui-foreground: #22c55e",
          "--live-ui-text-decoration: underline"
        ] do
      assert native_text =~ fragment
      assert canonical_text =~ fragment
    end

    native_button =
      render_component(
        &LiveUi.Widgets.Button.render/1,
        %{
          id: "native-button",
          label: "Save"
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:button,
            theme: LiveUi.Theme.default(),
            variant: :solid,
            style: %{background: "#1d4ed8", foreground: "#ffffff"}
          )
        )
      )

    canonical_button =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Foundational.button("Save",
            id: "canonical-button",
            style: %{background: "#1d4ed8", foreground: "#ffffff"}
          )
      )

    for fragment <- [
          "--live-ui-background: #1d4ed8",
          "--live-ui-foreground: #ffffff"
        ] do
      assert native_button =~ fragment
      assert canonical_button =~ fragment
    end

    native_input =
      render_component(
        &LiveUi.Widgets.TextInput.render/1,
        %{
          id: "native-input",
          name: "name",
          placeholder: "Name"
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:text_input,
            theme: LiveUi.Theme.default(),
            style: %{background: "#0f172a", border_color: "#38bdf8"}
          )
        )
      )

    canonical_input =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Input.text_input(
            id: "canonical-input",
            name: :name,
            placeholder: "Name",
            style: %{background: "#0f172a", border_color: "#38bdf8"}
          )
      )

    for fragment <- [
          "--live-ui-background: #0f172a",
          "--live-ui-border-color: #38bdf8"
        ] do
      assert native_input =~ fragment
      assert canonical_input =~ fragment
    end

    native_box =
      render_component(
        &LiveUi.Widgets.Box.render/1,
        %{
          id: "native-box",
          inner_block: [box_slot("Panel")]
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:box,
            theme: LiveUi.Theme.default(),
            variant: :panel,
            style: %{
              background: "#020617",
              border_color: "#334155",
              border: %{radius: :lg}
            }
          )
        )
      )

    canonical_box =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Container.box(
            [Foundational.text("Panel", id: "panel-copy")],
            id: "canonical-box",
            style: %{
              background: "#020617",
              border_color: "#334155",
              border: %{radius: :lg}
            },
            theme: %{id: :live_ui, variant: :panel}
          )
      )

    for fragment <- [
          "--live-ui-background: #020617",
          "--live-ui-border-color: #334155",
          "--live-ui-border-radius: 1rem"
        ] do
      assert native_box =~ fragment
      assert canonical_box =~ fragment
    end
  end

  test "shared stylesheet remains package-owned and powers aligned preview surfaces" do
    assert LiveUi.stylesheet() == LiveUi.Stylesheet

    css = LiveUi.Stylesheet.css()

    for selector <- [
          ".live-ui-text",
          ".live-ui-button",
          ".live-ui-text-input",
          ".live-ui-box",
          "[data-live-ui-widget=\"grid\"]"
        ] do
      assert css =~ selector
    end

    assert {:ok, html} = LiveUi.Export.example(:button, :html)
    assert html =~ "data-live-ui-widget=\"button\""
  end

  test "fallback hooks legacy attrs and diagnostics remain integration-stable" do
    fallback_html =
      render_component(
        &LiveUi.Widgets.Text.render/1,
        %{
          id: "fallback-text",
          content: "Ready"
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:text,
            theme: LiveUi.Theme.default(),
            tone: :success,
            class: "legacy-tone"
          )
        )
      )

    assert fallback_html =~ "data-live-ui-tone=\"success\""
    assert fallback_html =~ "data-live-ui-browser-fallback=\"mixed\""
    assert fallback_html =~ "legacy-tone"
    refute fallback_html =~ "--live-ui-foreground:"

    legacy_html =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Foundational.text("Legacy",
            id: "legacy-copy",
            style: %{
              foreground: "#f97316",
              extra: %{
                class: "legacy-copy",
                attrs: %{"data-legacy" => "true"}
              }
            }
          )
      )

    assert legacy_html =~ "legacy-copy"
    assert legacy_html =~ "data-legacy=\"true\""
    assert legacy_html =~ "--live-ui-foreground: #f97316"

    diagnostics =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :text,
        local_style: %{
          text: %{blink?: true, reverse?: true},
          visibility: %{disabled?: true},
          state_variants: %{active: %{foreground: "#ffffff"}}
        }
      )
      |> LiveUi.Style.browser_diagnostics()

    assert diagnostics.fallback == :mixed

    assert diagnostics.unsupported_fields == [
             "text.blink?",
             "text.reverse?",
             "visibility.disabled?"
           ]

    assert diagnostics.ignored_fields == ["state_variants.active"]
  end

  defp box_slot(content) do
    %{
      __slot__: :inner_block,
      inner_block: fn _, _ -> content end
    }
  end

end
