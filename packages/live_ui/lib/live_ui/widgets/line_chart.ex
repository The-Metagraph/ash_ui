defmodule LiveUi.Widgets.LineChart do
  @moduledoc """
  Native line-chart widget.
  """

  use LiveUi.Component, family: :display, name: :line_chart

  LiveUi.Component.common_attrs()
  attr(:series, :list, default: [])

  @impl true
  def render(assigns) do
    ~H"""
    <figure
      id={@id}
      data-live-ui-widget="line-chart"
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
