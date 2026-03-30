defmodule AshUI.Phase15IntegrationTest do
  use AshUI.DataCase, async: false

  require Ash.Query

  alias AshUI.Compiler
  alias AshUI.Data
  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Resources.Screen
  alias AshUI.Test.{RuntimeDomain, RuntimeFixtures, ScreenDocumentFixtures, User}

  @moduletag :integration
  @moduletag :conformance

  setup do
    Compiler.clear_cache()
    Compiler.init_cache()

    %{fixtures: RuntimeFixtures.seed!()}
  end

  describe "Section 15.4.1 - Graph-derived runtime scenarios" do
    test "15.4.1.1 - relational resource graphs compile to stable canonical IUR", %{
      fixtures: _fixtures
    } do
      {:ok, screen} =
        Data.create(Screen,
          attrs: ScreenDocumentFixtures.resource_screen_attrs("phase15_stable_graph")
        )

      minimal_document = %{
        "format" => screen.unified_dsl["format"],
        "version" => screen.unified_dsl["version"],
        "screen" => %{"module" => get_in(screen.unified_dsl, ["screen", "module"])}
      }

      drifted_screen = %{screen | unified_dsl: minimal_document}

      assert {:ok, original_iur} = Compiler.compile(screen, use_cache: false)
      assert {:ok, drifted_iur} = Compiler.compile(drifted_screen, use_cache: false)

      assert {:ok, original_canonical} = IURAdapter.to_canonical(original_iur)
      assert {:ok, drifted_canonical} = IURAdapter.to_canonical(drifted_iur)
      assert :ok = UnifiedIUR.validate(original_canonical)
      assert :ok = UnifiedIUR.validate(drifted_canonical)
      assert original_canonical == drifted_canonical
    end

    test "15.4.1.2 - element-local bindings hydrate and react through ownership metadata", %{
      fixtures: fixtures
    } do
      {:ok, _screen} =
        Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs(
              "bound_screen",
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
        )

      socket = RuntimeFixtures.socket(current_user: build_admin(), ash_ui_domains: [RuntimeDomain])

      assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, :bound_screen, %{})

      assert mounted_socket.assigns.ash_ui_element_bindings["display_name_input"].metadata[
               "owner_scope"
             ] == "element"

      assert mounted_socket.assigns.ash_ui_bindings["display_name_input"].value == fixtures.user.name
      assert is_map(mounted_socket.assigns.ash_ui_iur)

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{
                   "target" => "display_name",
                   "value" => "Runtime Pascal",
                   "element_id" => "display_name_input",
                   "signal" => "change"
                 },
                 mounted_socket
               )

      assert changed_socket.assigns.ash_ui_bindings["display_name_input"].value == "Runtime Pascal"
      assert is_map(changed_socket.assigns.ash_ui_iur)
    end

    test "15.4.1.3 - element-local actions execute through the owning element boundary", %{
      fixtures: fixtures
    } do
      screen_name = "phase15_runtime_actions"

      {:ok, _screen} =
        Data.create(Screen,
          attrs: runtime_screen_attrs(screen_name, fixtures)
        )

      socket = RuntimeFixtures.socket(current_user: build_admin(), ash_ui_domains: [RuntimeDomain])

      assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen_name, %{})

      assert {:noreply, changed_socket} =
               EventHandler.handle_value_change(
                 %{
                   "target" => "display_name",
                   "value" => "Action Pascal",
                   "element_id" => "display_name_input",
                   "signal" => "change"
                 },
                 mounted_socket
               )

      assert {:reply, %{status: :ok}, action_socket} =
               EventHandler.handle_action_event(
                 %{
                   "action_id" => "save_profile",
                   "element_id" => "save_profile_button",
                   "signal" => "click"
                 },
                 changed_socket
               )

      assert get_in(action_socket.assigns, [:flash, :info]) == "Action completed successfully"

      query = Ash.Query.filter(User, id == ^fixtures.user.id)
      assert {:ok, refreshed_user} = Ash.read_one(query, domain: RuntimeDomain)
      assert refreshed_user.name == "Action Pascal"
      assert refreshed_user.nickname == "Action Pascal"
    end

    test "15.4.1.4 - superseded screen-document compiler inputs are rejected explicitly" do
      assert {:error, error} =
               Data.create(Screen,
                 attrs: %{
                   name: "phase15_invalid_document",
                   unified_dsl: %{"format" => "ash_ui/unified_ui_document", "version" => 2},
                   layout: :row
                 }
               )

      assert Exception.message(error) =~ "authoring must be a map"
    end
  end

  defp runtime_screen_attrs(name, fixtures) do
    payload =
      ScreenDocumentFixtures.resource_screen_document(name)
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

    attrs = ScreenDocumentFixtures.resource_screen_attrs(name)

    %{
      attrs
      | metadata: Map.put(attrs.metadata, "public", true),
        unified_dsl: payload
    }
  end

  defp update_screen_binding(payload, binding_id, fun) do
    update_in(payload, ["screen", "bindings"], fn bindings ->
      Enum.map(bindings || [], fn binding ->
        if Map.get(binding, "id") == binding_id, do: fun.(binding), else: binding
      end)
    end)
  end

  defp update_element_binding(payload, element_id, binding_id, fun) do
    update_in(payload, ["elements"], fn elements ->
      Enum.map(elements || [], fn element ->
        if element_runtime_id(element) == element_id do
          Map.update(element, "bindings", [], fn bindings ->
            Enum.map(bindings, fn binding ->
              if Map.get(binding, "id") == binding_id, do: fun.(binding), else: binding
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
              if Map.get(action, "id") == action_id, do: fun.(action), else: action
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

  defp build_admin do
    %{id: "admin-1", name: "Admin User", role: :admin, active: true}
  end
end
