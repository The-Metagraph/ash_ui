defmodule AshUI.Rendering.VoicePairPresenceTest do
  @moduledoc """
  Tests for the voice_pair_presence widget type admission and rendering.

  Covers:
  - `AshUI.DSL.Storage.valid_widget_type?/1` admission
  - `LiveUI.Renderer` render clause (direct live render path)
  - Full props: participant_a, participant_b, state, accent_variant
  - Missing optional fields (accent_variant absent) handled gracefully
  - Each state produces distinct class / token reference
  - accent_variant drives data-accent attribute and avatar token
  - Participant initial derived from participant_a name
  - Empty participant_a falls back to "?" initial
  - Token purity — no literal hex/rgb values in output
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias LiveUI.Renderer, as: LiveUIRenderer

  @full_iur %{
    "type" => "voice_pair_presence",
    "id" => "vpp-1",
    "props" => %{
      "participant_a" => "Mike",
      "participant_b" => "Codex",
      "state" => "listening",
      "accent_variant" => "codex"
    },
    "children" => [],
    "metadata" => %{}
  }

  @minimal_iur %{
    "type" => "voice_pair_presence",
    "id" => "vpp-2",
    "props" => %{
      "participant_a" => "Pascal",
      "participant_b" => "Gemini",
      "state" => "idle"
    },
    "children" => [],
    "metadata" => %{}
  }

  # ── Admission ─────────────────────────────────────────────────────────────

  describe "admission" do
    test "valid_widget_type?/1 accepts voice_pair_presence" do
      assert Storage.valid_widget_type?("voice_pair_presence")
    end

    test "valid_widget_type?/1 still rejects unknown widget types" do
      refute Storage.valid_widget_type?("voice_pair_unknown")
    end
  end

  # ── LiveUI.Renderer full props ─────────────────────────────────────────────

  describe "LiveUI.Renderer full props" do
    test "renders the li wrapper with voice-pair-presence class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "voice-pair-presence"
    end

    test "renders participant_a name" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "voice-pair-presence__name-a"
      assert html =~ "Mike"
    end

    test "renders participant_b name" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "voice-pair-presence__name-b"
      assert html =~ "Codex"
    end

    test "renders the colon separator" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "voice-pair-presence__sep"
      assert html =~ ":"
    end

    test "renders state data attribute on root element" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(data-state="listening")
    end

    test "renders state label in status span" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "voice-pair-presence__status"
      assert html =~ "listening"
    end

    test "renders accent_variant as data-accent attribute" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(data-accent="codex")
    end

    test "renders avatar token reference for accent_variant" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "var(--avatar-codex"
    end

    test "derives initial from participant_a name" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      # Mike → "M"
      assert html =~ ">M<"
    end
  end

  # ── LiveUI.Renderer minimal props ─────────────────────────────────────────

  describe "LiveUI.Renderer minimal props (no accent_variant)" do
    test "omits data-accent attribute when accent_variant is absent" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      refute html =~ "data-accent"
    end

    test "falls back to neutral avatar token when no accent_variant" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      assert html =~ "var(--avatar-neutral"
    end

    test "still renders participant names and state" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      assert html =~ "Pascal"
      assert html =~ "Gemini"
      assert html =~ "idle"
    end
  end

  # ── State token variation ─────────────────────────────────────────────────

  describe "state token references" do
    for {state, expected_token} <- [
          {"listening", "var(--presence-listening"},
          {"idle", "var(--presence-idle"},
          {"muted", "var(--presence-muted"},
          {"active", "var(--presence-active"}
        ] do
      @state state
      @expected_token expected_token
      test "state #{@state} produces token reference #{@expected_token}" do
        iur = put_in(@full_iur, ["props", "state"], @state)
        {:ok, html} = LiveUIRenderer.render(screen_with(iur))

        assert html =~ @expected_token,
               "expected #{@expected_token} in HTML for state #{@state}"
      end
    end

    test "each state produces a distinct data-state value" do
      states = ["listening", "idle", "muted", "active"]

      rendered_states =
        Enum.map(states, fn s ->
          iur = put_in(@full_iur, ["props", "state"], s)
          {:ok, html} = LiveUIRenderer.render(screen_with(iur))
          assert html =~ ~s(data-state="#{s}")
          s
        end)

      assert Enum.uniq(rendered_states) == states
    end
  end

  # ── Edge cases ────────────────────────────────────────────────────────────

  describe "edge cases" do
    test "empty participant_a falls back to ? initial" do
      iur = put_in(@full_iur, ["props", "participant_a"], "")
      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      assert html =~ ">?<"
    end

    test "missing state prop defaults without crashing" do
      iur = update_in(@full_iur["props"], &Map.delete(&1, "state"))
      assert {:ok, html} = LiveUIRenderer.render(screen_with(iur))
      assert html =~ "voice-pair-presence"
    end

    test "no literal hex color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/#[0-9a-fA-F]{3,6}\b/,
             "found literal hex color value in voice_pair_presence HTML"
    end

    test "no rgb() color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/\brgb\s*\(/,
             "found rgb() color value in voice_pair_presence HTML"
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
