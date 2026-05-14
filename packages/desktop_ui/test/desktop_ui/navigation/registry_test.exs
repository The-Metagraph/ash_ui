defmodule DesktopUi.Navigation.RegistryTest do
  use ExUnit.Case
  alias DesktopUi.Navigation.Registry

  @moduletag :navigation

  describe "validate/1" do
    test "validates a registry module with register/0" do
      defmodule TestRegistry do
        def register, do: %{home: HomeScreen}
      end

      assert {:ok, %{home: HomeScreen}} = Registry.validate(TestRegistry)
    end

    test "returns error for module without register/0" do
      defmodule BadRegistry do
        def get_screen(_), do: nil
      end

      assert {:error, {:invalid_registry, :not_loaded_or_no_register}} =
               Registry.validate(BadRegistry)
    end

    test "validates that registry returns a map" do
      defmodule BadReturn do
        def register, do: :not_a_map
      end

      assert {:error, {:invalid_registry, :register_not_map}} =
               Registry.validate(BadReturn)
    end
  end

  describe "lookup/2" do
    defmodule ValidRegistry do
      def register, do: %{home: HomeScreen, about: AboutScreen}
      def get_screen(:home), do: HomeScreen
      def get_screen(:about), do: AboutScreen
      def get_screen(_), do: nil
    end

    test "returns {:ok, module} for known screens" do
      assert {:ok, HomeScreen} = Registry.lookup(ValidRegistry, :home)
      assert {:ok, AboutScreen} = Registry.lookup(ValidRegistry, :about)
    end

    test "returns {:error, :unknown_screen} for unknown screens" do
      assert {:error, {:unknown_screen, :unknown}} =
               Registry.lookup(ValidRegistry, :unknown)
    end

    test "returns error for registry without get_screen/1" do
      defmodule NoLookup do
        def register, do: %{}
      end

      assert {:error, {:invalid_registry, NoLookup}} =
               Registry.lookup(NoLookup, :home)
    end
  end

  describe "metadata/2" do
    defmodule MetadataRegistry do
      def register, do: %{}
      def get_screen(:home), do: HomeScreen

      def screen_metadata(:home) do
        %{title: "Home Screen", icon: :home}
      end

      def screen_metadata(_), do: %{}
    end

    test "returns metadata from registry" do
      assert %{title: "Home Screen", icon: :home} =
               Registry.metadata(MetadataRegistry, :home)
    end

    test "returns empty map when no metadata callback" do
      defmodule NoMetadata do
        def register, do: %{}
        def get_screen(_), do: nil
      end

      assert %{} = Registry.metadata(NoMetadata, :home)
    end
  end

  describe "all_screen_ids/1" do
    defmodule FullRegistry do
      def register, do: %{home: HomeScreen, about: AboutScreen, settings: SettingsScreen}
      def get_screen(_), do: nil
    end

    test "returns list of screen IDs from registry" do
      ids = Registry.all_screen_ids(FullRegistry)

      assert [:about, :home, :settings] = Enum.sort(ids)
    end

    test "returns empty list for invalid registry" do
      defmodule BadRegistry do
        def get_screen(_), do: nil
      end

      assert [] = Registry.all_screen_ids(BadRegistry)
    end
  end
end
