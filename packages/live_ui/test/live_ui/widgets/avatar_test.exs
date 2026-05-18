defmodule LiveUi.Widgets.AvatarTest do
  @moduledoc """
  Tests for the Avatar widget Phoenix.Component.

  Covers:
  - Rendering with image_url present (img path)
  - Rendering with initials fallback (no image_url)
  - Each size_variant (small / medium / large) sets the right CSS class
  - aria-label present when label_text given
  - All attrs default correctly (actor_id required; rest have sane defaults)
  - data-live-ui-widget="avatar" marker always present
  - tone / state data attrs forwarded
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  describe "component metadata" do
    test "avatar widget has a metadata entry with the correct family and name" do
      metadata = Component.metadata(LiveUi.Widgets.Avatar)

      assert metadata.family == :content
      assert metadata.name == :avatar
    end

    test "avatar widget has a mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Avatar)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Avatar.Component
    end

    test "actor_id is listed in avatar assigns contract" do
      metadata = Component.metadata(LiveUi.Widgets.Avatar)

      assert :actor_id in metadata.assigns
    end
  end

  describe "image path (image_url present)" do
    test "renders img tag with src and alt when image_url is given" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-img",
          actor_id: "user-42",
          image_url: "/avatars/user-42.png",
          label_text: "Alice"
        })

      assert html =~ ~s(src="/avatars/user-42.png")
      assert html =~ ~s(alt="Alice")
      assert html =~ ~s(class="live-ui-avatar-image")
    end

    test "outer span has data-live-ui-widget=avatar" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-widget-attr",
          actor_id: "user-1",
          image_url: "/img.png"
        })

      assert html =~ ~s(data-live-ui-widget="avatar")
    end

    test "actor_id is forwarded as data-actor-id DOM hook" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-actor",
          actor_id: "actor-99",
          image_url: "/img.png"
        })

      assert html =~ ~s(data-actor-id="actor-99")
    end

    test "initials span is not rendered when image_url is present" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-no-initials",
          actor_id: "user-7",
          image_url: "/img.png",
          initials: "AB"
        })

      refute html =~ "live-ui-avatar-initials"
      refute html =~ "AB"
    end
  end

  describe "initials fallback (no image_url)" do
    test "renders initials span when image_url is nil" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-initials",
          actor_id: "user-3",
          initials: "JD"
        })

      assert html =~ ~s(class="live-ui-avatar-initials")
      assert html =~ "JD"
    end

    test "initials span has aria-hidden=true when label_text is present" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-aria-hidden",
          actor_id: "user-4",
          initials: "JD",
          label_text: "Jane Doe"
        })

      assert html =~ ~s(aria-hidden="true")
    end

    test "initials span has aria-hidden=false when label_text is nil" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-aria-visible",
          actor_id: "user-5",
          initials: "AB"
        })

      assert html =~ ~s(aria-hidden="false")
    end

    test "no img tag rendered when image_url is absent" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-no-img",
          actor_id: "user-6",
          initials: "XY"
        })

      refute html =~ "<img"
    end
  end

  describe "size_variant CSS classes" do
    test "size_variant :small produces live-ui-avatar--small class" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-small",
          actor_id: "u",
          size_variant: :small
        })

      assert html =~ "live-ui-avatar--small"
    end

    test "size_variant :medium produces live-ui-avatar--medium class" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-medium",
          actor_id: "u",
          size_variant: :medium
        })

      assert html =~ "live-ui-avatar--medium"
    end

    test "size_variant :large produces live-ui-avatar--large class" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-large",
          actor_id: "u",
          size_variant: :large
        })

      assert html =~ "live-ui-avatar--large"
    end

    test "default size_variant is :small" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-default-size",
          actor_id: "u"
        })

      assert html =~ "live-ui-avatar--small"
    end
  end

  describe "aria-label" do
    test "outer span has aria-label when label_text is provided" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-aria-label",
          actor_id: "u",
          label_text: "Bob Smith"
        })

      assert html =~ ~s(aria-label="Bob Smith")
    end

    test "aria-label is absent when label_text is nil" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-no-aria-label",
          actor_id: "u"
        })

      refute html =~ ~s(aria-label=)
    end
  end

  describe "tone and state data attributes" do
    test "tone is forwarded to data-live-ui-tone" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-tone",
          actor_id: "u",
          tone: "positive"
        })

      assert html =~ ~s(data-live-ui-tone="positive")
    end

    test "state is forwarded to data-live-ui-state" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-state",
          actor_id: "u",
          state: "selected"
        })

      assert html =~ ~s(data-live-ui-state="selected")
    end
  end

  describe "default values" do
    test "all optional attrs have sane defaults — renders without error" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-defaults",
          actor_id: "user-default"
        })

      assert html =~ "live-ui-avatar"
      assert html =~ "avatar-defaults"
    end

    test "widget boundary key is stable" do
      html =
        render_component(&LiveUi.Widgets.Avatar.component/1, %{
          id: "avatar-key-check",
          actor_id: "user-stable"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="avatar")
      assert html =~ ~s(data-live-ui-widget-key="native:content:avatar:avatar-key-check:root")
    end
  end
end
