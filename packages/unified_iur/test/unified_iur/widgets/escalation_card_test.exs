defmodule UnifiedIUR.Widgets.EscalationCardTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Validate}
  alias UnifiedIUR.Widgets.Components

  describe "escalation_card constructor" do
    test "emits canonical layer_shell_and_callout component metadata" do
      card =
        Components.escalation_card(
          id: "esc-1",
          target_project_id: "ariston-ui",
          severity: :p2,
          text: "Coverage gap detected."
        )

      assert %Element{type: :widget, kind: :escalation_card} = card

      assert card.attributes.component == %{
               family: :layer_shell_and_callout,
               kind: :escalation_card
             }

      assert %{target_project_id: "ariston-ui", severity: :p2, text: "Coverage gap detected."} =
               card.attributes.escalation

      assert :ok = Validate.element(card)
    end

    test "accepts all three severity values" do
      for severity <- [:p1, :p2, :p3] do
        card =
          Components.escalation_card(
            id: "esc-#{severity}",
            target_project_id: "proj",
            severity: severity,
            text: "Test."
          )

        assert card.attributes.escalation.severity == severity
        assert :ok = Validate.element(card)
      end
    end

    test "accepts severity as binary and normalizes to atom" do
      card =
        Components.escalation_card(
          id: "esc-bin",
          target_project_id: "proj",
          severity: "p1",
          text: "Test."
        )

      assert card.attributes.escalation.severity == :p1
    end

    test "stores optional fields when present" do
      card =
        Components.escalation_card(
          id: "esc-full",
          target_project_id: "ariston-ui",
          severity: :p1,
          text: "P1 escalation.",
          related_finding_id: "finding-42",
          proposed_action: "Patch the gap immediately",
          actor_handle: "@codex",
          escalated_at: "2026-05-27T10:00:00Z",
          target_finding_id: "finding-43",
          target_severity: :p2,
          originating_severity: :p3
        )

      esc = card.attributes.escalation

      assert esc.related_finding_id == "finding-42"
      assert esc.proposed_action == "Patch the gap immediately"
      assert esc.actor_handle == "@codex"
      assert esc.escalated_at == "2026-05-27T10:00:00Z"
      assert esc.target_finding_id == "finding-43"
      assert esc.target_severity == :p2
      assert esc.originating_severity == :p3

      assert :ok = Validate.element(card)
    end

    test "raises when target_project_id is missing" do
      assert_raise ArgumentError, ~r/target_project_id/, fn ->
        Components.escalation_card(severity: :p2, text: "Test.")
      end
    end

    test "raises when text is missing" do
      assert_raise ArgumentError, ~r/text/, fn ->
        Components.escalation_card(target_project_id: "proj", severity: :p2)
      end
    end

    test "raises on unknown severity" do
      assert_raise ArgumentError, ~r/severity/, fn ->
        Components.escalation_card(
          target_project_id: "proj",
          severity: :critical,
          text: "Test."
        )
      end
    end

    test "emits default interactions for acknowledge and route_to_rail" do
      card =
        Components.escalation_card(
          id: "esc-default",
          target_project_id: "ariston-ui",
          severity: :p2,
          text: "Test."
        )

      interactions = Map.get(card.attributes, :interactions, [])
      commands = Enum.map(interactions, & &1.payload.command)

      assert :acknowledge in commands
      assert :route_to_rail in commands
    end
  end

  describe "escalation_card validation" do
    test "returns :ok for a well-formed element" do
      card =
        Components.escalation_card(
          id: "esc-ok",
          target_project_id: "proj",
          severity: :p3,
          text: "Low-priority gap."
        )

      assert :ok = Validate.element(card)
    end

    test "returns :invalid_escalation_card when target_project_id is blank" do
      card =
        Element.new(:widget, :escalation_card,
          attributes: %{
            component: %{family: :layer_shell_and_callout, kind: :escalation_card},
            escalation: %{target_project_id: "", severity: :p2, text: "Test."}
          }
        )

      assert {:error, errors} = Validate.element(card)
      assert Enum.any?(errors, &(&1.code == :invalid_escalation_card))
    end

    test "returns :invalid_escalation_card when text is blank" do
      card =
        Element.new(:widget, :escalation_card,
          attributes: %{
            component: %{family: :layer_shell_and_callout, kind: :escalation_card},
            escalation: %{target_project_id: "proj", severity: :p2, text: ""}
          }
        )

      assert {:error, errors} = Validate.element(card)
      assert Enum.any?(errors, &(&1.code == :invalid_escalation_card))
    end

    test "returns :invalid_escalation_card when severity is unknown" do
      card =
        Element.new(:widget, :escalation_card,
          attributes: %{
            component: %{family: :layer_shell_and_callout, kind: :escalation_card},
            escalation: %{target_project_id: "proj", severity: :critical, text: "Test."}
          }
        )

      assert {:error, errors} = Validate.element(card)
      assert Enum.any?(errors, &(&1.code == :invalid_escalation_card))
    end

    test "returns :invalid_escalation_card when escalation is not a map" do
      card =
        Element.new(:widget, :escalation_card,
          attributes: %{
            component: %{family: :layer_shell_and_callout, kind: :escalation_card},
            escalation: "not-a-map"
          }
        )

      assert {:error, errors} = Validate.element(card)
      assert Enum.any?(errors, &(&1.code == :invalid_escalation_card))
    end

    test "returns :invalid_escalation_card when optional string field is non-string" do
      card =
        Element.new(:widget, :escalation_card,
          attributes: %{
            component: %{family: :layer_shell_and_callout, kind: :escalation_card},
            escalation: %{
              target_project_id: "proj",
              severity: :p2,
              text: "Test.",
              actor_handle: 123
            }
          }
        )

      assert {:error, errors} = Validate.element(card)
      assert Enum.any?(errors, &(&1.code == :invalid_escalation_card))
    end
  end

  describe "escalation_card is in @layer_callout_kinds" do
    test "escalation_card is classified as a layer callout kind" do
      card =
        Components.escalation_card(
          id: "esc-family",
          target_project_id: "ariston-ui",
          severity: :p2,
          text: "Test."
        )

      assert card.attributes.component.family == :layer_shell_and_callout
    end
  end
end
