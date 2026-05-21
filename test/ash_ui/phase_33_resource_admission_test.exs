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

  describe "collection picker admission" do
    test "resource and persisted DSL authoring admit collection_picker" do
      definition = %{
        type: :collection_picker,
        props: %{picker_id: "sources", items: [%{id: "adr-1", label: "ADR 1"}]},
        variants: [],
        metadata: %{}
      }

      assert Authoring.validate_element_definition!(definition) == definition
      assert Storage.canonical_widget_type(:collection_picker) == {:ok, "collection_picker"}

      assert Storage.validate_write(%{
               type: "collection_picker",
               props: %{
                 "picker_id" => "sources",
                 "items" => [%{"id" => "adr-1", "label" => "ADR 1"}]
               },
               children: [],
               signals: [],
               metadata: %{}
             }) == :ok
    end

    test "collection_picker exposes collection and action admission" do
      definition = %{type: :collection_picker, props: %{}, variants: [], metadata: %{}}

      assert :ok =
               Authoring.validate_element_authority!(
                 definition,
                 [%{id: :items, binding_type: :list, target: "items", source: %{path: "items"}}],
                 [
                   %{
                     id: :select_source,
                     signal: :click,
                     source: "collection_picker",
                     target: "selection"
                   },
                   %{
                     id: :filter_sources,
                     signal: :toggle,
                     source: "collection_picker",
                     target: "filters"
                   }
                 ]
               )
    end
  end

  describe "workflow progress status admission" do
    test "resource and persisted DSL authoring admit workflow_progress_status_card" do
      definition = %{
        type: :workflow_progress_status_card,
        props: %{subject_id: "subject:release-readiness", name: "Release readiness"},
        variants: [],
        metadata: %{}
      }

      assert Authoring.validate_element_definition!(definition) == definition

      assert Storage.canonical_widget_type(:workflow_progress_status_card) ==
               {:ok, "workflow_progress_status_card"}

      assert Storage.validate_write(%{
               type: "workflow_progress_status_card",
               props: %{
                 "subject_id" => "subject:release-readiness",
                 "name" => "Release readiness"
               },
               children: [],
               signals: [],
               metadata: %{}
             }) == :ok
    end

    test "workflow_progress_status_card exposes semantic action admission" do
      definition = %{
        type: :workflow_progress_status_card,
        props: %{},
        variants: [],
        metadata: %{}
      }

      assert :ok =
               Authoring.validate_element_authority!(
                 definition,
                 [],
                 [
                   %{
                     id: :open_release,
                     signal: :click,
                     source: "workflow_progress_status_card",
                     target: "open"
                   },
                   %{
                     id: :focus_dependency,
                     signal: :change,
                     source: "workflow_progress_status_card",
                     target: "dependency"
                   }
                 ]
               )

      assert_raise ArgumentError, ~r/supported signals/, fn ->
        Authoring.validate_element_authority!(
          definition,
          [],
          [
            %{
              id: :submit_release,
              signal: :submit,
              source: "workflow_progress_status_card",
              target: "open"
            }
          ]
        )
      end
    end
  end
end
