defmodule AshUI.PluggableUIStorageTest do
  use ExUnit.Case, async: false

  alias AshUI.Compiler
  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.LiveView.Integration
  alias AshUI.Test.RuntimeDomain
  alias AshUI.Test.UIStorageFixtures
  alias AshUI.Test.UIStorageScreen

  @moduletag :conformance

  setup do
    previous_ui_storage = Application.get_env(:ash_ui, :ui_storage)
    previous_domains = Application.get_env(:ash_ui, :ash_domains)

    Application.put_env(:ash_ui, :ui_storage, UIStorageFixtures.ui_storage_config())
    Application.put_env(:ash_ui, :ash_domains, [RuntimeDomain])

    on_exit(fn ->
      Application.put_env(:ash_ui, :ui_storage, previous_ui_storage)
      Application.put_env(:ash_ui, :ash_domains, previous_domains)
    end)

    :ok
  end

  test "AshUI.Data routes CRUD through the configured UI storage domain" do
    suffix = System.unique_integer([:positive])

    {:ok, screen} =
      Data.create(UIStorageScreen,
        attrs: %{
          name: "configured_storage_#{suffix}",
          unified_dsl: %{},
          metadata: %{"title" => "Configured storage"}
        }
      )

    assert screen.__struct__ == UIStorageScreen
    assert Config.ui_storage_domain() == AshUI.Test.UIStorageDomain

    assert {:ok, loaded} =
             Data.read_one(UIStorageScreen, filter: [name: "configured_storage_#{suffix}"])

    assert loaded.id == screen.id
  end

  test "Compiler compiles screens from alternate UI storage resources" do
    %{screen: screen, binding: binding} = UIStorageFixtures.seed_screen!()

    assert {:ok, iur} = Compiler.compile(screen.id)
    assert iur.id == screen.id
    assert Enum.any?(iur.bindings, &(&1["id"] == binding.id))
  end

  test "LiveView mount loads and evaluates bindings from alternate UI storage resources" do
    %{screen: screen, runtime: runtime, binding: binding} = UIStorageFixtures.seed_screen!()

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: Map.put(runtime.actor, :active, true),
          ash_ui_storage: UIStorageFixtures.ui_storage_config(),
          ash_ui_domains: [RuntimeDomain]
        }
      }

    assert {:ok, mounted_socket} = Integration.mount_ui_screen(socket, screen.name, %{})
    assert mounted_socket.assigns[:ash_ui_screen].id == screen.id
    assert mounted_socket.assigns[:ash_ui_storage][:domain] == AshUI.Test.UIStorageDomain
    assert mounted_socket.assigns[:ash_ui_bindings][binding.id].value == runtime.user.name
  end
end
