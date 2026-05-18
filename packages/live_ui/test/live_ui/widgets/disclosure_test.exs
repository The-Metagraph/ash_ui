defmodule LiveUi.Widgets.DisclosureTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  @moduledoc """
  Tests for LiveUi.Widgets.Disclosure — the native `<details>` disclosure primitive.

  Covers:
  - Default closed state (no `open` attribute on `<details>`)
  - Explicit open state (`open` attribute present)
  - `summary` named slot rendered inside `<summary>`
  - `body` named slot rendered inside the body div
  - `label` attr used as fallback when no `summary` slot provided
  - `id` attribute set on the outer `<details>` element
  - Widget metadata: family, name, mountable boundary
  """

  describe "Disclosure widget metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Disclosure)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Disclosure.Component
      assert metadata.name == :disclosure
    end

    test "family matches canonical content identity catalog" do
      metadata = Component.metadata(LiveUi.Widgets.Disclosure)

      assert metadata.family == :content_identity_and_disclosure
    end

    test "is exposed through the content identity widget family" do
      assert LiveUi.Widgets.Disclosure in LiveUi.Widgets.content_identity_and_disclosure_modules()
      assert LiveUi.Widgets.Disclosure in LiveUi.Widgets.modules()
    end
  end

  describe "Disclosure component rendering" do
    test "renders as a <details> element with correct data-live-ui-widget" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "test-disclosure",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body content" end}]
        })

      assert html =~ "<details"
      assert html =~ ~s(data-live-ui-widget="disclosure")
      assert html =~ ~s(id="test-disclosure")
    end

    test "default state is closed — no `open` attribute on <details>" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "closed-disclosure",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      # Phoenix renders `open={false}` as the attribute absent
      refute html =~ ~s( open="true")
      refute html =~ ~s( open=true)
    end

    test "open?={true} adds `open` attribute to <details>" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "open-disclosure",
          open?: true,
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ " open"
    end

    test "body slot content rendered inside .live-ui-disclosure-body" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "body-slot-disclosure",
          body: [
            %{__slot__: :body, inner_block: fn _, _ -> "Disclosure body text" end}
          ]
        })

      assert html =~ "Disclosure body text"
      assert html =~ ~s(class="live-ui-disclosure-body")
    end

    test "summary slot rendered inside <summary> when provided" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "summary-slot-disclosure",
          summary: [
            %{__slot__: :summary, inner_block: fn _, _ -> "Custom summary content" end}
          ],
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ "Custom summary content"
      assert html =~ "<summary"
      assert html =~ ~s(class="live-ui-disclosure-summary")
    end

    test "label attr used as fallback when summary slot is empty" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "label-fallback-disclosure",
          label: "Toggle section",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ "Toggle section"
      assert html =~ "<summary"
    end

    test "id attribute set on outer <details> element" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "my-disclosure-id",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ ~s(id="my-disclosure-id")
    end

    test "tone and variant passed through as data attrs" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "styled-disclosure",
          tone: "surface",
          variant: "outlined",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ ~s(data-live-ui-tone="surface")
      assert html =~ ~s(data-live-ui-variant="outlined")
    end

    test "widget boundary key is present when rendered via component/1" do
      html =
        render_component(&LiveUi.Widgets.Disclosure.component/1, %{
          id: "boundary-disclosure",
          body: [%{__slot__: :body, inner_block: fn _, _ -> "Body" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="disclosure")
    end
  end
end
