defmodule AshUI.Rendering.StickyFrostedHeaderTest do
  @moduledoc """
  Tests for the sticky_frosted_header widget type admission and rendering.

  Covers:
  - `AshUI.DSL.Storage.valid_widget_type?/1` admission
  - `AshUI.Rendering.IURAdapter.map_element_type/1` mapping
  - `AshUI.Rendering.LiveUIAdapter` render clause (fallback path)
  - `LiveUI.Renderer` render clause
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.LiveUIAdapter

  @base_iur %{
    "type" => "sticky_frosted_header",
    "id" => "header-1",
    "props" => %{"height" => 64, "class" => ""},
    "children" => [
      %{
        "type" => "row",
        "id" => "leading-1",
        "props" => %{},
        "children" => [],
        "metadata" => %{}
      },
      %{
        "type" => "text",
        "id" => "title-1",
        "props" => %{"content" => "My Page"},
        "children" => [],
        "metadata" => %{}
      },
      %{
        "type" => "row",
        "id" => "trailing-1",
        "props" => %{},
        "children" => [],
        "metadata" => %{}
      }
    ],
    "metadata" => %{}
  }

  describe "admission" do
    test "valid_widget_type?/1 accepts sticky_frosted_header" do
      assert Storage.valid_widget_type?("sticky_frosted_header")
    end

    test "valid_widget_type?/1 still rejects unknown widget types" do
      refute Storage.valid_widget_type?("frosted_banana")
    end
  end

  describe "LiveUIAdapter rendering" do
    setup do
      canonical_iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [@base_iur],
        "bindings" => [],
        "metadata" => %{}
      }

      {:ok, canonical_iur: canonical_iur}
    end

    test "renders sticky_frosted_header element inside a screen", %{canonical_iur: iur} do
      assert {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

      assert String.contains?(heex, "ash-sticky-frosted-header")
    end

    test "renders all three slot containers", %{canonical_iur: iur} do
      assert {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

      assert String.contains?(heex, "ash-sticky-frosted-header-leading")
      assert String.contains?(heex, "ash-sticky-frosted-header-title")
      assert String.contains?(heex, "ash-sticky-frosted-header-trailing")
    end

    test "applies height as inline style", %{canonical_iur: iur} do
      assert {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

      assert String.contains?(heex, "height: 64px")
    end
  end

  describe "LiveUI.Renderer direct rendering" do
    test "renders sticky_frosted_header with all slot containers" do
      iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test",
        "layout" => "column",
        "children" => [@base_iur],
        "bindings" => [],
        "metadata" => %{}
      }

      assert {:ok, heex} = LiveUI.Renderer.render(iur)

      assert String.contains?(heex, "ash-sticky-frosted-header")
      assert String.contains?(heex, "ash-sticky-frosted-header-leading")
      assert String.contains?(heex, "ash-sticky-frosted-header-title")
      assert String.contains?(heex, "ash-sticky-frosted-header-trailing")
    end

    test "renders child content in correct slot position" do
      iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test",
        "layout" => "column",
        "children" => [@base_iur],
        "bindings" => [],
        "metadata" => %{}
      }

      assert {:ok, heex} = LiveUI.Renderer.render(iur)

      assert String.contains?(heex, "My Page")
    end

    test "renders with custom height prop" do
      custom_iur = put_in(@base_iur, ["props", "height"], 72)

      iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test",
        "layout" => "column",
        "children" => [custom_iur],
        "bindings" => [],
        "metadata" => %{}
      }

      assert {:ok, heex} = LiveUI.Renderer.render(iur)

      assert String.contains?(heex, "height: 72px")
    end
  end
end
