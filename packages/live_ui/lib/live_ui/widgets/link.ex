defmodule LiveUi.Widgets.Link do
  @moduledoc """
  Baseline native link widget.
  """

  use LiveUi.Component, family: :content, name: :link, events: [:click, :navigate]

  LiveUi.Component.common_attrs()
  attr(:label, :string, required: true)
  attr(:href, :string, required: true)
  attr(:external, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <a
      id={@id}
      href={@href}
      target={if @external, do: "_blank", else: nil}
      rel={if @external, do: "noreferrer noopener", else: nil}
      data-live-ui-widget="link"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @label %></a>
    """
  end
end
