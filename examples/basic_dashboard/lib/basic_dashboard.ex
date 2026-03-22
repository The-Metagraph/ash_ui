defmodule BasicDashboard do
  @moduledoc """
  Minimal Ash UI example seed module.
  """

  alias AshUI.Config
  alias AshUI.DSL.Builder
  alias AshUI.Data, as: Domain

  def seed! do
    screen_resource = Config.screen_resource()
    element_resource = Config.element_resource()
    binding_resource = Config.binding_resource()

    {:ok, screen} =
      Domain.create(screen_resource,
        attrs: %{
          name: "basic_dashboard",
          route: "/dashboard",
          layout: :column,
          unified_dsl:
            Builder.column(
              spacing: 12,
              children: [
                Builder.text("Basic Dashboard", size: 24, weight: :bold),
                Builder.input("display_name", placeholder: "Enter your name", bind_to: "user-name"),
                Builder.button("Save", on_click: "save-profile")
              ]
            )
            |> Builder.to_store(),
          metadata: %{"title" => "Basic Dashboard"}
        }
      )

    {:ok, input} =
      Domain.create(element_resource,
        attrs: %{
          screen_id: screen.id,
          type: :textinput,
          props: %{"label" => "Display name"},
          position: 0
        }
      )

    {:ok, button} =
      Domain.create(element_resource,
        attrs: %{
          screen_id: screen.id,
          type: :button,
          props: %{"label" => "Save"},
          variants: [:primary],
          position: 1
        }
      )

    {:ok, _value_binding} =
      Domain.create(binding_resource,
        attrs: %{
          screen_id: screen.id,
          element_id: input.id,
          binding_type: :value,
          target: "value",
          source: %{"resource" => "User", "field" => "name", "id" => "current-user"}
        }
      )

    {:ok, _action_binding} =
      Domain.create(binding_resource,
        attrs: %{
          screen_id: screen.id,
          element_id: button.id,
          binding_type: :action,
          target: "submit",
          source: %{"resource" => "User", "action" => "save_profile"},
          transform: %{
            "params" => %{
              "display_name" => %{"from" => "event", "key" => "display_name"},
              "actor_id" => %{"from" => "context", "key" => "user_id"}
            }
          }
        }
      )

    screen
  end
end
