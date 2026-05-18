defmodule UnifiedUi.RightRailCompilerTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule RightRailScreen do
    use UnifiedUi.Dsl

    identity do
      id(:right_rail_screen)
      authored_ref([:tests, :right_rail_screen])
    end

    composition do
      root(:right_rail_root)

      right_rail :inspector_rail do
        panels([
          %{id: :summary, label: "Summary", content_slot: :summary_body},
          %{id: :activity, label: "Activity", disabled?: true, empty_state: "No activity"}
        ])

        active_panel(:summary)
        panel_select_intent(:select_panel)
        collapse_intent(:set_collapsed)
      end
    end
  end

  test "DSL entity registers right_rail as a layer shell and callout component" do
    kinds = UnifiedUi.Dsl.Entities.WidgetComponents.layer_callout_kinds()

    assert :right_rail in kinds
    refute :doc_right_rail in kinds

    [summary] =
      RightRailScreen
      |> UnifiedUi.Info.composition_summary()
      |> Enum.filter(&(&1.kind == :right_rail))

    assert summary.family == :layer_shell_and_callout

    assert summary.panels == [
             %{id: :summary, label: "Summary", content_slot: :summary_body},
             %{id: :activity, label: "Activity", disabled?: true, empty_state: "No activity"}
           ]
  end

  test "right_rail validation rejects active panels outside the descriptor set" do
    assert {:error, [:composition, :right_rail, :bad_rail], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :right_rail,
               id: :bad_rail,
               side: :right,
               panels: [%{id: :summary, label: "Summary"}],
               active_panel: :missing
             })

    assert message =~ "active_panel must reference"
  end

  test "right_rail validation rejects host-specific event and route fields" do
    assert {:error, [:composition, :right_rail, :bad_rail], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :right_rail,
               id: :bad_rail,
               side: :right,
               panels: [
                 %{"phx-click" => "select-summary", id: :summary, label: "Summary"}
               ],
               active_panel: :summary
             })

    assert message =~ "without host-specific event or route fields"
  end
end
