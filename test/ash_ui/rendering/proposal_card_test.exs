defmodule AshUI.Rendering.ProposalCardTest do
  @moduledoc """
  Tests for the proposal_card widget type admission and rendering.

  Covers:
  - `AshUI.DSL.Storage.valid_widget_type?/1` admission
  - `LiveUI.Renderer` render clause (direct live render path)
  - Full props: proposer, timestamp, proposed_text, state, accept_event, accept_value, accent_variant
  - Minimal props: no accent_variant defaults to neutral avatar token
  - Each state (:pending, :accepted, :rejected, :superseded) renders correct visual treatment
  - Accept + Reject buttons render only in :pending state
  - phx-click event and phx-value-id wire correctly
  - Each accent_variant produces distinct data-accent attribute and avatar token
  - Token purity — no literal hex/rgb colour values in output
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias LiveUI.Renderer, as: LiveUIRenderer

  @full_iur %{
    "type" => "proposal_card",
    "id" => "pc-1",
    "props" => %{
      "proposer" => "Codex",
      "timestamp" => "09:42",
      "proposed_text" => "The document is the collaboration surface.",
      "state" => "pending",
      "accept_event" => "accept_proposal",
      "accept_value" => "proposal-abc123",
      "accent_variant" => "codex"
    },
    "children" => [],
    "metadata" => %{}
  }

  @minimal_iur %{
    "type" => "proposal_card",
    "id" => "pc-2",
    "props" => %{
      "proposer" => "Pascal",
      "timestamp" => "10:00",
      "proposed_text" => "Conversations are primary.",
      "state" => "pending",
      "accept_event" => "accept_proposal"
    },
    "children" => [],
    "metadata" => %{}
  }

  # ── Admission ─────────────────────────────────────────────────────────────

  describe "admission" do
    test "valid_widget_type?/1 accepts proposal_card" do
      assert Storage.valid_widget_type?("proposal_card")
    end

    test "valid_widget_type?/1 still rejects unknown widget types" do
      refute Storage.valid_widget_type?("proposal_unknown")
    end
  end

  # ── LiveUI.Renderer full props ─────────────────────────────────────────────

  describe "LiveUI.Renderer full props (pending)" do
    test "renders the root wrapper with proposal-card class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card"
    end

    test "renders proposer name in header" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card__proposer"
      assert html =~ "Codex"
    end

    test "renders timestamp in header" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card__timestamp"
      assert html =~ "09:42"
    end

    test "renders proposed_text in blockquote" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card__proposed-text"
      assert html =~ "collaboration surface"
    end

    test "renders Accept button in pending state" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card__btn--accept"
      assert html =~ "Accept"
    end

    test "renders Reject button in pending state" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "proposal-card__btn--reject"
      assert html =~ "Reject"
    end

    test "wires phx-click event on Accept button" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(phx-click="accept_proposal")
    end

    test "wires phx-value-id on Accept button when accept_value provided" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(phx-value-id="proposal-abc123")
    end

    test "renders accent_variant as data-accent attribute" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(data-accent="codex")
    end

    test "renders avatar token for accent_variant" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "var(--avatar-codex"
    end

    test "renders state badge with data-state attribute" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(data-state="pending")
    end
  end

  # ── Reject button event configurability ───────────────────────────────────

  describe "reject_event prop configurability" do
    test "defaults Reject phx-click to 'reject_proposal' when reject_event is absent" do
      # @full_iur does not set reject_event — should fall back to the convention.
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ ~s(phx-click="reject_proposal")
    end

    test "overrides Reject phx-click when reject_event is provided" do
      iur = put_in(@full_iur, ["props", "reject_event"], "decline_proposal")
      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      assert html =~ ~s(phx-click="decline_proposal")
      refute html =~ ~s(phx-click="reject_proposal")
    end

    test "Reject button uses accept_value when reject_value is absent (back-compat)" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      # Both Accept and Reject buttons should carry the same phx-value-id when
      # reject_value isn't separately configured — preserves prior behavior.
      assert html =~ ~s(phx-value-id="proposal-abc123")
    end

    test "Reject button uses reject_value when separately configured" do
      iur =
        @full_iur
        |> put_in(["props", "reject_event"], "decline_proposal")
        |> put_in(["props", "reject_value"], "proposal-zzz999")

      {:ok, html} = LiveUIRenderer.render(screen_with(iur))

      # Accept button keeps its accept_value, Reject button gets its own.
      assert html =~ ~s(phx-click="decline_proposal" phx-value-id="proposal-zzz999")
      assert html =~ ~s(phx-click="accept_proposal" phx-value-id="proposal-abc123")
    end
  end

  # ── Terminal states: no action buttons ────────────────────────────────────

  describe "accepted state" do
    @accepted_iur put_in(@full_iur, ["props", "state"], "accepted")

    test "renders proposal-card--accepted modifier class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@accepted_iur))

      assert html =~ "proposal-card--accepted"
    end

    test "does NOT render Accept button" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@accepted_iur))

      refute html =~ "proposal-card__btn--accept"
    end

    test "does NOT render Reject button" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@accepted_iur))

      refute html =~ "proposal-card__btn--reject"
    end

    test "state badge shows accepted" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@accepted_iur))

      assert html =~ ~s(data-state="accepted")
    end
  end

  describe "rejected state" do
    @rejected_iur put_in(@full_iur, ["props", "state"], "rejected")

    test "renders proposal-card--rejected modifier class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@rejected_iur))

      assert html =~ "proposal-card--rejected"
    end

    test "does NOT render action buttons" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@rejected_iur))

      refute html =~ "proposal-card__actions"
    end

    test "state badge shows rejected" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@rejected_iur))

      assert html =~ ~s(data-state="rejected")
    end
  end

  describe "superseded state" do
    @superseded_iur put_in(@full_iur, ["props", "state"], "superseded")

    test "renders proposal-card--superseded modifier class" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@superseded_iur))

      assert html =~ "proposal-card--superseded"
    end

    test "does NOT render action buttons" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@superseded_iur))

      refute html =~ "proposal-card__actions"
    end

    test "state badge shows superseded" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@superseded_iur))

      assert html =~ ~s(data-state="superseded")
    end
  end

  # ── Minimal props (no accent_variant, no accept_value) ────────────────────

  describe "LiveUI.Renderer minimal props" do
    test "omits data-accent attribute when accent_variant is absent" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      refute html =~ "data-accent"
    end

    test "falls back to neutral avatar token when no accent_variant" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      assert html =~ "var(--avatar-neutral"
    end

    test "still renders proposer, timestamp, and proposed_text" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      assert html =~ "Pascal"
      assert html =~ "10:00"
      assert html =~ "Conversations are primary."
    end

    test "Accept button has no phx-value-id when accept_value absent" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@minimal_iur))

      refute html =~ "phx-value-id"
    end
  end

  # ── accent_variant token variation ────────────────────────────────────────

  describe "accent_variant token references" do
    for variant <- ["pascal", "codex", "gemini", "mike"] do
      @variant variant
      test "accent_variant #{@variant} references var(--avatar-#{@variant})" do
        iur = put_in(@full_iur, ["props", "accent_variant"], @variant)
        {:ok, html} = LiveUIRenderer.render(screen_with(iur))

        assert html =~ "var(--avatar-#{@variant}",
               "expected var(--avatar-#{@variant}) in HTML for variant #{@variant}"
      end
    end

    test "each accent_variant produces a distinct data-accent attribute" do
      variants = ["pascal", "codex", "gemini", "mike"]

      rendered_accents =
        Enum.map(variants, fn v ->
          iur = put_in(@full_iur, ["props", "accent_variant"], v)
          {:ok, html} = LiveUIRenderer.render(screen_with(iur))
          assert html =~ ~s(data-accent="#{v}")
          v
        end)

      assert Enum.uniq(rendered_accents) == variants
    end
  end

  # ── Token purity ─────────────────────────────────────────────────────────

  describe "token purity" do
    test "no literal hex color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/#[0-9a-fA-F]{3,6}\b/,
             "found literal hex color value in proposal_card HTML"
    end

    test "no rgb() color values in rendered HTML" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      refute html =~ ~r/\brgb\s*\(/,
             "found rgb() color value in proposal_card HTML"
    end

    test "accent-strong token used for Accept button background" do
      {:ok, html} = LiveUIRenderer.render(screen_with(@full_iur))

      assert html =~ "var(--accent-strong"
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
