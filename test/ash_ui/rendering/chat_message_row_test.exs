defmodule AshUI.Rendering.ChatMessageRowTest do
  @moduledoc """
  Tests for the chat_message_row widget type admission and rendering.

  Covers:
  - `AshUI.DSL.Storage.valid_widget_type?/1` admission
  - `LiveUI.Renderer` render clause (direct live render path)
  - Full props: author, timestamp, body, avatar_variant, presence
  - Minimal props: no presence omits the presence_dot span
  - Each avatar_variant produces a distinct token reference
  - Empty body handled gracefully
  - Multi-line body (\\n) renders as <br>
  - No literal hex/rgb colour values emitted
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias LiveUI.Renderer, as: LiveUIRenderer

  @full_iur %{
    "type" => "chat_message_row",
    "id" => "msg-1",
    "props" => %{
      "author" => "Pascal",
      "timestamp" => "00:19",
      "body" => "Agree. Make the sentence say the document is the collaboration surface.",
      "avatar_variant" => "pascal",
      "presence" => "live"
    },
    "children" => [],
    "metadata" => %{}
  }

  @minimal_iur %{
    "type" => "chat_message_row",
    "id" => "msg-2",
    "props" => %{
      "author" => "Codex",
      "timestamp" => "00:21",
      "body" => "I found the sentence.",
      "avatar_variant" => "codex"
    },
    "children" => [],
    "metadata" => %{}
  }

  # ── Admission ─────────────────────────────────────────────────────────────

  describe "admission" do
    test "valid_widget_type?/1 accepts chat_message_row" do
      assert Storage.valid_widget_type?("chat_message_row")
    end

    test "valid_widget_type?/1 still rejects unknown widget types" do
      refute Storage.valid_widget_type?("chat_bubble_unknown")
    end
  end

  # ── LiveUI.Renderer rendering ──────────────────────────────────────────────

  describe "LiveUI.Renderer full props" do
    test "renders the article wrapper with chat-message-row class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row"
    end

    test "renders the avatar span with avatar_variant token reference" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row__avatar"
      assert html =~ "var(--avatar-pascal"
    end

    test "avatar badge shows first initial of author name" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      # Pascal → "P" initial
      assert html =~ ">P<"
    end

    test "renders author name in meta line" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row__author"
      assert html =~ "Pascal"
    end

    test "renders timestamp in meta line" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row__timestamp"
      assert html =~ "00:19"
    end

    test "renders body text" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row__body"
      assert html =~ "collaboration surface"
    end

    test "renders presence_dot when presence prop is set" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "chat-message-row__presence"
      assert html =~ ~s(data-state="live")
      assert html =~ "var(--presence-live"
    end
  end

  describe "LiveUI.Renderer minimal props (no presence)" do
    test "omits presence_dot span when presence is absent" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      refute html =~ "chat-message-row__presence"
    end

    test "still renders author, timestamp, and body" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      assert html =~ "Codex"
      assert html =~ "00:21"
      assert html =~ "I found the sentence."
    end
  end

  describe "avatar_variant token references" do
    for variant <- ["pascal", "codex", "gemini", "mike", "neutral"] do
      @variant variant
      test "avatar_variant #{@variant} references var(--avatar-#{@variant})" do
        iur = put_in(@full_iur, ["props", "avatar_variant"], @variant)
        {:ok, html} = LiveUIRenderer.render(screen_with(iur))

        assert html =~ "var(--avatar-#{@variant}",
               "expected var(--avatar-#{@variant}) in HTML for variant #{@variant}"
      end
    end

    test "each variant produces a distinct data-variant attribute" do
      variants = ["pascal", "codex", "gemini", "mike"]

      variant_attrs =
        Enum.map(variants, fn v ->
          iur = put_in(@full_iur, ["props", "avatar_variant"], v)
          {:ok, html} = LiveUIRenderer.render(screen_with(iur))
          assert html =~ ~s(data-variant="#{v}")
          v
        end)

      assert Enum.uniq(variant_attrs) == variants
    end
  end

  describe "edge cases" do
    test "empty body renders gracefully without crashing" do
      iur = put_in(@full_iur, ["props", "body"], "")
      assert {:ok, html} = LiveUIRenderer.render(screen_with(iur))
      assert html =~ "chat-message-row__body"
    end

    test "multi-line body renders newlines as <br>" do
      iur = put_in(@full_iur, ["props", "body"], "Line one\nLine two")
      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      assert html =~ "Line one<br>Line two"
    end

    test "no literal hex color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/#[0-9a-fA-F]{3,6}\b/,
             "found literal hex color value in chat_message_row HTML"
    end

    test "no rgb() color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/\brgb\s*\(/,
             "found rgb() color value in chat_message_row HTML"
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp screen_with(widget) do
    %{
      "type" => "screen",
      "id" => "screen-1",
      "name" => "test_screen",
      "layout" => "column",
      "children" => [widget],
      "bindings" => [],
      "metadata" => %{}
    }
  end
end
