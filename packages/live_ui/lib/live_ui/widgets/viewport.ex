defmodule LiveUi.Widgets.Viewport do
  @moduledoc """
  Native viewport primitive for clipped and scrollable regions.
  """

  alias LiveUi.BrowserAttrs
  alias LiveUi.Style.Browser

  use LiveUi.Component, family: :display, name: :viewport, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:axis, :string, default: "vertical")
  attr(:offset_x, :integer, default: 0)
  attr(:offset_y, :integer, default: 0)
  attr(:clip, :boolean, default: true)
  attr(:scrollbars, :string, default: "auto")
  attr(:width, :string, default: nil)
  attr(:height, :string, default: nil)
  attr(:sync_group, :string, default: nil)
  attr(:independent_scroll, :boolean, default: false)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:diagnostics, LiveUi.Diagnostics.validate_viewport(assigns.inner_block))
      |> assign(:resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="viewport"
      data-live-ui-axis={@axis}
      data-live-ui-offset-x={@offset_x}
      data-live-ui-offset-y={@offset_y}
      data-live-ui-clip={@clip}
      data-live-ui-scrollbars={@scrollbars}
      data-live-ui-width={@width}
      data-live-ui-height={@height}
      data-live-ui-sync-group={@sync_group}
      data-live-ui-independent-scroll={@independent_scroll}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
      <div data-live-ui-viewport-slot="content"><%= render_slot(@inner_block) %></div>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    Browser.realize(%{
      sizing: %{width: assigns.width, height: assigns.height}
    }).css_vars
    |> Map.merge(offset_css(assigns.offset_x, assigns.offset_y))
    |> Map.merge(overflow_css(assigns.axis, assigns.scrollbars, assigns.clip))
    |> BrowserAttrs.from_css_vars()
  end

  defp offset_css(offset_x, offset_y) do
    %{}
    |> maybe_put("--live-ui-viewport-offset-x", offset_x)
    |> maybe_put("--live-ui-viewport-offset-y", offset_y)
  end

  defp overflow_css(axis, scrollbars, clip) do
    cross_axis = if(clip, do: "hidden", else: "visible")
    scroll = scroll_value(scrollbars)

    case to_string(axis || "vertical") do
      "horizontal" ->
        %{"--live-ui-overflow-x" => scroll, "--live-ui-overflow-y" => cross_axis}

      "both" ->
        %{"--live-ui-overflow-x" => scroll, "--live-ui-overflow-y" => scroll}

      _other ->
        %{"--live-ui-overflow-x" => cross_axis, "--live-ui-overflow-y" => scroll}
    end
  end

  defp scroll_value(value) do
    case to_string(value || "auto") do
      "always" -> "scroll"
      "hidden" -> "hidden"
      "none" -> "hidden"
      _other -> "auto"
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, to_string(value))
end
