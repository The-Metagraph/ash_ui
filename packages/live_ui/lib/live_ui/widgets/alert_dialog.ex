defmodule LiveUi.Widgets.AlertDialog do
  @moduledoc """
  Native alert-dialog widget for destructive or attention-demanding flows.
  """

  alias LiveUi.BrowserAttrs
  alias LiveUi.Style.Browser

  use LiveUi.Component, family: :overlay, name: :alert_dialog, slots: [:inner_block, :actions]

  LiveUi.Component.common_attrs()
  attr(:title, :string, default: nil)
  attr(:severity, :string, default: "warning")
  attr(:open, :boolean, default: true)
  attr(:requires_confirmation, :boolean, default: true)
  attr(:background_fill, :string, default: "scrim")
  slot(:inner_block)
  slot(:actions)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="alert-dialog"
      data-live-ui-open={@open}
      data-live-ui-severity={@severity}
      data-live-ui-requires-confirmation={@requires_confirmation}
      data-live-ui-background-fill={@background_fill}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <div data-live-ui-alert-slot="header">
        <%= if @title do %>
          <h2><%= @title %></h2>
        <% end %>
      </div>
      <div data-live-ui-alert-slot="content"><%= render_slot(@inner_block) %></div>
      <%= if @actions != [] do %>
        <footer data-live-ui-alert-slot="actions"><%= render_slot(@actions) %></footer>
      <% end %>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    Browser.realize(%{
      spacing: %{padding: "lg"},
      sizing: %{width: "30rem"}
    }).css_vars
    |> Map.merge(severity_css(assigns.severity))
    |> BrowserAttrs.from_css_vars()
  end

  defp severity_css(nil), do: %{}

  defp severity_css(value) do
    case to_string(value) do
      "critical" ->
        %{
          "--live-ui-border-color" => "var(--live-ui-theme-critical)",
          "--live-ui-background" =>
            "color-mix(in srgb, var(--live-ui-theme-surface-panel) 86%, var(--live-ui-theme-critical) 14%)"
        }

      "success" ->
        %{
          "--live-ui-border-color" => "var(--live-ui-theme-success)",
          "--live-ui-background" =>
            "color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, var(--live-ui-theme-success) 12%)"
        }

      _other ->
        %{
          "--live-ui-border-color" => "var(--live-ui-theme-warning)",
          "--live-ui-background" =>
            "color-mix(in srgb, var(--live-ui-theme-surface-panel) 88%, var(--live-ui-theme-warning) 12%)"
        }
    end
  end
end
