defmodule LiveUi.Widgets.Separator do
  @moduledoc """
  Baseline native separator widget.
  """

  use LiveUi.Component, family: :layout, name: :separator

  LiveUi.Component.common_attrs()
  attr(:orientation, :string, default: "horizontal")

  @impl true
  def render(assigns) do
    ~H"""
    <hr
      id={@id}
      data-live-ui-widget="separator"
      data-live-ui-orientation={@orientation}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    />
    """
  end
end
