defmodule LiveUi.Widgets.Sparkline do
  @moduledoc """
  Native sparkline widget.
  """

  use LiveUi.Component, family: :display, name: :sparkline

  LiveUi.Component.common_attrs()
  attr(:series, :list, default: [])

  @impl true
  def render(assigns) do
    ~H"""
    <figure
      id={@id}
      data-live-ui-widget="sparkline"
      data-live-ui-points={inspect(@series)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ></figure>
    """
  end
end
