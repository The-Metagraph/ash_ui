defmodule LiveUi.Widgets.Dialog do
  @moduledoc """
  Native dialog widget for overlay-driven workflows.
  """

  alias LiveUi.BrowserAttrs
  alias LiveUi.Style.Browser

  use LiveUi.Component, family: :overlay, name: :dialog, slots: [:inner_block, :actions]

  LiveUi.Component.common_attrs()
  attr(:title, :string, default: nil)
  attr(:open, :boolean, default: true)
  attr(:modal, :boolean, default: true)
  attr(:dismissible, :boolean, default: true)
  attr(:size, :string, default: "md")
  attr(:trigger, :string, default: nil)
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
      data-live-ui-widget="dialog"
      data-live-ui-open={@open}
      data-live-ui-modal={@modal}
      data-live-ui-dismissible={@dismissible}
      data-live-ui-size={@size}
      data-live-ui-trigger={@trigger}
      data-live-ui-background-fill={@background_fill}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <div data-live-ui-dialog-slot="header">
        <%= if @title do %>
          <h2><%= @title %></h2>
        <% end %>
      </div>
      <div data-live-ui-dialog-slot="content"><%= render_slot(@inner_block) %></div>
      <%= if @actions != [] do %>
        <footer data-live-ui-dialog-slot="actions"><%= render_slot(@actions) %></footer>
      <% end %>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    Browser.realize(%{
      spacing: %{padding: size_padding(assigns.size)},
      sizing: %{width: size_width(assigns.size)}
    }).css_vars
    |> BrowserAttrs.from_css_vars()
  end

  defp size_padding(value) do
    case to_string(value || "md") do
      "sm" -> "md"
      "lg" -> "xl"
      "xl" -> "xxl"
      "full" -> "xl"
      _other -> "lg"
    end
  end

  defp size_width(value) do
    case to_string(value || "md") do
      "sm" -> "24rem"
      "lg" -> "40rem"
      "xl" -> "52rem"
      "full" -> "100%"
      _other -> "32rem"
    end
  end
end
