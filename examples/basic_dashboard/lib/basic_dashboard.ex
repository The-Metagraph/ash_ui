defmodule BasicDashboard do
  @moduledoc """
  Minimal Ash UI example seed module backed by ETS data.
  """

  alias AshUI.DSL.Builder
  alias AshUI.Data, as: Domain
  alias AshUI.Resources.Binding
  alias AshUI.Resources.Element
  alias AshUI.Resources.Screen
  alias BasicDashboard.Data

  def seed! do
    cleanup_existing_screen!()

    {:ok, screen} =
      Domain.create(Screen,
        attrs: %{
          name: "basic_dashboard",
          route: "/dashboard",
          layout: :column,
          unified_dsl:
            Builder.column(
              spacing: 12,
              children: [
                Builder.text("Basic Dashboard", size: 24, weight: :bold),
                Builder.input("display_name",
                  placeholder: "Enter your name",
                  bind_to: "user-name"
                ),
                Builder.button("Save", on_click: "save-profile")
              ]
            )
            |> Builder.to_store(),
          metadata: %{"title" => "Basic Dashboard"}
        }
      )

    {:ok, input} =
      Domain.create(Element,
        attrs: %{
          screen_id: screen.id,
          type: :textinput,
          props: %{"label" => "Display name"},
          position: 0
        }
      )

    {:ok, button} =
      Domain.create(Element,
        attrs: %{
          screen_id: screen.id,
          type: :button,
          props: %{"label" => "Save"},
          variants: [:primary],
          position: 1
        }
      )

    {:ok, _value_binding} =
      Domain.create(Binding,
        attrs: %{
          screen_id: screen.id,
          element_id: input.id,
          binding_type: :value,
          target: "value",
          source: %{
            "resource" => "BasicDashboard.User",
            "field" => "name",
            "id" => Data.current_user_id()
          }
        }
      )

    {:ok, _action_binding} =
      Domain.create(Binding,
        attrs: %{
          screen_id: screen.id,
          element_id: button.id,
          binding_type: :action,
          target: "submit",
          source: %{
            "resource" => "BasicDashboard.User",
            "action" => "save_profile",
            "id" => Data.current_user_id()
          },
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

  defp cleanup_existing_screen! do
    Screen
    |> Ash.read!(domain: AshUI.Domain, authorize?: false)
    |> Enum.filter(&(&1.name == "basic_dashboard"))
    |> Enum.each(fn screen ->
      :ok = Domain.destroy(screen, authorize?: false)
    end)
  end
end
