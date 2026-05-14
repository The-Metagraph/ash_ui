defmodule LiveUi.Widgets.Label do
  @moduledoc """
  Baseline native label widget.
  """

  use LiveUi.Component, family: :content, name: :label

  LiveUi.Component.common_attrs()
  attr(:for, :string, default: nil)
  attr(:content, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <label
      id={@id}
      for={@for}
      data-live-ui-widget="label"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @content %></label>
    """
  end
end
