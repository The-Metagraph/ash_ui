defmodule UnifiedUi.ListRepeatCompilerHydrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Interaction, Tree}
  alias UnifiedUi.Compiler

  defmodule HydratedRepeatScreen do
    use UnifiedUi.Dsl

    identity do
      id(:hydrated_repeat_screen)
      authored_ref([:tests, :hydrated_repeat_screen])
    end

    signals do
      data_binding do
        id(:artifact_rows)
        path([:artifacts])
        collection?(true)

        default([
          %{id: "adr-1", title: "Widget ADR", status: :accepted},
          %{id: "adr-2", title: "Compiler ADR", status: :draft}
        ])
      end
    end

    composition do
      root(:hydrated_repeat_root)
      mode(:screen)

      list_repeat :artifact_repeat do
        repeat_binding(:artifact_rows)
        row_scope(:artifact)
        row_fields([:id, :title, :status])
        template_identity(:artifact_template)
        identity_strategy(:row_identity)

        artifact_row_template :artifact_template do
          title("Artifact")
          meta(%{status: :status})
          row_identity(:id)
          action_intent(:open_artifact)

          button :open_button do
            label("Open")
          end
        end
      end
    end
  end

  defmodule EmptyRepeatScreen do
    use UnifiedUi.Dsl

    identity do
      id(:empty_repeat_screen)
      authored_ref([:tests, :empty_repeat_screen])
    end

    signals do
      data_binding do
        id(:empty_rows)
        path([:empty])
        collection?(true)
        default([])
      end
    end

    composition do
      root(:empty_repeat_root)
      mode(:screen)

      list_repeat :empty_repeat do
        repeat_binding(:empty_rows)
        row_fields([:id])

        artifact_row_template :empty_template do
          title("Empty")
          row_identity(:id)
        end
      end
    end
  end

  test "preserves repeat metadata and hydrates one stable child per binding row" do
    iur = Compiler.iur!(HydratedRepeatScreen)
    repeat = Tree.find_by_id(iur, :artifact_repeat)

    assert repeat.kind == :list_repeat

    assert repeat.attributes.repeat == %{
             binding_id: :artifact_rows,
             binding_ref: %{
               kind: :binding_ref,
               id: :artifact_rows,
               name: :artifact_rows,
               path: [:artifacts],
               scope: []
             },
             row_scope: :artifact,
             row_fields: [:id, :title, :status],
             template_identity: :artifact_template,
             identity_strategy: :row_identity,
             child_slot: :default,
             hydrated?: true,
             row_count: 2,
             template: %{id: :artifact_template, type: :widget, kind: :artifact_row}
           }

    assert Enum.map(repeat.children, & &1.element.id) == [
             "artifact_repeat:adr-1:artifact_template",
             "artifact_repeat:adr-2:artifact_template"
           ]

    [first_child | _rest] = repeat.children
    first = first_child.element

    assert first.attributes.artifact == %{
             row_identity: "adr-1",
             title: "Artifact",
             meta: %{status: :accepted},
             active?: false,
             action_intent: :open_artifact
           }

    assert first.attributes.repeat_instance == %{
             source_repeat_id: :artifact_repeat,
             row_scope: :artifact,
             row_index: 0,
             values: %{id: "adr-1", title: "Widget ADR", status: :accepted}
           }

    assert [%Interaction{family: :click, intent: :open_artifact} = action] =
             first.attributes.interactions

    assert action.source == %{element_id: "artifact_repeat:adr-1:artifact_template"}
    assert action.payload == %{value: "adr-1", mapping: %{row_identity: :row_identity}}

    assert [%{element: nested_button}] = first.children
    assert nested_button.id == "artifact_repeat:adr-1:open_button"

    assert nested_button.attributes.repeat_instance.values == %{
             id: "adr-1",
             title: "Widget ADR",
             status: :accepted
           }
  end

  test "hydrates empty repeat bindings as deterministic empty child output" do
    iur = Compiler.iur!(EmptyRepeatScreen)
    repeat = Tree.find_by_id(iur, :empty_repeat)

    assert repeat.attributes.repeat.hydrated? == true
    assert repeat.attributes.repeat.row_count == 0

    assert repeat.attributes.repeat.template == %{
             id: :empty_template,
             type: :widget,
             kind: :artifact_row
           }

    assert repeat.children == []
  end
end
