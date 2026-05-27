defmodule UnifiedIUR.Widgets.LiveSessionCardTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Interaction, Validate}
  alias UnifiedIUR.Widgets.Components

  @session_id "550e8400-e29b-41d4-a716-446655440000"
  @started_at ~U[2026-05-27 15:00:00Z]

  describe "live_session_card constructor" do
    test "builds a valid running session card with deterministic id" do
      card = Components.live_session_card(valid_opts())

      assert %Element{kind: :live_session_card} = card
      assert card.id == "live_session:#{@session_id}:7"

      assert card.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :live_session_card
             }

      assert card.attributes.live_session.session_id == @session_id
      assert card.attributes.live_session.actor_handle == "@opus"
      assert card.attributes.live_session.status == :running
      assert card.attributes.live_session.status_version == 7
      assert card.attributes.live_session.tools_count == 3
      assert card.attributes.live_session.edits_count == 2
      assert card.attributes.live_session.tokens_consumed == 12_345
      assert card.attributes.live_session.started_at == @started_at
      assert card.attributes.live_session.pinned? == false

      assert [
               %Interaction{family: :command, payload: %{command: :pin_toggled}},
               %Interaction{family: :command, payload: %{command: :interrupted}},
               %Interaction{family: :command, payload: %{command: :expanded_recent}}
             ] = card.attributes.interactions

      assert :ok = Validate.element(card)
    end

    test "preserves optional streaming and recent activity fragments" do
      card =
        Components.live_session_card(
          valid_opts(
            current_step: "reading",
            current_task_title: "Implementing card",
            now_streaming: "Updating renderer wiring.",
            pinned?: true,
            recent_events: [
              %{kind: :assistant_text, body_fragment: "Working through tests."},
              %{kind: "tool_call", body: "mix test packages/unified_iur/test"}
            ]
          )
        )

      assert card.attributes.live_session.current_step == "reading"
      assert card.attributes.live_session.current_task_title == "Implementing card"
      assert card.attributes.live_session.now_streaming == "Updating renderer wiring."
      assert card.attributes.live_session.pinned? == true

      assert card.attributes.live_session.recent_events == [
               %{kind: :assistant_text, body: "Working through tests."},
               %{kind: "tool_call", body: "mix test packages/unified_iur/test"}
             ]

      assert :ok = Validate.element(card)
    end

    test "raises for non-running sessions, invalid meters, and excessive recent events" do
      assert_raise ArgumentError, ~r/status must be one of/, fn ->
        Components.live_session_card(valid_opts(status: :complete))
      end

      assert_raise ArgumentError, ~r/status_version must be a non-negative integer/, fn ->
        Components.live_session_card(valid_opts(status_version: -1))
      end

      assert_raise ArgumentError, ~r/tools_count must be a non-negative integer/, fn ->
        Components.live_session_card(valid_opts(tools_count: -1))
      end

      assert_raise ArgumentError, ~r/recent_events accepts at most 5/, fn ->
        Components.live_session_card(
          valid_opts(recent_events: List.duplicate(%{kind: :assistant_text, body: "event"}, 6))
        )
      end
    end

    test "raises when an explicit id does not match the synthetic key" do
      assert_raise ArgumentError, ~r/id must be deterministic/, fn ->
        Components.live_session_card(valid_opts(id: "live-session-card"))
      end
    end

    test "validates malformed raw cards with structured diagnostics" do
      invalid =
        Element.new(:widget, :live_session_card,
          id: "bad-id",
          attributes: %{
            component: %{family: :workflow_progress_and_status, kind: :live_session_card},
            live_session: %{
              session_id: "not-a-uuid",
              actor_handle: " ",
              status: :complete,
              status_version: -1,
              tools_count: -1,
              edits_count: "2",
              tokens_consumed: -3,
              started_at: "not-a-date",
              now_streaming: %{text: "bad"},
              recent_events: List.duplicate(%{kind: "", body: 10}, 6),
              pinned?: "false",
              actions: %{pause: %{event: :pause}}
            },
            interactions: []
          }
        )

      assert {:error, errors} = Validate.element(invalid)
      assert Enum.all?(errors, &(&1.code == :invalid_live_session_card))
      assert Enum.any?(errors, &(&1.path == [:attributes, :live_session, :session_id]))
      assert Enum.any?(errors, &(&1.path == [:attributes, :live_session, :recent_events]))
      assert Enum.any?(errors, &(&1.path == [:attributes, :interactions]))
    end
  end

  test "is included in workflow and aggregate component kind lists" do
    assert :live_session_card in Components.workflow_kinds()
    assert :live_session_card in Components.kinds()
  end

  defp valid_opts(overrides \\ []) do
    Keyword.merge(
      [
        session_id: @session_id,
        actor_handle: "@opus",
        status: :running,
        status_version: 7,
        tools_count: 3,
        edits_count: 2,
        tokens_consumed: 12_345,
        started_at: @started_at
      ],
      overrides
    )
  end
end
