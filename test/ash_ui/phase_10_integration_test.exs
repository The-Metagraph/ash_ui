defmodule AshUI.Phase10IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Authoring
  alias AshUI.Compiler
  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.DSL.Builder
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ResourceAuthorityScreen, ScreenDocumentFixtures, UIStorageFixtures}

  @moduletag :conformance

  setup do
    ui_storage = UIStorageFixtures.ui_storage_config()

    %{
      ui_storage: ui_storage,
      screen_resource: Config.screen_resource(ui_storage)
    }
  end

  describe "Section 10.4.1 - stored document migration scenarios" do
    test "resource-authority screens persist successfully", %{ui_storage: ui_storage} do
      assert {:ok, screen} =
               Authoring.create_screen(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 name: "phase10_resource_authority",
                 route: "/phase-10/resource-authority",
                 layout: :column,
                 metadata: %{"seed" => "phase_10"}
               )

      assert Authority.authority_payload?(screen.unified_dsl)
      assert get_in(screen.unified_dsl, ["screen", "module"]) ==
               "Elixir.AshUI.Test.ResourceAuthorityScreen"
      assert get_in(screen.unified_dsl, ["screen", "metadata", "seed"]) == "phase_10"

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)
      assert iur.type == :screen
    end

    test "screen resources can be persisted directly from authority attrs", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      attrs =
        ScreenDocumentFixtures.resource_screen_attrs("phase10_persisted_screen",
          route: "/phase-10/persisted",
          layout: :column,
          metadata: %{"title" => "Persisted Screen"}
        )

      assert {:ok, screen} =
               Data.create(screen_resource,
                 ui_storage: ui_storage,
                 authorize?: false,
                 attrs: attrs
               )

      assert Authority.authority_payload?(screen.unified_dsl)
      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)
      assert iur.type == :screen
    end

    test "unsupported legacy shapes are reported clearly without runtime fallback", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      invalid_legacy = %{
        "type" => "unsupported_widget",
        "props" => %{},
        "signals" => [],
        "metadata" => %{},
        "children" => []
      }

      assert {:ok, screen} =
               Data.create(screen_resource,
                 ui_storage: ui_storage,
                 authorize?: false,
                 attrs: %{
                   name: "phase10_runtime_reject",
                   unified_dsl: invalid_legacy,
                   layout: :row
                 }
               )

      assert {:error, {:invalid_screen_dsl, :unsupported_format}} =
               Compiler.compile_from_unified_dsl(screen, ui_storage: ui_storage)
    end

    test "resource-authority screens retain metadata, bindings, and versions", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      attrs =
        ScreenDocumentFixtures.resource_screen_attrs("phase10_bound_screen",
          route: "/phase-10/bound",
          layout: :row,
          metadata: %{"title" => "Bound Screen", "owner" => "phase10"},
          binding_metadata: %{
            "display_name_input" => %{
              "element_id" => "display_name_input",
              "source" => %{"resource" => "User", "field" => "name", "id" => "user-1"},
              "binding_type" => :value,
              "target" => "display_name"
            }
          },
          version: 7
        )

      assert {:ok, screen} =
               Data.create(screen_resource,
                 ui_storage: ui_storage,
                 authorize?: false,
                 attrs: attrs
               )

      assert screen.version == 7
      assert screen.metadata["owner"] == "phase10"
      assert get_in(screen.unified_dsl, ["screen", "metadata", "owner"]) == "phase10"

      assert get_in(screen.unified_dsl, [
               "elements"
             ])
             |> Enum.any?(fn element ->
               Enum.any?(Map.get(element, "bindings", []), fn binding ->
                 binding["id"] == "display_name_input" and
                   binding["source"]["field"] == "name"
               end)
             end)

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)

      assert Enum.any?(iur.bindings, fn binding ->
               binding["id"] == "display_name_input"
             end)
    end

    test "legacy builder payloads are rejected without compatibility fallbacks", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      legacy_dsl =
        Builder.column(
          children: [
            Builder.text("Legacy"),
            Builder.button("Save")
          ]
        )
        |> Builder.to_store()

      assert {:ok, screen} =
               Data.create(screen_resource,
                 ui_storage: ui_storage,
                 authorize?: false,
                 attrs: %{
                   name: "phase10_legacy_rejected",
                   unified_dsl: legacy_dsl,
                   layout: :column
                 }
               )

      assert {:error, {:invalid_screen_dsl, :unsupported_format}} =
               Compiler.compile(screen, ui_storage: ui_storage)
    end
  end
end
