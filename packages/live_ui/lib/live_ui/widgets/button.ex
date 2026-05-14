defmodule LiveUi.Widgets.Button do
  @moduledoc """
  Baseline native button widget.
  """

  use LiveUi.Component, family: :content, name: :button, assigns: [:disabled], events: [:click]

  LiveUi.Component.common_attrs()
  attr(:label, :string, required: true)
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button")

  @impl true
  def render(assigns) do
    ~H"""
    <button
      id={@id}
      type={@type}
      disabled={@disabled}
      data-live-ui-widget="button"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @label %></button>
    """
  end
end
