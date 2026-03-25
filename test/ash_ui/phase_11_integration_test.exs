defmodule AshUI.Phase11IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Authoring.Screen
  alias AshUI.Compiler
  alias AshUI.Compiler.Incremental
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias AshUI.Test.{AuthoredSupportScreen, RuntimeDomain, RuntimeFixtures, UIStorageFixtures}

  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()

    %{ui_storage: UIStorageFixtures.ui_storage_config()}
  end

  describe "Section 11.4.1 - compiler delegation scenarios" do
    test "11.4.1.1 - Verify an upstream-authored screen compiles through AshUI.Compiler", %{
      ui_storage: ui_storage
    } do
      screen = create_screen!(ui_storage, "phase11_compile")

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)
      assert {:ok, canonical} = IURAdapter.to_canonical(iur)
      assert :ok = UnifiedIUR.validate(canonical)

      assert canonical["type"] == "screen"

      assert get_in(canonical, ["metadata", "ash_ui", "authoring_source", "module"]) ==
               "AshUI.Test.AuthoredSupportScreen"
    end

    test "11.4.1.2 - Verify live bindings hydrate correctly after upstream compilation", %{
      ui_storage: ui_storage
    } do
      fixtures = RuntimeFixtures.seed!()

      screen =
        create_screen!(ui_storage, "phase11_hydration",
          binding_metadata: %{
            "display_name_input" => %{
              "source" => %{
                "resource" => "User",
                "field" => "name",
                "id" => fixtures.user.id
              },
              "binding_type" => :value,
              "target" => "display_name",
              "element_id" => "display_name_input"
            }
          }
        )

      socket =
        build_socket(
          current_user: build_admin(),
          ash_ui_storage: ui_storage,
          ash_ui_domains: [RuntimeDomain]
        )

      assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen.name, %{})

      assert mounted_socket.assigns.ash_ui_bindings["display_name_input"].value ==
               fixtures.user.name

      assert mounted_socket.assigns.ash_ui_iur
             |> find_node("display_name_input")
             |> get_in(["props", "value"]) == fixtures.user.name
    end

    test "11.4.1.3 - Verify canonical renderer output is unchanged for equivalent screens", %{
      ui_storage: ui_storage
    } do
      screen = create_screen!(ui_storage, "phase11_renderer_parity")

      assert {:ok, cached_iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: true)
      assert {:ok, cached_canonical} = IURAdapter.to_canonical(cached_iur)

      assert {:ok, uncached_iur} =
               Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)

      assert {:ok, uncached_canonical} = IURAdapter.to_canonical(uncached_iur)

      assert {:ok, cached_heex} = LiveUIAdapter.render(cached_canonical)
      assert {:ok, uncached_heex} = LiveUIAdapter.render(uncached_canonical)
      assert cached_heex == uncached_heex

      assert ElmUIAdapter.configure_elm_integration(cached_canonical).flags ==
               ElmUIAdapter.configure_elm_integration(uncached_canonical).flags
    end

    test "11.4.1.4 - Verify cache and incremental recompilation still behave correctly", %{
      ui_storage: ui_storage
    } do
      screen =
        create_screen!(ui_storage, "phase11_incremental",
          binding_metadata: %{
            "display_name_input" => %{
              "source" => %{"resource" => "User", "field" => "name", "id" => "user-1"},
              "binding_type" => :value,
              "target" => "display_name",
              "element_id" => "display_name_input"
            }
          }
        )

      assert {:ok, _iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: true)
      assert {:ok, _iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: true)
      assert Compiler.cache_stats().hits >= 1

      assert {:ok, graph} = Incremental.build_dependencies(screen, ui_storage: ui_storage)
      assert "display_name_input" in Map.get(graph.screen_to_elements, screen.id, [])

      assert {:ok, recompiled_iur} =
               Incremental.recompile_on_change(
                 screen.id,
                 :element,
                 "display_name_input",
                 ui_storage: ui_storage
               )

      assert :ok = AshUI.Compilation.IUR.validate(recompiled_iur)
    end
  end

  defp create_screen!(ui_storage, prefix, opts \\ []) do
    suffix = System.unique_integer([:positive])

    {:ok, screen} =
      Screen.create(AuthoredSupportScreen,
        ui_storage: ui_storage,
        name: "#{prefix}_#{suffix}",
        route: "/#{prefix}",
        layout: :column,
        metadata: %{"seed" => prefix},
        binding_metadata: Keyword.get(opts, :binding_metadata, %{})
      )

    screen
  end

  defp build_socket(assigns) do
    %Phoenix.LiveView.Socket{
      assigns:
        assigns
        |> Enum.into(%{__changed__: %{}, flash: %{}})
    }
  end

  defp build_admin(id \\ "admin-1") do
    %{id: id, name: "Admin User", role: :admin, active: true}
  end

  defp find_node(%{"id" => id} = node, id), do: node

  defp find_node(%{"children" => children}, id) when is_list(children) do
    Enum.find_value(children, &find_node(&1, id))
  end

  defp find_node(_node, _id), do: nil
end
