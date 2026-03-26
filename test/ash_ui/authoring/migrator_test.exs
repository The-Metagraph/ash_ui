defmodule AshUI.Authoring.MigratorTest do
  use AshUI.DataCase, async: false

  alias AshUI.Authoring.{Document, Migrator}
  alias AshUI.Compiler
  alias AshUI.DSL.Builder
  alias AshUI.Resources.Screen

  describe "Section 10.2.1 - legacy builder migration" do
    test "dry_run reports migration shape and unsupported widgets without mutating input" do
      dsl = %{
        "type" => "column",
        "props" => %{},
        "signals" => [],
        "metadata" => %{},
        "children" => [
          %{
            "type" => "text",
            "props" => %{"content" => "Dry run"},
            "signals" => [],
            "metadata" => %{},
            "children" => []
          },
          %{
            "type" => "unsupported_widget",
            "props" => %{},
            "signals" => [],
            "metadata" => %{},
            "children" => []
          }
        ]
      }

      report = Migrator.dry_run(dsl, name: "dry_run_screen")

      assert report.source_format == "ash_ui.dsl.builder"
      assert report.root_type == "column"
      assert report.node_count == 3
      assert report.status == :unsupported
      assert "unsupported_widget" in report.unsupported_types
    end

    test "builder-authored screens migrate into the Phase 10 persisted contract" do
      dsl =
        Builder.column(
          spacing: 12,
          children: [
            Builder.text("Migrated"),
            Builder.button("Save")
          ]
        )

      assert {:ok, document} =
               Migrator.document(Builder.to_store(dsl),
                 name: "migrated_screen",
                 route: "/migrated",
                 layout: :column,
                 metadata: %{"title" => "Migrated Screen"}
               )

      assert Document.authoring_document?(document)
      assert document["format"] == Document.format()
      assert get_in(document, ["authoring", "source", "kind"]) == "legacy_builder_migration"

      assert get_in(document, ["ash_ui", "runtime_annotations", "compiler_dsl", "type"]) ==
               "column"

      assert :ok = Document.validate_write(document)
    end

    test "screen attrs preserve screen metadata during migration" do
      dsl = Builder.text("Attrs")

      assert {:ok, attrs} =
               Migrator.screen_attrs(Builder.to_store(dsl),
                 name: "migrated_attrs",
                 route: "/migrated-attrs",
                 layout: :row,
                 metadata: %{"title" => "Migrated Attrs", "owner" => "tests"}
               )

      assert attrs.name == "migrated_attrs"
      assert attrs.route == "/migrated-attrs"
      assert attrs.layout == :row
      assert attrs.metadata["owner"] == "tests"
      assert Document.authoring_document?(attrs.unified_dsl)
    end

    test "unsupported legacy widgets are reported clearly" do
      invalid_dsl = %{"type" => "unsupported_widget"}

      assert {:error, {:unsupported_legacy_dsl, report}} =
               Migrator.document(invalid_dsl, name: "invalid_migration")

      assert report.status == :unsupported
      assert "unsupported_widget" in report.unsupported_types
    end
  end

  describe "Section 10.2.2 - migrated screens in repo-owned seeds" do
    test "migrated persisted screens still compile through the current compiler" do
      dsl =
        Builder.row(
          children: [
            Builder.text("Phase 10"),
            Builder.button("Compile")
          ]
        )

      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            Migrator.screen_attrs!(Builder.to_store(dsl),
              name: "phase10_migrated_screen",
              layout: :row
            )
        )

      assert {:ok, iur} = Compiler.compile(screen)
      assert iur.type == :screen
      assert length(iur.children) == 1
    end
  end
end
