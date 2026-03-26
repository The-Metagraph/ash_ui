defmodule AshUI.Phase9IntegrationTest do
  use ExUnit.Case, async: false

  alias AshUI.Authoring.{Document, Screen}
  alias AshUI.DSL.Builder
  alias AshUI.Telemetry
  alias AshUI.Test.{AuthoredCustomWidgetScreen, AuthoredSupportScreen, UIStorageFixtures}

  @moduletag :conformance

  setup do
    Telemetry.reset_metrics()
    :ok
  end

  describe "Section 9.4.1 - authoring boundary scenarios" do
    test "a screen defined through upstream unified_ui can be persisted with semantic widgets intact" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Screen.create(AuthoredSupportScreen,
                 ui_storage: ui_storage,
                 route: "/phase-9",
                 layout: :column,
                 metadata: %{"seed" => "phase_9"},
                 binding_metadata: %{"profile_form" => %{"intent" => "save_profile"}}
               )

      assert Document.authoring_document?(screen.unified_dsl)
      assert get_in(screen.unified_dsl, ["ash_ui", "metadata", "seed"]) == "phase_9"
      assert screen.unified_dsl["version"] == Document.version()

      composition_summary =
        screen.unified_dsl
        |> get_in(["authoring", "document", "composition_summary"])
        |> flatten_nodes()

      assert Enum.any?(composition_summary, &(&1["kind"] == "hero"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "stat"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "key_value"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "info_list"))
      assert Enum.any?(composition_summary, &(&1["kind"] == "form_field"))
    end

    test "invalid upstream DSL errors surface clearly through Ash UI" do
      assert {:error, {:invalid_unified_ui_module, String, message}} =
               Screen.screen_attrs(String)

      assert is_binary(message)
      assert message != ""
    end

    test "custom upstream authoring extensions persist and builder-first authoring is signaled as legacy" do
      handler_id = "phase-9-legacy-builder-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:ash_ui, :authoring, :legacy_builder],
        fn _, measurements, metadata, _ ->
          send(self(), {:legacy_builder, measurements, metadata})
        end,
        :ok
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, attrs} =
               Screen.screen_attrs(AuthoredCustomWidgetScreen, route: "/phase-9/custom")

      composition_summary =
        attrs.unified_dsl
        |> get_in(["authoring", "document", "composition_summary"])
        |> flatten_nodes()

      assert Enum.any?(composition_summary, fn node ->
               node["id"] == "banner_shell" and node["kind"] == "content"
             end)

      _legacy =
        Builder.column(
          children: [
            Builder.text("Legacy compatibility")
          ]
        )
        |> Builder.to_store()

      assert_receive {:legacy_builder, measurements, metadata}
      assert measurements.count == 1
      assert metadata.authoring_mode == :legacy_builder
      assert metadata.source == :builder_to_store
    end
  end

  defp flatten_nodes(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, fn node ->
      [node | flatten_nodes(Map.get(node, "children", []))]
    end)
  end
end
