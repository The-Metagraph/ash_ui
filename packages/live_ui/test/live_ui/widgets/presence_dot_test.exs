defmodule LiveUi.Widgets.PresenceDotTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  @moduledoc """
  Tests for the PresenceDot widget (Wave AshUI-3.9.1a Stage-4).

  Covers: presence-state rendering for all canonical states, default state,
  aria-label fallback, explicit aria-label override, and decorative-only
  (aria-hidden) mode via `decorative?: true`.
  """

  describe "LiveUi.Widgets.PresenceDot metadata" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.PresenceDot)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.PresenceDot.Component
      assert metadata.family == :content_identity_and_disclosure
      assert metadata.name == :presence_dot
    end

    test "is exposed through the content identity widget family" do
      assert :content_identity_and_disclosure in LiveUi.Widgets.families()

      assert LiveUi.Widgets.PresenceDot in LiveUi.Widgets.content_identity_and_disclosure_modules()

      assert LiveUi.Widgets.PresenceDot in LiveUi.Widgets.modules()
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

    test "renders data-presence-state for :do_not_disturb" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-do-not-disturb",
          presence_state: :do_not_disturb
        })

      assert html =~ ~s(data-presence-state="do_not_disturb")
      assert html =~ ~s(aria-label="Presence: do not disturb")
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

  describe "decorative-only mode" do
    test "renders aria-hidden=true and no aria-label when decorative? is true" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-decorative",
          presence_state: :active,
          decorative?: true
        })

      assert html =~ ~s(aria-hidden="true")
      refute html =~ "aria-label="
    end

    test "continues to support aria_label false as a compatibility shortcut" do
      html =
        render_component(&LiveUi.Widgets.PresenceDot.component/1, %{
          id: "dot-decorative-compat",
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
          decorative?: true
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
