defmodule AshUI.Phase13IntegrationTest do
  use AshUI.DataCase, async: false

  require Ash.Query

  alias AshUI.Compiler
  alias AshUI.Data
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Resource.Authority
  alias AshUI.Resources.Screen
  alias AshUI.Test.{ResourceAuthorityScreen, RuntimeDomain, RuntimeFixtures, User}

  @moduletag :integration
  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()

    %{fixtures: RuntimeFixtures.seed!()}
  end

  describe "Section 13.4.1 - Resource-first authoring scenarios" do
    test "13.4.1.1 - an element resource graph compiles as the authoritative source" do
      {:ok, screen} =
        Data.create(Screen,
          attrs: authority_screen_attrs("phase13_authority_screen")
        )

      assert {:ok, iur} = Compiler.compile(screen, use_cache: false)

      assert iur.metadata["ash_ui"]["authoring_source"]["kind"] == "resource_authority"
      assert iur.metadata["ash_ui"]["authoring_source"]["module"] ==
               "Elixir.AshUI.Test.ResourceAuthorityScreen"
      assert iur.metadata["ash_ui"]["resource_authority"]["screen_module"] ==
               "Elixir.AshUI.Test.ResourceAuthorityScreen"

      types = collect_types(iur)
      assert :hero in types
      assert :stat in types
      assert :key_value in types
      assert :info_list in types
      assert :form_field in types
      assert :input in types
      assert :button in types
    end

    test "13.4.1.2 - element-local bindings and actions survive mount and runtime execution",
         %{fixtures: fixtures} do
      screen_name = "phase13_runtime_screen"

      {:ok, _screen} =
        Data.create(Screen,
          attrs: runtime_screen_attrs(screen_name, fixtures)
        )

      socket =
        RuntimeFixtures.socket(
          current_user: build_admin()
        )

      assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen_name, %{})

      assert mounted_socket.assigns.ash_ui_bindings["display_name_input"].value == fixtures.user.name
      assert mounted_socket.assigns.ash_ui_bindings["save_profile"].binding_type == :action

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{"target" => "display_name", "value" => "Updated Pascal"},
                 mounted_socket
               )

      assert changed_socket.assigns.ash_ui_bindings["display_name_input"].value == "Updated Pascal"

      assert {:reply, %{status: :ok}, action_socket} =
               EventHandler.handle_action_event(
                 %{"action_id" => "save_profile"},
                 changed_socket
               )

      assert get_in(action_socket.assigns, [:flash, :info]) == "Action completed successfully"

      query = Ash.Query.filter(User, id == ^fixtures.user.id)
      assert {:ok, refreshed_user} = Ash.read_one(query, domain: RuntimeDomain)
      assert refreshed_user.name == "Updated Pascal"
      assert refreshed_user.nickname == "Updated Pascal"
    end

    test "13.4.1.3 - invalid signal and action declarations fail clearly at compile time" do
      assert_raise ArgumentError, ~r/supported signals are \[:click, :submit\]/, fn ->
        Code.compile_string("""
        defmodule InvalidPhase13ActionButton do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Element

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_element do
            type :button
            props %{label: "Broken"}
          end

          ui_actions do
            action :bad_toggle do
              signal :toggle
              source %{resource: "User", action: "update", id: "user-1"}
            end
          end
        end
        """)
      end
    end

    test "13.4.1.4 - superseded screen-document authoring helpers are removed" do
      refute Code.ensure_loaded?(AshUI.Authoring.Screen)
      refute Code.ensure_loaded?(AshUI.Authoring.Document)
      refute Code.ensure_loaded?(AshUI.Authoring.Migrator)
      refute Code.ensure_loaded?(AshUI.Authoring.LegacyBuilder)
    end
  end

  defp authority_screen_attrs(name) do
    {:ok, attrs} =
      Authority.screen_attrs(ResourceAuthorityScreen,
        name: name,
        route: "/phase-13/#{name}",
        layout: :column
      )

    attrs
  end

  defp runtime_screen_attrs(name, fixtures) do
    payload =
      authority_screen_attrs(name).unified_dsl
      |> update_screen_binding("screen_notice", fn binding ->
        binding
        |> Map.put("source", %{
          "resource" => "User",
          "field" => "nickname",
          "id" => fixtures.user.id
        })
        |> Map.put("transform", %{"default" => "ready"})
      end)
      |> update_element_binding("current_value_stat", "current_value", fn binding ->
        Map.put(binding, "source", %{
          "resource" => "User",
          "field" => "name",
          "id" => fixtures.user.id
        })
      end)
      |> update_element_binding("display_name_input", "display_name_input", fn binding ->
        Map.put(binding, "source", %{
          "resource" => "User",
          "field" => "name",
          "id" => fixtures.user.id
        })
      end)
      |> update_element_action("save_profile_button", "save_profile", fn action ->
        action
        |> Map.put("source", %{
          "resource" => "User",
          "action" => "update",
          "id" => fixtures.user.id
        })
        |> Map.put("transform", %{
          "params" => %{
            "nickname" => %{"from" => "binding", "key" => "display_name"}
          }
        })
      end)

    attrs = authority_screen_attrs(name)

    %{
      attrs
      | metadata: Map.put(attrs.metadata, "public", true),
        unified_dsl: payload
    }
  end

  defp update_screen_binding(payload, binding_id, fun) do
    update_in(payload, ["screen", "bindings"], fn bindings ->
      Enum.map(bindings || [], fn binding ->
        if Map.get(binding, "id") == binding_id do
          fun.(binding)
        else
          binding
        end
      end)
    end)
  end

  defp update_element_binding(payload, element_id, binding_id, fun) do
    update_in(payload, ["elements"], fn elements ->
      Enum.map(elements || [], fn element ->
        if element_runtime_id(element) == element_id do
          Map.update(element, "bindings", [], fn bindings ->
            Enum.map(bindings, fn binding ->
              if Map.get(binding, "id") == binding_id do
                fun.(binding)
              else
                binding
              end
            end)
          end)
        else
          element
        end
      end)
    end)
  end

  defp update_element_action(payload, element_id, action_id, fun) do
    update_in(payload, ["elements"], fn elements ->
      Enum.map(elements || [], fn element ->
        if element_runtime_id(element) == element_id do
          Map.update(element, "actions", [], fn actions ->
            Enum.map(actions, fn action ->
              if Map.get(action, "id") == action_id do
                fun.(action)
              else
                action
              end
            end)
          end)
        else
          element
        end
      end)
    end)
  end

  defp element_runtime_id(element) do
    element
    |> Map.get("dsl", %{})
    |> Map.get("metadata", %{})
    |> Map.get("id")
  end

  defp collect_types(%{type: type, children: children}) do
    [type | Enum.flat_map(children || [], &collect_types/1)]
  end

  defp collect_types(_node), do: []

  defp build_admin do
    %{id: "admin-1", name: "Admin User", role: :admin, active: true}
  end
end
