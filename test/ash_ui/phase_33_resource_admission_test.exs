defmodule AshUI.Phase33ResourceAdmissionTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  @moduletag :conformance

  describe "Section 33 - composer query preview admission" do
    test "resource and persisted DSL authoring admit composer_query_preview" do
      definition = %{
        type: :composer_query_preview,
        props: %{composer_id: "composer-main", query: "release blockers"},
        variants: [],
        metadata: %{}
      }

      assert Authoring.validate_element_definition!(definition) == definition

      assert Storage.canonical_widget_type(:composer_query_preview) ==
               {:ok, "composer_query_preview"}

      assert Storage.validate_write(%{
               type: "composer_query_preview",
               props: %{"composer_id" => "composer-main", "query" => "release blockers"},
               children: [],
               signals: [],
               metadata: %{}
             }) == :ok
    end

    test "composer_query_preview exposes click-based action admission" do
      definition = %{type: :composer_query_preview, props: %{}, variants: [], metadata: %{}}

      assert :ok =
               Authoring.validate_element_authority!(
                 definition,
                 [],
                 [
                   %{
                     id: :open_query_preview,
                     signal: :click,
                     source: "query_preview",
                     target: "preview"
                   }
                 ]
               )

      assert_raise ArgumentError, ~r/supported signals/, fn ->
        Authoring.validate_element_authority!(
          definition,
          [],
          [
            %{
              id: :submit_query_preview,
              signal: :submit,
              source: "query_preview",
              target: "preview"
            }
          ]
        )
      end
    end
  end
end
