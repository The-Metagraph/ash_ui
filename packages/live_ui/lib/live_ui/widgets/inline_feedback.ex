defmodule LiveUi.Widgets.InlineFeedback do
  @moduledoc """
  Native inline-feedback widget.
  """

  use LiveUi.Component, family: :feedback, name: :inline_feedback

  LiveUi.Component.common_attrs()
  attr(:message, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:severity, :string, default: "info")

  @impl true
  def render(assigns) do
    ~H"""
    <aside
      id={@id}
      data-live-ui-widget="inline-feedback"
      data-live-ui-severity={@severity}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= if @title do %><strong><%= @title %></strong><% end %>
      <span><%= @message %></span>
    </aside>
    """
  end
end
