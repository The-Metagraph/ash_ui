defmodule LiveUi.StyleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "style resolution applies theme defaults and explicit overrides to native widgets" do
    theme = LiveUi.Theme.default()

    assigns =
      LiveUi.Style.component_assigns(:button,
        theme: theme,
        tone: :success,
        variant: :quiet,
        state: :active,
        class: "custom-button"
      )

    html =
      render_component(
        &LiveUi.Widgets.Button.render/1,
        %{
          id: "save",
          label: "Save"
        }
        |> Map.merge(assigns)
      )

    assert html =~ "data-live-ui-tone=\"success\""
    assert html =~ "data-live-ui-variant=\"quiet\""
    assert html =~ "data-live-ui-state=\"active\""
    assert html =~ "class=\"live-ui-button live-ui-button-quiet is-active custom-button\""
    assert html =~ "data-live-ui-theme=\"live_ui\""
  end

  test "style merging preserves parent continuity while allowing child overrides" do
    parent =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :overlay_surface,
        variant: :modal,
        state: :active
      )

    child =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :button,
        tone: :critical,
        class: "destructive"
      )

    merged = LiveUi.Style.merge(parent, child)

    assert merged.tone == "critical"
    assert merged.variant == "solid"
    assert merged.state == "active"
    assert merged.class =~ "live-ui-overlay-surface"
    assert merged.class =~ "live-ui-button"
    assert merged.class =~ "destructive"
  end

  test "style lowering can derive a native profile from canonical element attachments" do
    element =
      UnifiedIUR.Widgets.Foundational.button("Save",
        id: "save",
        style: %{
          emphasis: %{tone: :warning},
          extra: %{class: "canonical-warning"}
        },
        theme: %{id: :live_ui, variant: :quiet}
      )

    profile = LiveUi.Style.from_element(element)

    assert profile.component == :button
    assert profile.theme_id == :live_ui
    assert profile.tone == "warning"
    assert profile.variant == "quiet"
    assert profile.class =~ "live-ui-button"
    assert profile.class =~ "canonical-warning"
  end

  test "style resolution exposes a deterministic browser realization payload" do
    theme = LiveUi.Theme.default()

    left =
      LiveUi.Style.resolve(theme, :text,
        local_style: %{
          foreground: "#0f172a",
          background: "#f8fafc",
          border_color: "#cbd5e1",
          text: %{italic?: true, underline?: true},
          spacing: %{padding_x: :lg, gap: :sm},
          sizing: %{width: 320},
          alignment: %{text_align: :center},
          visibility: %{opacity: 0.92}
        }
      )

    right =
      LiveUi.Style.resolve(theme, :text,
        local_style: %{
          foreground: "#0f172a",
          background: "#f8fafc",
          border_color: "#cbd5e1",
          text: %{underline?: true, italic?: true},
          spacing: %{gap: :sm, padding_x: :lg},
          sizing: %{width: 320},
          alignment: %{text_align: :center},
          visibility: %{opacity: 0.92},
          extra: %{}
        }
      )

    assert left.browser == right.browser
    assert left.browser.mode == :mixed
    assert left.browser.css_vars["--live-ui-foreground"] == "#0f172a"
    assert left.browser.css_vars["--live-ui-background"] == "#f8fafc"
    assert left.browser.css_vars["--live-ui-border-color"] == "#cbd5e1"
    assert left.browser.css_vars["--live-ui-font-style"] == "italic"
    assert left.browser.css_vars["--live-ui-text-decoration"] == "underline"
    assert left.browser.css_vars["--live-ui-padding-inline"] == "1rem"
    assert left.browser.css_vars["--live-ui-gap"] == "0.5rem"
    assert left.browser.css_vars["--live-ui-width"] == "320px"
    assert left.browser.css_vars["--live-ui-text-align"] == "center"
    assert left.browser.css_vars["--live-ui-opacity"] == "0.92"
    assert :emphasis in left.browser.semantic_only_fields
  end

  test "to_assigns emits browser-realized attrs while preserving semantic hooks" do
    profile =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :button,
        tone: :critical,
        variant: :quiet,
        state: :active,
        local_style: %{
          foreground: "#fafafa",
          background: "#1f2937",
          border: %{radius: :lg, weight: :thin},
          text: %{bold?: true}
        }
      )

    assigns = LiveUi.Style.to_assigns(profile)

    assert assigns.tone == "critical"
    assert assigns.variant == "quiet"
    assert assigns.state == "active"
    assert assigns.class =~ "live-ui-button"
    assert assigns.rest["data-live-ui-browser-style"] == "mixed"
    assert assigns.rest["data-live-ui-realized-style-fields"] =~ "foreground"
    assert assigns.rest["style"] =~ "--live-ui-foreground: #fafafa"
    assert assigns.rest["style"] =~ "--live-ui-background: #1f2937"
    assert assigns.rest["style"] =~ "--live-ui-border-radius: 1rem"
    assert assigns.rest["style"] =~ "--live-ui-border-width: 1px"
    assert assigns.rest["style"] =~ "--live-ui-font-weight: 700"
  end

  test "browser host attrs append after realized attrs so hosts can override locally" do
    assigns =
      LiveUi.Style.apply(
        %{rest: %{"style" => "--live-ui-foreground: #ffffff", "data-host" => "true"}},
        LiveUi.Theme.default(),
        :text,
        style: %{foreground: "#0f172a"}
      )

    assert assigns.rest["data-live-ui-browser-style"] == "mixed"
    assert assigns.rest["data-host"] == "true"
    assert assigns.rest["style"] =~ "--live-ui-foreground: #0f172a"
    assert String.ends_with?(assigns.rest["style"], "--live-ui-foreground: #ffffff")
  end

  test "semantic hook fallback remains explicit when direct browser colors are absent" do
    assigns =
      LiveUi.Style.component_assigns(:text,
        theme: LiveUi.Theme.default(),
        tone: :success,
        class: "legacy-tone"
      )

    html =
      render_component(
        &LiveUi.Widgets.Text.render/1,
        %{
          id: "status",
          content: "Ready"
        }
        |> Map.merge(assigns)
      )

    assert html =~ "data-live-ui-tone=\"success\""
    assert html =~ "data-live-ui-browser-style=\"mixed\""
    assert html =~ "data-live-ui-browser-fallback=\"mixed\""
    assert html =~ "class=\"live-ui-text legacy-tone\""
    refute html =~ "--live-ui-foreground:"
  end

  test "browser diagnostics surface ignored and unsupported foundational style fields" do
    profile =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :text,
        local_style: %{
          text: %{blink?: true, reverse?: true},
          visibility: %{disabled?: true},
          state_variants: %{active: %{foreground: "#ffffff"}}
        }
      )

    diagnostics = LiveUi.Style.browser_diagnostics(profile)

    assert diagnostics.fallback == :mixed

    assert diagnostics.unsupported_fields == [
             "text.blink?",
             "text.reverse?",
             "visibility.disabled?"
           ]

    assert diagnostics.ignored_fields == ["state_variants.active"]
    assert profile.browser.attrs["data-live-ui-ignored-style-fields"] == "state_variants.active"
  end

  test "browser realization applies the active state variant when a supported state is selected" do
    profile =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :status,
        state: :active,
        local_style: %{
          border_color: "#334155",
          state_variants: %{
            active: %{foreground: "#ffffff", background: "#0f172a", border_color: "#2563eb"}
          }
        }
      )

    diagnostics = LiveUi.Style.browser_diagnostics(profile)

    assert diagnostics.ignored_fields == []
    assert profile.browser.attrs["style"] =~ "--live-ui-foreground: #ffffff"
    assert profile.browser.attrs["style"] =~ "--live-ui-background: #0f172a"
    assert profile.browser.attrs["style"] =~ "--live-ui-border-color: #2563eb"
  end
end
