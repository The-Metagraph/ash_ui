defmodule LiveUi.Widgets.Text do
  @moduledoc """
  Baseline native text widget.
  """

  use LiveUi.Component, family: :content, name: :text, assigns: [:content]

  LiveUi.Component.common_attrs()
  attr(:content, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <span
      id={@id}
      data-live-ui-widget="text"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @content %></span>
    """
  end
end
