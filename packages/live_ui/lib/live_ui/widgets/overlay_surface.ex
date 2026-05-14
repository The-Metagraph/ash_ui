defmodule LiveUi.Widgets.OverlaySurface do
  @moduledoc """
  Native overlay-surface widget that composes a base region with layered overlays.
  """

  alias LiveUi.BrowserAttrs

  use LiveUi.Component, family: :overlay, name: :overlay_surface, slots: [:base, :overlay]

  LiveUi.Component.common_attrs()
  attr(:mode, :string, default: "stacked")
  attr(:background_fill, :string, default: "transparent")
  attr(:dismissible, :boolean, default: false)
  attr(:focus_scope, :string, default: nil)
  slot(:base, required: true)
  slot(:overlay)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:diagnostics, LiveUi.Diagnostics.validate_overlay_surface(assigns.base))
      |> assign(:resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="overlay-surface"
      data-live-ui-mode={@mode}
      data-live-ui-background-fill={@background_fill}
      data-live-ui-dismissible={@dismissible}
      data-live-ui-focus-scope={@focus_scope}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
      <div data-live-ui-overlay-slot="base"><%= render_slot(@base) %></div>
      <%= for overlay <- @overlay do %>
        <div data-live-ui-overlay-slot="overlay"><%= render_slot([overlay]) %></div>
      <% end %>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    assigns.background_fill
    |> scrim_css()
    |> BrowserAttrs.from_css_vars()
  end

  defp scrim_css(nil), do: %{}

  defp scrim_css(value) do
    case to_string(value) do
      "transparent" ->
        %{"--live-ui-overlay-scrim" => "transparent"}

      "none" ->
        %{"--live-ui-overlay-scrim" => "transparent"}

      "scrim" ->
        %{"--live-ui-overlay-scrim" => "hsl(222 47% 11% / 0.76)"}

      other when other in ["soft", "muted"] ->
        %{"--live-ui-overlay-scrim" => "hsl(222 30% 8% / 0.52)"}

      _other ->
        %{}
    end
  end
end
