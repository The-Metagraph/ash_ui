defmodule BasicDashboard do
  @moduledoc """
  ETS-backed Ash UI example seed module for the upstream-authored dashboard.
  """

  alias AshUI.Authoring.Screen, as: AuthoringScreen
  alias AshUI.Config
  alias AshUI.Data
  alias BasicDashboard.Data, as: RuntimeData
  alias BasicDashboard.Storage

  @screen_name "basic_dashboard"
  @screen_title "Basic Dashboard"

  @spec seed!() :: struct()
  def seed! do
    ui_storage = Storage.config()
    screen_resource = Config.screen_resource(ui_storage)

    cleanup_existing_screen!(screen_resource, ui_storage)

    {:ok, screen} =
      AuthoringScreen.create(BasicDashboard.AuthoredScreen,
        ui_storage: ui_storage,
        authorize?: false,
        name: @screen_name,
        route: "/dashboard",
        layout: :column,
        metadata: %{"title" => @screen_title},
        binding_metadata: binding_metadata()
      )

    screen
  end

  @spec authored_module() :: module()
  def authored_module, do: BasicDashboard.AuthoredScreen

  @spec screen_name() :: String.t()
  def screen_name, do: @screen_name

  @spec screen_title() :: String.t()
  def screen_title, do: @screen_title

  @spec binding_metadata() :: map()
  def binding_metadata do
    %{
      "display_name_input" => %{
        "source" => user_field_source("name"),
        "binding_type" => :value,
        "target" => "display_name",
        "element_id" => "display_name_input"
      },
      "save_profile_button" => %{
        "source" => %{
          "resource" => "BasicDashboard.User",
          "action" => "save_profile",
          "id" => RuntimeData.current_user_id()
        },
        "binding_type" => :action,
        "target" => "submit",
        "element_id" => "save_profile_button",
        "transform" => %{
          "params" => %{
            "display_name" => %{"from" => "binding", "key" => "display_name"},
            "actor_id" => %{"from" => "context", "key" => "user_id"}
          }
        }
      },
      "current_value_stat" => value_binding("current_value_stat", user_field_source("name")),
      "last_actor_stat" =>
        value_binding("last_actor_stat", user_field_source("last_actor_id"), [
          %{"function" => "default", "args" => ["none yet"]}
        ]),
      "name_row" => value_binding("name_row", user_field_source("name")),
      "email_row" => value_binding("email_row", user_field_source("email")),
      "status_row" => value_binding("status_row", user_field_source("status")),
      "team_row" => value_binding("team_row", user_relationship_source("profile.team")),
      "profile_name_row" =>
        value_binding("profile_name_row", user_relationship_source("profile.name"))
    }
  end

  defp value_binding(element_id, source, transform \\ %{}) do
    %{
      "source" => source,
      "binding_type" => :value,
      "target" => "value",
      "element_id" => element_id,
      "transform" => transform
    }
  end

  defp user_field_source(field) do
    %{
      "resource" => "BasicDashboard.User",
      "field" => field,
      "id" => RuntimeData.current_user_id()
    }
  end

  defp user_relationship_source(path) do
    %{
      "resource" => "BasicDashboard.User",
      "relationship" => path,
      "id" => RuntimeData.current_user_id()
    }
  end

  defp cleanup_existing_screen!(screen_resource, ui_storage) do
    screen_resource
    |> Data.read!(filter: [name: @screen_name], ui_storage: ui_storage, authorize?: false)
    |> Enum.each(fn screen ->
      :ok = Data.destroy(screen, ui_storage: ui_storage, authorize?: false)
    end)
  end
end
