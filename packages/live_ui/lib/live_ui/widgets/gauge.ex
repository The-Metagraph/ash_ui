defmodule LiveUi.Widgets.Gauge do
  @moduledoc """
  Native gauge widget.
  """

  use LiveUi.Component, family: :feedback, name: :gauge

  LiveUi.Component.common_attrs()
  attr(:value, :integer, default: 0)
  attr(:min, :integer, default: 0)
  attr(:max, :integer, default: 100)
  attr(:label, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <figure
      id={@id}
      data-live-ui-widget="gauge"
      data-live-ui-value={@value}
      data-live-ui-min={@min}
      data-live-ui-max={@max}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <figcaption><%= @label || "Gauge" %>: <%= @value %></figcaption>
    </figure>
    """
  end
end
