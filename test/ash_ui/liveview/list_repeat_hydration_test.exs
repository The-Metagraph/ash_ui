defmodule AshUI.LiveView.ListRepeatHydrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.LiveView.IURHydration
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Resource.Authority
  alias AshUI.Resource.Info
  alias AshUI.Resources.Screen
  alias AshUI.Resources.Validations.BindingSource
  alias AshUI.Test.Phase31InvalidHasOneRepeatScreen
  alias AshUI.Test.Phase31InvalidMissingRepeatBindingScreen
  alias AshUI.Test.Phase31RepeatScreen

  @moduletag :conformance

  describe "Section 31.5 - list repeat composition behavior" do
    test "relationship repeat declarations validate against destination list bindings and encode payload metadata" do
      assert {:ok, [edge]} = Info.composition_edges(Phase31RepeatScreen)

      assert edge.repeat == %{
               binding_id: :artifact_rows,
               row_scope: :row,
               row_fields: [:id, :title, :status]
             }

      assert {:ok, attrs} =
               Authority.screen_attrs(Phase31RepeatScreen,
                 name: "phase_31_repeat_screen"
               )

      repeat =
        get_in(attrs.unified_dsl, ["composition", "roots", Access.at(0), "relationship", "repeat"])

      assert repeat == %{
               "binding_id" => "artifact_rows",
               "row_scope" => "row",
               "row_fields" => ["id", "title", "status"]
             }

      assert {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)
      assert {:ok, iur} = Compiler.compile(screen, use_cache: false)
      assert [%{type: :list_repeat} = repeat_iur] = iur.children
      assert repeat_iur.props["repeat_binding"] == "artifact_rows"
      assert repeat_iur.metadata["composition"]["repeat"] == repeat
    end

    test "rejects repeat declarations on non-has-many relationships" do
      assert {:error,
              {:invalid_repeat_relationship, Phase31InvalidHasOneRepeatScreen, :repeat_region,
               :requires_has_many}} =
               Info.composition_edges(Phase31InvalidHasOneRepeatScreen)
    end

    test "rejects repeat declarations when the destination lacks the referenced list binding" do
      assert {:error,
              {:invalid_repeat_relationship, Phase31InvalidMissingRepeatBindingScreen,
               :hero_elements, {:missing_list_binding, :missing_rows}}} =
               Info.composition_edges(Phase31InvalidMissingRepeatBindingScreen)
    end

    test "row-scoped value sources validate without a resource reference" do
      assert :ok = BindingSource.validate_source(%{scope: :row, field: :title}, :value)

      assert {:error, "row-scoped value bindings must include a field"} =
               BindingSource.validate_source(%{scope: :row}, :value)
    end

    test "hydrates list_repeat templates into concrete row children" do
      ash_iur =
        IUR.new(:screen,
          name: "phase31-repeat",
          children: [
            IUR.new(:list_repeat,
              id: "artifact-repeat",
              props: %{
                repeat_binding: :artifact_rows,
                row_scope: :row,
                row_fields: [:id, :title, :status]
              },
              children: [
                IUR.new(:artifact_row,
                  id: "artifact-template",
                  props: %{
                    row_identity: %{scope: :row, field: :id},
                    title: %{scope: :row, field: :title},
                    meta: %{status: %{scope: :row, field: :status}}
                  }
                )
              ]
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      hydrated =
        IURHydration.hydrate(canonical, %{
          "artifact-repeat" => %{
            element_id: "artifact-repeat",
            binding_type: :list,
            target: "artifact_rows",
            value: %{
              items: [
                %{"id" => "adr-0007", "title" => "Canonical widgets", "status" => "accepted"}
              ],
              total: 1,
              page: 1
            }
          }
        })

      [repeat] = hydrated["children"]
      assert repeat["type"] == "list_repeat"
      assert repeat["props"]["hydrated?"] == true
      assert repeat["props"]["row_count"] == 1
      assert repeat["props"]["binding_id"] == :artifact_rows

      [row] = repeat["children"]
      assert row["id"] == "artifact-template:row:adr-0007:0"
      assert row["props"]["row_identity"] == "adr-0007"
      assert row["props"]["title"] == "Canonical widgets"
      assert row["props"]["meta"]["status"] == "accepted"
      assert row["metadata"]["repeat"] == %{"row_index" => 0, "row_identity" => "adr-0007"}
    end
  end
end
