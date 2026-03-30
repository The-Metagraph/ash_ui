defmodule BasicDashboard do
  @moduledoc """
  ETS-backed Ash UI example seed module for the resource-first dashboard.
  """

  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.Resource.Authority
  alias BasicDashboard.Storage

  @screen_name "basic_dashboard"
  @screen_title "Basic Dashboard"

  @spec seed!() :: struct()
  def seed! do
    ui_storage = Storage.config()
    screen_resource = Config.screen_resource(ui_storage)

    cleanup_existing_screen!(screen_resource, ui_storage)

    {:ok, screen} =
      Authority.create(BasicDashboard.Screen,
        ui_storage: ui_storage,
        authorize?: false,
        name: @screen_name,
        route: "/dashboard",
        layout: :column,
        metadata: %{"title" => @screen_title}
      )

    screen
  end

  @spec screen_module() :: module()
  def screen_module, do: BasicDashboard.Screen

  @spec screen_name() :: String.t()
  def screen_name, do: @screen_name

  @spec screen_title() :: String.t()
  def screen_title, do: @screen_title

  defp cleanup_existing_screen!(screen_resource, ui_storage) do
    screen_resource
    |> Data.read!(filter: [name: @screen_name], ui_storage: ui_storage, authorize?: false)
    |> Enum.each(fn screen ->
      :ok = Data.destroy(screen, ui_storage: ui_storage, authorize?: false)
    end)
  end
end
