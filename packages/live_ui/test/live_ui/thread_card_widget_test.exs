defmodule LiveUi.ThreadCardWidgetTest do
  @moduledoc """
  Stage-4 tests for `LiveUi.Widgets.ThreadCard`.

  Verifies:
  - `data-live-ui-widget="thread-card"` root attribute (true-widget, not component-kind fallback)
  - `data-thread-id` selector hook
  - Title renders in an `<h3>`
  - Seed quote renders in `<blockquote>`
  - Reply count in footer
  - Avatar stack renders participants (up to 3 + overflow indicator)
  - Progress bar renders with ARIA when `progress_pct` is present
  - Open button `aria-label` and `data-live-ui-intent`
  - Renderer dispatches to `LiveUi.Widgets.ThreadCard` (not generic fallback)
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Widgets.Components

  # ---------------------------------------------------------------------------
  # Stage-4 Phoenix.Component direct render tests
  # ---------------------------------------------------------------------------

  describe "ThreadCard Phoenix.Component" do
    test "renders with the true-widget data attribute (not component-kind fallback)" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-1",
          thread_id: "t-abc",
          title: "API design discussion",
          reply_count: 5,
          seed_quote: "Should we use REST or GraphQL here?",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ ~s(data-live-ui-widget="thread-card")
      refute html =~ ~s(data-live-ui-component-kind)
    end

    test "renders data-thread-id selector hook" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-2",
          thread_id: "unique-thread-id",
          title: "Test thread",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ ~s(data-thread-id="unique-thread-id")
    end

    test "renders title in h3 with correct BEM class" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-3",
          thread_id: "t-1",
          title: "My thread title",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "live-ui-thread-card__title"
      assert html =~ "My thread title"
    end

    test "renders seed quote in blockquote" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-4",
          thread_id: "t-2",
          title: "Thread",
          reply_count: 0,
          seed_quote: "This is the opening quote",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "<blockquote"
      assert html =~ "live-ui-thread-card__seed-quote"
      assert html =~ "This is the opening quote"
    end

    test "renders reply count in footer meta" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-5",
          thread_id: "t-3",
          title: "Thread",
          reply_count: 12,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "12"
      assert html =~ "replies"
      assert html =~ "live-ui-thread-card__meta"
    end

    test "pluralizes reply count correctly (1 reply vs N replies)" do
      single_html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-5a",
          thread_id: "t-s",
          title: "T",
          reply_count: 1,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      multi_html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-5b",
          thread_id: "t-m",
          title: "T",
          reply_count: 3,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert single_html =~ "1 reply"
      refute single_html =~ "1 replies"
      assert multi_html =~ "3 replies"
    end

    test "renders open button with aria-label and BEM class" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-6",
          thread_id: "t-4",
          title: "Open me",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "live-ui-thread-card__open"
      assert html =~ ~s(aria-label="Open thread: Open me")
      assert html =~ ~s(data-live-ui-intent="open_thread")
    end

    test "renders open button with custom open_intent" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-7",
          thread_id: "t-5",
          title: "Nav thread",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "navigate_thread"
        })

      assert html =~ ~s(data-live-ui-intent="navigate_thread")
    end

    test "renders avatar stack for up to 3 participants" do
      participants = [
        %{actor_name: "Pascal", avatar: %{initials: "PC"}},
        %{actor_name: "Matt", avatar: %{initials: "MD"}},
        %{actor_name: "Claude", avatar: %{initials: "CL"}}
      ]

      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-8",
          thread_id: "t-6",
          title: "Thread",
          reply_count: 0,
          seed_quote: "",
          participants: participants,
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "live-ui-thread-card__avatars"
      assert html =~ "live-ui-thread-card__avatar"
      assert html =~ "PC"
      assert html =~ "MD"
      assert html =~ "CL"
      refute html =~ "live-ui-thread-card__avatar-overflow"
    end

    test "renders overflow indicator for more than 3 participants" do
      participants = [
        %{actor_name: "A", avatar: %{initials: "A1"}},
        %{actor_name: "B", avatar: %{initials: "B1"}},
        %{actor_name: "C", avatar: %{initials: "C1"}},
        %{actor_name: "D", avatar: %{initials: "D1"}},
        %{actor_name: "E", avatar: %{initials: "E1"}}
      ]

      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-9",
          thread_id: "t-7",
          title: "Thread",
          reply_count: 0,
          seed_quote: "",
          participants: participants,
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "live-ui-thread-card__avatar-overflow"
      assert html =~ "+2"
      assert html =~ ~s(aria-label="and 2 more participants")
    end

    test "renders progress bar with ARIA when progress_pct is present" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-10",
          thread_id: "t-8",
          title: "In-flight",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: 0.65,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      assert html =~ "live-ui-thread-card__progress"
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="65")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(data-progress-pct="0.65")
      assert html =~ "live-ui-thread-card__progress-fill"
    end

    test "omits progress bar when progress_pct is nil" do
      html =
        render_component(&LiveUi.Widgets.ThreadCard.render/1, %{
          id: "tc-11",
          thread_id: "t-9",
          title: "Idle thread",
          reply_count: 0,
          seed_quote: "",
          participants: [],
          progress_pct: nil,
          last_activity_at: nil,
          open_intent: "open_thread"
        })

      refute html =~ "live-ui-thread-card__progress"
      refute html =~ "progressbar"
    end
  end

  # ---------------------------------------------------------------------------
  # Renderer dispatch tests (Stage 3 → Stage 4 wiring)
  # ---------------------------------------------------------------------------

  describe "Renderer dispatches :thread_card to LiveUi.Widgets.ThreadCard" do
    test "renderer produces true-widget attr (not component-kind fallback) for thread_card IUR" do
      element =
        Components.thread_card(
          thread_id: "t-r1",
          title: "Renderer dispatch test",
          reply_count: 3,
          seed_quote: "Checking wiring"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-widget="thread-card")
      refute html =~ ~s(data-live-ui-component-kind="thread_card")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end

    test "renderer propagates thread_id and title from IUR element" do
      element =
        Components.thread_card(
          thread_id: "t-r2",
          title: "Propagation test",
          reply_count: 0,
          seed_quote: ""
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-thread-id="t-r2")
      assert html =~ "Propagation test"
    end
  end
end
