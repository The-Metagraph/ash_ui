defmodule LiveUi.Widgets.PresenceDotTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  @moduledoc """
  Tests for the PresenceDot widget (Wave AshUI-3.9.1a Stage-4).

  Covers: presence-state rendering for all 4 states, default state,
  aria-label fallback, explicit aria-label override, and decorative-only
  (aria-hidden) mode via `aria_label: false`.
  """

  describe "LiveUi.Widgets.PresenceDot metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.PresenceDot)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.PresenceDot.Component
      assert metadata.family == :feedback
      assert metadata.name == :presence_dot
    end
  end

  describe "presence state rendering" do
    test "renders data-presence-state for :active" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-active",
          presence_state: :active
        })

      assert html =~ ~s(data-presence-state="active")
      assert html =~ ~s(data-live-ui-widget="presence_dot")
      assert html =~ "live-ui-presence-dot"
    end

    test "renders data-presence-state for :away" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-away",
          presence_state: :away
        })

      assert html =~ ~s(data-presence-state="away")
    end

    test "renders data-presence-state for :offline" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-offline",
          presence_state: :offline
        })

      assert html =~ ~s(data-presence-state="offline")
    end

    test "renders data-presence-state for :focus" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-focus",
          presence_state: :focus
        })

      assert html =~ ~s(data-presence-state="focus")
    end
  end

  describe "default state" do
    test "defaults to :offline when presence_state is not provided" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-default"
        })

      assert html =~ ~s(data-presence-state="offline")
    end
  end

  describe "aria-label" do
    test "uses provided aria_label string when given" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-explicit-aria",
          presence_state: :active,
          aria_label: "Matt is online"
        })

      assert html =~ ~s(aria-label="Matt is online")
      refute html =~ ~s(aria-hidden="true")
    end

    test "falls back to derived label from state when aria_label is nil" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-derived-aria",
          presence_state: :away
        })

      assert html =~ ~s(aria-label="Presence: away")
      refute html =~ ~s(aria-hidden="true")
    end

    test "falls back to derived label for :active state" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-derived-active",
          presence_state: :active
        })

      assert html =~ ~s(aria-label="Presence: active")
    end

    test "falls back to derived label for :focus state" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-derived-focus",
          presence_state: :focus
        })

      assert html =~ ~s(aria-label="Presence: focus")
    end

    test "falls back to derived label for :offline state" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-derived-offline",
          presence_state: :offline
        })

      assert html =~ ~s(aria-label="Presence: offline")
    end
  end

  describe "decorative-only mode (aria_label: false)" do
    test "renders aria-hidden=true and no aria-label when aria_label is false" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-decorative",
          presence_state: :active,
          aria_label: false
        })

      assert html =~ ~s(aria-hidden="true")
      refute html =~ "aria-label="
    end

    test "decorative-only still renders the presence state data attribute" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-decorative-state",
          presence_state: :focus,
          aria_label: false
        })

      assert html =~ ~s(data-presence-state="focus")
      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "widget boundary attributes" do
    test "renders with data-live-ui-widget-boundary attribute" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-boundary",
          presence_state: :active
        })

      assert html =~ ~s(data-live-ui-widget-boundary="presence_dot")
    end
  end
end
