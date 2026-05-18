defmodule AshUI.Phase32ResourceAdmissionTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  @moduletag :conformance

  describe "Section 32.4 - Ash UI right rail admission" do
    test "resource and persisted DSL authoring admit right_rail" do
      definition = %{
        type: :right_rail,
        props: %{
          panels: [%{id: :summary, label: "Summary"}],
          active_panel: :summary
        },
        variants: [],
        metadata: %{}
      }

      assert Authoring.validate_element_definition!(definition) == definition
      assert Storage.canonical_widget_type(:right_rail) == {:ok, "right_rail"}

      assert Storage.validate_write(%{
               type: "right_rail",
               props: %{},
               children: [],
               signals: [],
               metadata: %{}
             }) == :ok
    end

    test "document-specific rail names remain custom extension names only" do
      assert {:error, diagnostic} = Storage.canonical_widget_type(:doc_right_rail)
      assert diagnostic.status == :unknown

      assert Storage.canonical_widget_type("custom:doc_right_rail") ==
               {:ok, "custom:doc_right_rail"}
    end

    test "right_rail exposes interactive action signals" do
      definition = %{type: :right_rail, props: %{}, variants: [], metadata: %{}}

      assert :ok =
               Authoring.validate_element_authority!(
                 definition,
                 [],
                 [
                   %{id: :select_panel, signal: :change, source: "rail", target: "active_panel"},
                   %{id: :toggle_rail, signal: :toggle, source: "rail", target: "collapsed"}
                 ]
               )

      assert_raise ArgumentError, ~r/supported signals/, fn ->
        Authoring.validate_element_authority!(
          definition,
          [],
          [%{id: :submit_rail, signal: :submit, source: "rail", target: "rail"}]
        )
      end
    end
  end
end
