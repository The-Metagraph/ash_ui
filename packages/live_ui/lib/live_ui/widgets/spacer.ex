defmodule LiveUi.Widgets.Spacer do
  @moduledoc """
  Baseline native spacer widget.
  """

  use LiveUi.Component, family: :layout, name: :spacer

  LiveUi.Component.common_attrs()
  attr(:size, :string, default: "md")
  attr(:grow, :integer, default: 0)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-live-ui-widget="spacer"
      data-live-ui-size={@size}
      data-live-ui-grow={@grow}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ></div>
    """
  end
end
