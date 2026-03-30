defmodule AshUI.Rendering.IURAdapterTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compiler
  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ResourceAuthorityScreen, UIStorageFixtures}

  describe "to_canonical/1" do
    test "converts simple screen to canonical format" do
      ash_iur =
        IUR.new(:screen,
          id: "test-screen-1",
          name: "test_screen",
          attributes: %{
            "layout" => :row,
            "route" => "/test"
          },
          children: [
            IUR.new(:text,
              id: "text-1",
              props: %{"content" => "Hello World"}
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      assert canonical["type"] == "screen"
      assert canonical["id"] == "test-screen-1"
      assert canonical["name"] == "test_screen"
      assert canonical["layout"] == "row"
      assert is_list(canonical["children"])
      assert length(canonical["children"]) == 1
      assert :ok = UnifiedIUR.validate(canonical)
    end

    test "converts element to canonical widget type" do
      element = IUR.new(:button, props: %{"label" => "Click me"})

      ash_iur =
        IUR.new(:screen,
          children: [element]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical["children"]
      assert child["type"] == "button"
      assert child["props"]["label"] == "Click me"
    end

    test "converts layout to canonical layout type" do
      layouts = [:row, :column, :grid, :stack]

      Enum.each(layouts, fn layout ->
        ash_iur =
          IUR.new(:screen,
            attributes: %{"layout" => layout}
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        assert canonical["layout"] == Atom.to_string(layout)
      end)
    end

    test "converts nested elements" do
      ash_iur =
        IUR.new(:screen,
          attributes: %{"layout" => :column},
          children: [
            IUR.new(:row,
              children: [
                IUR.new(:text, props: %{"content" => "Nested"}),
                IUR.new(:button, props: %{"label" => "Button"})
              ]
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [row] = canonical["children"]
      assert row["type"] == "row"

      assert length(row["children"]) == 2
    end
  end

  describe "compatible?/2" do
    test "returns true for screen with valid renderers" do
      screen_iur = IUR.new(:screen)

      assert IURAdapter.compatible?(screen_iur, :live_ui)
      assert IURAdapter.compatible?(screen_iur, :elm)
      assert IURAdapter.compatible?(screen_iur, :desktop_ui)
    end

    test "returns false for non-screen types" do
      text_iur = IUR.new(:text)

      refute IURAdapter.compatible?(text_iur, :live_ui)
    end
  end

  describe "element type mapping" do
    test "maps known element types correctly" do
      type_mappings = [
        {:text, "text"},
        {:button, "button"},
        {:textinput, "input"},
        {:textarea, "textarea"},
        {:select, "select"},
        {:row, "row"},
        {:column, "column"}
      ]

      Enum.each(type_mappings, fn {ash_type, expected_canonical} ->
        ash_iur =
          IUR.new(:screen,
            children: [IUR.new(ash_type)]
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        [child] = canonical["children"]
        assert child["type"] == expected_canonical
      end)
    end
  end

  describe "props mapping" do
    test "converts props map correctly" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:button,
              props: %{
                "label" => "Submit",
                "disabled" => false
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical["children"]
      assert child["props"]["label"] == "Submit"
      assert child["props"]["disabled"] == false
    end

    test "preserves empty binding paths on authored form widgets" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:form_field,
              props: %{
                "bindings" => [
                  %{
                    "name" => :display_name,
                    "path" => [],
                    "scope" => [],
                    "depends_on" => [],
                    "metadata" => [],
                    "derived" => []
                  }
                ]
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert :ok = UnifiedIUR.validate(canonical)
    end

    test "converts resource-authority semantic widgets without leaking renderer assumptions" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Authority.create(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 route: "/phase-13/resource-authority",
                 layout: :column,
                 metadata: %{"seed" => "phase13"}
               )

      assert {:ok, ash_iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)
      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert :ok = UnifiedIUR.validate(canonical)

      types = collect_types(canonical)

      assert "hero" in types
      assert "stat" in types
      assert "key_value" in types
      assert "info_list" in types
      assert "form_field" in types

      assert get_in(canonical, ["metadata", "ash_ui", "compiler_boundary"]) ==
               "AshUI resource graph -> AshUI runtime normalization"

      refute Enum.any?(canonical["children"], fn child ->
               match?(%{"ash_ui" => _}, child["metadata"])
             end)
    end
  end

  describe "error handling" do
    test "returns error for invalid IUR" do
      invalid_iur = %IUR{type: nil}

      assert {:error, _reason} = IURAdapter.to_canonical(invalid_iur)
    end
  end

  defp collect_types(%{"type" => type, "children" => children}) do
    [type | Enum.flat_map(children || [], &collect_types/1)]
  end

  defp collect_types(_other), do: []
end
