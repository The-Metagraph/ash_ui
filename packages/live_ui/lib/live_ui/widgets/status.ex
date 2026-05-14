defmodule LiveUi.Widgets.Status do
  @moduledoc """
  Native status widget.
  """

  use LiveUi.Component, family: :feedback, name: :status

  LiveUi.Component.common_attrs()
  attr(:text, :string, required: true)
  attr(:severity, :string, default: "info")
  attr(:status, :string, default: "idle")

  @impl true
  def render(assigns) do
    ~H"""
    <p
      id={@id}
      data-live-ui-widget="status"
      data-live-ui-severity={@severity}
      data-live-ui-status={@status}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @text %></p>
    """
  end
end
