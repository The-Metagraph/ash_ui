defmodule LiveUi.Widgets.BarChart do
  @moduledoc """
  Native bar-chart widget.
  """

  use LiveUi.Component, family: :display, name: :bar_chart

  LiveUi.Component.common_attrs()
  attr(:series, :list, default: [])

  @impl true
  def render(assigns) do
    ~H"""
    <figure
      id={@id}
      data-live-ui-widget="bar-chart"
      data-live-ui-series={inspect(@series)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ></figure>
    """
  end
end
