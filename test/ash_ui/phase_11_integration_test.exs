defmodule AshUI.Phase11IntegrationTest do
  use AshUI.DataCase, async: false

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.Compiler.Incremental
  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias AshUI.Resources.Screen
  alias AshUI.Test.{RuntimeDomain, RuntimeFixtures, ScreenDocumentFixtures, UIStorageFixtures}

  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()

    %{ui_storage: UIStorageFixtures.ui_storage_config()}
  end

  describe "Section 11.4.1 - compiler delegation scenarios" do
    test "11.4.1.1 - Verify a resource-authority screen compiles through AshUI.Compiler", %{
      ui_storage: ui_storage
    } do
      screen = create_screen!(ui_storage, "phase11_compile")

      assert {:ok, iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)
      assert {:ok, canonical} = IURAdapter.to_canonical(iur)
      assert {:ok, canonical} = UnifiedIUR.Normalize.element(canonical)
      assert :ok = UnifiedIUR.Validate.element(canonical)

      assert canonical.type == :composite
      assert canonical.kind == :screen

      assert get_in(canonical.metadata.extra, [
               "ash_ui",
               "ash_ui",
               "authoring_source",
               "module"
             ]) ==
               "Elixir.AshUI.Test.ResourceAuthorityScreen"
    end

    test "11.4.1.2 - Verify live bindings hydrate correctly after resource-authority compilation",
         %{
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
      _ui_storage_screen =
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

      {:ok, screen} =
        Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("phase11_incremental_default",
              route: "/phase11_incremental_default",
              layout: :column,
              metadata: %{"seed" => "phase11_incremental_default"},
              binding_metadata: %{
                "display_name_input" => %{
                  "source" => %{"resource" => "User", "field" => "name", "id" => "user-1"},
                  "binding_type" => :value,
                  "target" => "display_name",
                  "element_id" => "display_name_input"
                }
              }
            )
        )

      assert {:ok, _iur} = Compiler.compile(screen, use_cache: true)
      assert {:ok, _iur} = Compiler.compile(screen, use_cache: true)
      assert Compiler.cache_stats().hits >= 1

      assert {:ok, graph} = Incremental.build_dependencies(screen)
      assert "display_name_input" in Map.get(graph.screen_to_elements, screen.id, [])

      assert {:ok, recompiled_iur} =
               Incremental.recompile_on_change(
                 screen.id,
                 :element,
                 "display_name_input"
               )

      assert :ok = IUR.validate(recompiled_iur)
    end
  end

  defp create_screen!(ui_storage, prefix, opts \\ []) do
    suffix = System.unique_integer([:positive])
    screen_resource = Config.screen_resource(ui_storage)
    binding_metadata = Keyword.get(opts, :binding_metadata, %{})

    attrs =
      ScreenDocumentFixtures.resource_screen_attrs("#{prefix}_#{suffix}",
        route: "/#{prefix}",
        layout: :column,
        metadata: %{"seed" => prefix},
        binding_metadata: binding_metadata
      )

    {:ok, screen} =
      Data.create(screen_resource,
        ui_storage: ui_storage,
        authorize?: false,
        attrs: attrs
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
