defmodule AshUI.DSL.BuilderLegacyTest do
  use ExUnit.Case, async: false

  alias AshUI.Authoring.LegacyBuilder
  alias AshUI.DSL.Builder
  alias AshUI.Telemetry

  setup do
    Telemetry.reset_metrics()
    :ok
  end

  test "builder usage emits the legacy authoring telemetry event" do
    handler_id = "legacy-builder-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:ash_ui, :authoring, :legacy_builder],
      fn _, measurements, metadata, _ ->
        send(self(), {:legacy_builder_event, measurements, metadata})
      end,
      :ok
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    dsl =
      Builder.column(
        children: [
          Builder.text("Legacy dashboard")
        ]
      )

    stored = Builder.to_store(dsl)
    restored = Builder.from_store(stored)

    assert restored.type == "column"
    assert_receive {:legacy_builder_event, measurements, metadata}
    assert measurements.count == 1
    assert metadata.status == :legacy
    assert metadata.source in [:builder_to_store, :builder_from_store, :builder_validate]

    snapshot = Telemetry.snapshot()

    legacy_event =
      Enum.find(snapshot.events, fn definition ->
        definition.event_name == [:ash_ui, :authoring, :legacy_builder]
      end)

    assert legacy_event.count >= 1
  end

  test "documents removal criteria for builder-first authoring" do
    criteria = LegacyBuilder.removal_criteria()

    assert length(criteria) >= 4
    assert Enum.any?(criteria, &String.contains?(&1, "UnifiedUi.Compiler"))
    assert Enum.any?(criteria, &String.contains?(&1, "examples and guides"))
  end
end
