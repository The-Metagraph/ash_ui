defmodule AshUI.Phase10IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Authoring.{Document, Migrator, Screen}
  alias AshUI.Compiler
  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.DSL.Builder
  alias AshUI.Test.{AuthoredSupportScreen, UIStorageFixtures}

  @moduletag :conformance

  setup do
    ui_storage = UIStorageFixtures.ui_storage_config()

    %{
      ui_storage: ui_storage,
      screen_resource: Config.screen_resource(ui_storage)
    }
  end

  describe "Section 10.4.1 - stored document migration scenarios" do
    test "new upstream-authored screens persist successfully", %{ui_storage: ui_storage} do
      assert {:ok, screen} =
               Screen.create(AuthoredSupportScreen,
                 ui_storage: ui_storage,
                 route: "/phase-10/upstream",
                 layout: :column,
                 metadata: %{"seed" => "phase_10"}
               )

      assert Document.authoring_document?(screen.unified_dsl)
      assert get_in(screen.unified_dsl, ["authoring", "source", "kind"]) == "unified_ui_module"
      assert get_in(screen.unified_dsl, ["ash_ui", "metadata", "seed"]) == "phase_10"

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)
      assert iur.type == :screen
    end

    test "legacy builder-authored screens can be migrated before persistence", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      dsl =
        Builder.column(
          children: [
            Builder.text("Migrated"),
            Builder.button("Save")
          ]
        )

      attrs =
        Migrator.screen_attrs!(
          Builder.to_store(dsl),
          name: "phase10_migrated_screen",
          route: "/phase-10/migrated",
          layout: :column,
          metadata: %{"title" => "Migrated Screen"}
        )

      assert {:ok, screen} =
               Data.create(screen_resource,
                 ui_storage: ui_storage,
                 authorize?: false,
                 attrs: attrs
               )

      assert Document.authoring_document?(screen.unified_dsl)
      assert get_in(screen.unified_dsl, ["authoring", "source", "kind"]) ==
               "legacy_builder_migration"

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)
      assert iur.type == :screen
      assert length(iur.children) == 1
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

      assert {:error, {:unsupported_legacy_dsl, report}} =
               Migrator.document(invalid_legacy, name: "phase10_invalid_legacy")

      assert report.status == :unsupported
      assert "unsupported_widget" in report.unsupported_types

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

      assert {:error, {:invalid_authoring_document, :phase_10_current_format_required}} =
               Compiler.compile_from_unified_dsl(screen, ui_storage: ui_storage)
    end

    test "migrated screens retain metadata, bindings, and versions", %{
      screen_resource: screen_resource,
      ui_storage: ui_storage
    } do
      dsl =
        Builder.input("display_name",
          bind_to: %{"resource" => "User", "field" => "name", "id" => "user-1"}
        )

      attrs =
        Migrator.screen_attrs!(
          Builder.to_store(dsl),
          name: "phase10_bound_screen",
          route: "/phase-10/bound",
          layout: :row,
          metadata: %{"title" => "Bound Screen", "owner" => "phase10"},
          binding_metadata: %{"display_name" => %{"source" => "User.name"}},
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
      assert get_in(screen.unified_dsl, ["ash_ui", "metadata", "owner"]) == "phase10"

      assert get_in(screen.unified_dsl, [
               "ash_ui",
               "binding_metadata",
               "display_name",
               "source"
             ]) == "User.name"

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage)

      assert Enum.any?(iur.bindings, fn binding ->
               binding["target"] == "display_name" and binding["source"]["field"] == "name"
             end)
    end
  end
end
