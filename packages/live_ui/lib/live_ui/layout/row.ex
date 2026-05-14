defmodule LiveUi.Layout.Row do
  @moduledoc """
  Baseline horizontal layout primitive.
  """

  alias LiveUi.BrowserAttrs
  alias LiveUi.Style.Browser

  use LiveUi.Component, family: :layout, name: :row, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:gap, :string, default: nil)
  attr(:padding, :string, default: nil)
  attr(:align, :string, default: nil)
  attr(:justify, :string, default: nil)
  attr(:width, :string, default: nil)
  attr(:height, :string, default: nil)
  attr(:min_width, :string, default: nil)
  attr(:min_height, :string, default: nil)
  attr(:max_width, :string, default: nil)
  attr(:max_height, :string, default: nil)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <div
      id={@id}
      data-live-ui-widget="row"
      data-live-ui-gap={@gap}
      data-live-ui-padding={@padding}
      data-live-ui-align={@align}
      data-live-ui-justify={@justify}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp browser_attrs(assigns) do
    Browser.realize(%{
      spacing: %{gap: assigns.gap, padding: assigns.padding},
      sizing: %{
        width: assigns.width,
        height: assigns.height,
        min_width: assigns.min_width,
        min_height: assigns.min_height,
        max_width: assigns.max_width,
        max_height: assigns.max_height
      },
      alignment: %{align: assigns.align, justify: assigns.justify}
    }).css_vars
    |> BrowserAttrs.from_css_vars()
  end
end
