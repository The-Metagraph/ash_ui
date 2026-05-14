defmodule LiveUi.Widgets.Icon do
  @moduledoc """
  Baseline native icon widget.
  """

  use LiveUi.Component, family: :content, name: :icon

  LiveUi.Component.common_attrs()
  attr(:name, :string, required: true)
  attr(:set, :string, default: nil)
  attr(:fallback_text, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <span
      id={@id}
      data-live-ui-widget="icon"
      data-live-ui-icon={@name}
      data-live-ui-icon-set={@set}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @fallback_text || @name %></span>
    """
  end
end
