defmodule UnifiedUi.ListRepeatComponentsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule RepeatScreen do
    use UnifiedUi.Dsl

    identity do
      id(:repeat_screen)
      authored_ref([:examples, :repeat_screen])
    end

    signals do
      data_binding do
        id(:artifact_rows)
        path([:artifacts])
        collection?(true)
      end

      data_binding do
        id(:event_rows)
        path([:events])
        collection?(true)
      end
    end

    composition do
      root(:repeat_root)
      mode(:screen)

      list_repeat :artifact_repeat do
        repeat_binding(:artifact_rows)
        row_scope(:artifact)
        row_fields([:id, :title, :status])
        template_identity(:artifact_row_template)
        identity_strategy(:row_identity)

        artifact_row_template :artifact_template do
          title("Artifact template")
          meta(%{status: :row_scoped})
          row_identity(:id)
        end
      end

      list_repeat :event_repeat do
        repeat_binding(:event_rows)
        row_scope(:event)
        row_fields([:id, :message, :tone])
        template_identity(:event_callout_template)

        event_callout_template :event_template do
          tone(:info)
          message("Event template")
        end
      end
    end
  end

  test "registers list-repeat as a composition behavior component" do
    assert UnifiedUi.Widgets.composition_behavior_component_kinds() == [:list_repeat]
    assert :list_repeat in UnifiedUi.Widgets.kinds()
    assert :list_repeat in UnifiedUi.Widgets.component_kinds()
  end

  test "stores repeat metadata and exactly one child template per repeat" do
    [artifact_repeat, event_repeat] = Extension.get_entities(RepeatScreen, [:composition])

    assert {artifact_repeat.family, artifact_repeat.kind, artifact_repeat.repeat_binding,
            artifact_repeat.row_scope, artifact_repeat.identity_strategy} ==
             {:composition_behavior, :list_repeat, :artifact_rows, :artifact, :row_identity}

    assert Enum.map(artifact_repeat.children, & &1.kind) == [:artifact_row]

    assert {event_repeat.repeat_binding, event_repeat.row_fields, event_repeat.template_identity} ==
             {:event_rows, [:id, :message, :tone], :event_callout_template}

    assert Enum.map(event_repeat.children, & &1.kind) == [:event_callout]
  end

  test "summarizes repeat inspection metadata deterministically" do
    summary =
      RepeatScreen
      |> UnifiedUi.Info.composition_summary()
      |> Map.new(&{&1.id, &1})

    assert %{
             family: :composition_behavior,
             kind: :list_repeat,
             repeat_binding: :artifact_rows,
             row_scope: :artifact,
             row_fields: [:id, :title, :status],
             template_identity: :artifact_row_template,
             identity_strategy: :row_identity,
             children: [
               %{
                 id: :artifact_template,
                 family: :row_and_artifact,
                 kind: :artifact_row,
                 row_identity: :id
               }
             ]
           } = summary.artifact_repeat

    assert %{
             repeat_binding: :event_rows,
             row_scope: :event,
             children: [%{kind: :event_callout, message: "Event template"}]
           } = summary.event_repeat
  end

  test "validates repeat structure before binding context" do
    assert {:error, [:composition, :list_repeat, :bad_repeat], child_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :list_repeat,
               id: :bad_repeat,
               repeat_binding: :rows,
               row_scope: :row,
               row_fields: [:id],
               children: []
             })

    assert child_message =~ "must declare exactly one child template"

    assert {:error, [:composition, :list_repeat, :deep_repeat], field_message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :list_repeat,
               id: :deep_repeat,
               repeat_binding: :rows,
               row_scope: :row,
               row_fields: ["user.name"],
               children: [%Node{kind: :artifact_row}]
             })

    assert field_message =~ "without host-specific path syntax"
  end

  test "rejects missing and non-collection repeat bindings at compile time" do
    assert_compile_dsl_error(
      """
      identity do
        id(:missing_repeat_binding_screen)
        authored_ref([:examples, :missing_repeat_binding_screen])
      end

      composition do
        root(:missing_repeat_binding_root)

        list_repeat :missing_repeat do
          repeat_binding(:missing_rows)
          row_fields([:id])

          artifact_row_template :template do
            title("Template")
            row_identity(:id)
          end
        end
      end
      """,
      "repeat_binding :missing_rows must reference a declared data_binding"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:scalar_repeat_binding_screen)
        authored_ref([:examples, :scalar_repeat_binding_screen])
      end

      signals do
        data_binding do
          id(:profile)
          path([:profile])
          collection?(false)
        end
      end

      composition do
        root(:scalar_repeat_binding_root)

        list_repeat :scalar_repeat do
          repeat_binding(:profile)
          row_fields([:id])

          artifact_row_template :template do
            title("Template")
            row_identity(:id)
          end
        end
      end
      """,
      "repeat_binding :profile must reference a collection data_binding"
    )
  end

  test "tooling links repeat behavior to widget and signal specs" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(RepeatScreen)

    assert :composition_behavior in report.construct_families
    assert ".spec/specs/unified-ui/widget_components.spec.md" in report.related_specs
    assert ".spec/specs/unified-ui/signals.spec.md" in report.related_specs
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.ListRepeatComponentsTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
