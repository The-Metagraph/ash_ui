defmodule LiveUi.Widgets.Box do
  @moduledoc """
  Baseline panel-like container widget for foundational screen composition.
  """

  alias LiveUi.BrowserAttrs
  alias LiveUi.Style.Browser

  use LiveUi.Component, family: :layout, name: :box, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:padding, :string, default: nil)
  attr(:border, :string, default: nil)
  attr(:background, :string, default: nil)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="box"
      data-live-ui-padding={@padding}
      data-live-ui-border={@border}
      data-live-ui-background={@background}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    css_vars =
      Browser.realize(%{spacing: %{padding: assigns.padding}}).css_vars
      |> Map.merge(border_css_vars(assigns.border))
      |> Map.merge(background_css_vars(assigns.background))

    BrowserAttrs.from_css_vars(css_vars)
  end

  defp border_css_vars(nil), do: %{}
  defp border_css_vars(""), do: %{}

  defp border_css_vars(value) do
    case to_string(value) do
      "none" ->
        %{"--live-ui-border-width" => "0"}

      "subtle" ->
        %{
          "--live-ui-border-width" => "1px",
          "--live-ui-border-style" => "solid",
          "--live-ui-border-color" => "var(--live-ui-theme-border-muted)"
        }

      "strong" ->
        %{
          "--live-ui-border-width" => "1px",
          "--live-ui-border-style" => "solid",
          "--live-ui-border-color" => "var(--live-ui-theme-border-strong)"
        }

      "panel" ->
        %{
          "--live-ui-border-width" => "1px",
          "--live-ui-border-style" => "solid",
          "--live-ui-border-color" => "var(--live-ui-theme-border-muted)"
        }

      _other ->
        %{}
    end
  end

  defp background_css_vars(nil), do: %{}
  defp background_css_vars(""), do: %{}

  defp background_css_vars(value) do
    case to_string(value) do
      "transparent" ->
        %{"--live-ui-background" => "transparent"}

      "surface" ->
        %{"--live-ui-background" => "var(--live-ui-theme-surface-base)"}

      "panel" ->
        %{
          "--live-ui-background" =>
            "linear-gradient(180deg, color-mix(in srgb, var(--live-ui-theme-surface-panel) 78%, black) 0%, color-mix(in srgb, var(--live-ui-theme-surface-base) 88%, black) 100%)"
        }

      "analysis" ->
        %{
          "--live-ui-background" =>
            "linear-gradient(180deg, color-mix(in srgb, var(--live-ui-theme-surface-base) 90%, var(--live-ui-theme-accent) 10%) 0%, var(--live-ui-theme-surface-base) 100%)"
        }

      _other ->
        %{}
    end
  end
end
