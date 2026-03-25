defmodule BasicDashboard do
  @moduledoc """
  ETS-backed Ash UI example seed module for the full dashboard layout.
  """

  alias AshUI.Config
  alias AshUI.Authoring.Migrator
  alias AshUI.DSL.Builder
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
      Data.create(screen_resource,
        ui_storage: ui_storage,
        authorize?: false,
        attrs:
          Migrator.screen_attrs!(
            dashboard_dsl() |> Builder.to_store(),
            name: @screen_name,
            route: "/dashboard",
            layout: :column,
            metadata: %{"title" => @screen_title}
          )
      )

    screen
  end

  defp dashboard_dsl do
    Builder.column(
      class: "basic-dashboard-shell",
      style: shell_style(),
      spacing: 24,
      children: [
        top_bar(),
        hero_card(),
        Builder.grid(
          columns: 2,
          spacing: 20,
          style: "align-items: start;",
          children: [
            live_preview_card(),
            editor_card(),
            snapshot_card(),
            explainer_card()
          ]
        )
      ]
    )
  end

  defp top_bar do
    Builder.card(
      style: surface_style("padding: 18px 22px; border-radius: 28px;"),
      children: [
        Builder.row(
          spacing: 18,
          style: "justify-content: space-between; align-items: center; flex-wrap: wrap;",
          children: [
            Builder.column(
              spacing: 4,
              children: [
                Builder.text("Ash UI example", style: overline_style()),
                Builder.text("Basic dashboard on ETS-backed Ash resources",
                  style: title_style(18)
                )
              ]
            ),
            Builder.row(
              spacing: 10,
              style: "flex-wrap: wrap;",
              children: [
                pill("Theme", "Unified UI DSL"),
                pill("Data", "ETS + PubSub"),
                pill("Runtime", "LiveView bindings")
              ]
            )
          ]
        )
      ]
    )
  end

  defp hero_card do
    Builder.card(
      style: surface_style("padding: 30px; border-radius: 28px;"),
      children: [
        Builder.column(
          spacing: 14,
          children: [
            Builder.text("Ash-inspired example", style: overline_style()),
            Builder.text(
              "Model your dashboard. Let the runtime do the wiring.",
              style: hero_title_style()
            ),
            Builder.text(
              "This screen is stored as unified_dsl, compiled to canonical IUR, and hydrated from live Ash bindings without a handwritten dashboard shell.",
              style: copy_style()
            ),
            Builder.row(
              spacing: 10,
              style: "flex-wrap: wrap;",
              children: [
                badge("Route", "/dashboard"),
                badge("Screen", @screen_title)
              ]
            )
          ]
        )
      ]
    )
  end

  defp live_preview_card do
    Builder.card(
      style: surface_style("padding: 24px; border-radius: 24px;"),
      children: [
        Builder.column(
          spacing: 16,
          children: [
            Builder.text("Live signal preview", style: title_style(22)),
            Builder.text(
              "The input is bidirectionally bound to a real ETS-backed BasicDashboard.User, and the save button runs the save_profile Ash action with actor context.",
              style: copy_style()
            ),
            keyline("Current value", value_text(user_field_source("name"))),
            keyline(
              "Last actor",
              value_text(
                user_field_source("last_actor_id"),
                [%{"function" => "default", "args" => ["none yet"]}]
              )
            ),
            keyline("Runtime domain", static_value("BasicDashboard.Domain")),
            keyline("Renderer path", static_value("Ash UI -> LiveView"))
          ]
        )
      ]
    )
  end

  defp editor_card do
    Builder.card(
      style: surface_style("padding: 24px; border-radius: 24px;"),
      children: [
        Builder.column(
          spacing: 16,
          children: [
            Builder.text("Interactive profile editor", style: overline_style()),
            Builder.text("Update the current user", style: title_style(22)),
            Builder.text(
              "Type into the bound field to update the ETS record immediately, then click save to persist through the save_profile Ash action.",
              style: copy_style()
            ),
            Builder.text("Display name", style: label_style()),
            Builder.input("display_name",
              placeholder: "Enter your name",
              bind_to: user_field_source("name"),
              style: input_style()
            ),
            Builder.button("Save profile",
              variant: :primary,
              style: button_style(),
              signals: [
                %{
                  type: :event,
                  target: "submit",
                  source: %{
                    "resource" => "BasicDashboard.User",
                    "action" => "save_profile",
                    "id" => RuntimeData.current_user_id()
                  },
                  transform: %{
                    "params" => %{
                      "display_name" => %{"from" => "binding", "key" => "display_name"},
                      "actor_id" => %{"from" => "context", "key" => "user_id"}
                    }
                  }
                }
              ]
            ),
            meta_row("Resource", "BasicDashboard.User"),
            meta_row("Action", "save_profile"),
            meta_row("Actor", RuntimeData.current_user_id())
          ]
        )
      ]
    )
  end

  defp snapshot_card do
    Builder.card(
      style: surface_style("padding: 24px; border-radius: 24px;"),
      children: [
        Builder.column(
          spacing: 16,
          children: [
            Builder.text("Snapshot", style: overline_style()),
            Builder.text("Current dashboard state", style: title_style(22)),
            keyline("Display name", value_text(user_field_source("name"))),
            keyline("Email", value_text(user_field_source("email"))),
            keyline("Status", value_text(user_field_source("status"))),
            keyline("Team", value_text(user_relationship_source("profile.team"))),
            keyline("Profile name", value_text(user_relationship_source("profile.name")))
          ]
        )
      ]
    )
  end

  defp explainer_card do
    Builder.card(
      style: surface_style("padding: 24px; border-radius: 24px;"),
      children: [
        Builder.column(
          spacing: 14,
          children: [
            Builder.text("What this demo is showing", style: overline_style()),
            Builder.text("Persisted layout + runtime bindings", style: title_style(22)),
            explainer_item(
              "Real Ash resources",
              "BasicDashboard.User and BasicDashboard.Profile live in an ETS data layer domain."
            ),
            explainer_item(
              "Runtime reactivity",
              "PubSub notifications refresh the rendered IUR whenever the bound resources change."
            ),
            explainer_item(
              "Stored UI contract",
              "The top bar, hero, cards, labels, and editor are all stored in unified_dsl and rendered from IUR widgets."
            )
          ]
        )
      ]
    )
  end

  defp keyline(label, value_widget) do
    Builder.row(
      spacing: 12,
      style:
        "justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid rgba(71, 85, 105, 0.45);",
      children: [
        Builder.text(label, style: label_style()),
        value_widget
      ]
    )
  end

  defp meta_row(label, value) do
    Builder.row(
      spacing: 12,
      style: "justify-content: space-between; align-items: center;",
      children: [
        Builder.text(label, style: label_style()),
        Builder.text(value, style: value_style())
      ]
    )
  end

  defp explainer_item(title, body) do
    Builder.card(
      style:
        "border: 1px solid rgba(71, 85, 105, 0.55); background: rgba(15, 23, 42, 0.66); border-radius: 18px; padding: 16px;",
      children: [
        Builder.column(
          spacing: 6,
          children: [
            Builder.text(title, style: title_style(16)),
            Builder.text(body, style: copy_style())
          ]
        )
      ]
    )
  end

  defp pill(label, value) do
    Builder.text(
      "#{label}: #{value}",
      style:
        "display: inline-flex; align-items: center; gap: 6px; padding: 10px 14px; border-radius: 999px; background: rgba(249, 115, 22, 0.12); color: #fdba74; border: 1px solid rgba(249, 115, 22, 0.26); font-size: 13px; font-weight: 600;"
    )
  end

  defp badge(label, value) do
    Builder.text(
      "#{label}: #{value}",
      style:
        "display: inline-flex; align-items: center; padding: 10px 14px; border-radius: 999px; color: #f8fafc; background: rgba(15, 23, 42, 0.88); border: 1px solid rgba(148, 163, 184, 0.24); font-size: 13px;"
    )
  end

  defp value_text(source, transform \\ %{}) do
    Builder.text("",
      style: value_style(),
      signals: [value_signal("content", source, transform)]
    )
  end

  defp static_value(content) do
    Builder.text(content, style: value_style())
  end

  defp value_signal(target, source, transform) do
    signal =
      %{
        type: :value,
        target: target,
        source: source
      }

    case transform do
      %{} = value when map_size(value) > 0 -> Map.put(signal, :transform, value)
      value when is_list(value) and value != [] -> Map.put(signal, :transform, value)
      _ -> signal
    end
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

  defp shell_style do
    [
      "min-height: 100vh",
      "padding: 32px",
      "background: linear-gradient(180deg, #020617 0%, #0f172a 45%, #111827 100%)",
      "color: #f8fafc",
      "font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    ]
    |> Enum.join("; ")
  end

  defp surface_style(extra) do
    [
      "background: linear-gradient(180deg, rgba(15, 23, 42, 0.96), rgba(17, 24, 39, 0.94))",
      "border: 1px solid rgba(71, 85, 105, 0.65)",
      "box-shadow: 0 24px 64px rgba(2, 6, 23, 0.38)",
      extra
    ]
    |> Enum.join("; ")
  end

  defp overline_style do
    "color: #fdba74; text-transform: uppercase; letter-spacing: 0.14em; font-size: 12px; font-weight: 700;"
  end

  defp title_style(size) do
    "color: #f8fafc; font-size: #{size}px; font-weight: 700; line-height: 1.2;"
  end

  defp hero_title_style do
    "color: #fff7ed; font-size: 52px; font-weight: 800; line-height: 0.98; letter-spacing: -0.05em;"
  end

  defp copy_style do
    "color: #cbd5e1; font-size: 15px; line-height: 1.7;"
  end

  defp label_style do
    "color: #94a3b8; font-size: 13px; text-transform: uppercase; letter-spacing: 0.08em;"
  end

  defp value_style do
    "color: #f8fafc; font-size: 16px; font-weight: 600; text-align: right;"
  end

  defp input_style do
    [
      "width: 100%",
      "min-height: 48px",
      "padding: 14px 16px",
      "border-radius: 18px",
      "border: 1px solid rgba(249, 115, 22, 0.24)",
      "background: rgba(15, 23, 42, 0.88)",
      "color: #f8fafc"
    ]
    |> Enum.join("; ")
  end

  defp button_style do
    [
      "min-height: 48px",
      "padding: 0 20px",
      "border-radius: 999px",
      "border: none",
      "background: linear-gradient(90deg, #fb923c, #ef4444)",
      "color: #020617",
      "font-weight: 800",
      "cursor: pointer"
    ]
    |> Enum.join("; ")
  end
end
