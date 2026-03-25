defmodule AshUI.Resources.ScreenTest do
  use AshUI.DataCase, async: false

  require Ash.Query

  alias AshUI.Resources.Screen

  @moduletag :conformance

  describe "Screen CRUD operations" do
    test "create/1 creates a screen with unified_dsl storage" do
      attrs = %{
        name: "test_screen",
        unified_dsl: %{
          "type" => "screen",
          "root" => %{"type" => "row"}
        },
        layout: :row,
        route: "/test"
      }

      assert {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)
      assert screen.name == "test_screen"
      assert screen.layout == :row
      assert screen.route == "/test"
      assert is_map(screen.unified_dsl)
      assert screen.version == 1
      assert screen.active == true
    end

    test "read/2 lists all screens" do
      # Create test screens
      Enum.each(["screen_a", "screen_b"], fn name ->
        attrs = %{
          name: name,
          unified_dsl: %{"type" => "screen"},
          layout: :row
        }

        AshUI.Data.create(Screen, attrs: attrs)
      end)

      screens = AshUI.Data.read!(Screen)
      assert length(screens) >= 2
    end

    test "update/2 updates screen attributes" do
      attrs = %{
        name: "update_test",
        unified_dsl: %{"type" => "screen"},
        layout: :column
      }

      {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)
      {:ok, updated} = AshUI.Data.update(screen, attrs: %{layout: :grid})

      assert updated.layout == :grid
      assert updated.version == 2
    end

    test "destroy/1 deletes a screen" do
      attrs = %{
        name: "destroy_test",
        unified_dsl: %{"type" => "screen"},
        layout: :row
      }

      {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)
      assert :ok = AshUI.Data.destroy(screen)

      assert [] = AshUI.Data.read!(Screen, filter: [name: "destroy_test"])
    end
  end

  describe "Screen name uniqueness" do
    test "prevents duplicate screen names" do
      attrs = %{
        name: "unique_test",
        unified_dsl: %{"type" => "screen"},
        layout: :row
      }

      {:ok, _screen} = AshUI.Data.create(Screen, attrs: attrs)

      assert {:error, error} = AshUI.Data.create(Screen, attrs: attrs)
      assert Exception.message(error) =~ "constraint error"
    end
  end

  describe "Screen unified_dsl validation" do
    test "rejects malformed Phase 10 authoring documents" do
      assert {:error, error} =
               AshUI.Data.create(Screen,
                 attrs: %{
                   name: "invalid_phase10_document",
                   unified_dsl: %{
                     "format" => "ash_ui/unified_ui_document",
                     "version" => 2,
                     "authoring" => %{},
                     "ash_ui" => %{}
                   },
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "authoring"
      assert Exception.message(error) =~ "invalid"
    end

    test "rejects non-map unified_dsl values" do
      assert {:error, error} =
               AshUI.Data.create(Screen,
                 attrs: %{
                   name: "invalid_dsl_scalar",
                   unified_dsl: "not a map",
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "unified_dsl"
      assert Exception.message(error) =~ "invalid"
    end

    test "rejects unsupported unified_dsl root types" do
      assert {:error, error} =
               AshUI.Data.create(Screen,
                 attrs: %{
                   name: "invalid_dsl_type",
                   unified_dsl: %{"type" => "unsupported_widget"},
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "unsupported type"
    end
  end

  describe "Screen lifecycle actions" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: %{
            name: "lifecycle_screen",
            unified_dsl: %{"type" => "screen", "children" => []},
            layout: :row
          }
        )

      %{screen: screen}
    end

    test "mount read action accepts user_id and params", %{screen: screen} do
      assert {:ok, mounted} =
               AshUI.Data.read_one(Screen,
                 filter: [id: screen.id],
                 action: :mount,
                 args: %{user_id: "user-1", params: %{"tab" => "overview"}}
               )

      assert mounted.id == screen.id
      assert mounted.name == "lifecycle_screen"
    end

    test "mount read action rejects missing user_id", %{screen: screen} do
      assert {:error, error} =
               AshUI.Data.read_one(Screen,
                 filter: [id: screen.id],
                 action: :mount,
                 args: %{params: %{}}
               )

      assert Exception.message(error) =~ "user_id"
    end

    test "unmount action returns cleanup payload", %{screen: screen} do
      assert {:ok, result} =
               AshUI.Data.action(Screen, :unmount, %{
                 screen_id: screen.id,
                 user_id: "user-1",
                 params: %{"from" => "test"}
               })

      assert result.screen_id == screen.id
      assert result.user_id == "user-1"
      assert result.cleaned_up == true
      assert %DateTime{} = result.unmounted_at
    end
  end
end
