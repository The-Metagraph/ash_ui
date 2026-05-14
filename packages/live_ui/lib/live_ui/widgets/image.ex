defmodule LiveUi.Widgets.Image do
  @moduledoc """
  Baseline native image widget.
  """

  use LiveUi.Component, family: :content, name: :image

  LiveUi.Component.common_attrs()
  attr(:src, :string, required: true)
  attr(:alt, :string, default: "")
  attr(:fit, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <img
      id={@id}
      src={@src}
      alt={@alt}
      data-live-ui-widget="image"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-live-ui-fit={@fit}
      class={@class}
      {@rest}
    />
    """
  end
end
