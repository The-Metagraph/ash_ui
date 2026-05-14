defmodule LiveUi.Widgets.Progress do
  @moduledoc """
  Native progress widget.
  """

  use LiveUi.Component, family: :feedback, name: :progress

  LiveUi.Component.common_attrs()
  attr(:current, :integer, default: 0)
  attr(:total, :integer, default: 100)
  attr(:label, :string, default: nil)
  attr(:indeterminate, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <progress
      id={@id}
      value={if @indeterminate, do: nil, else: @current}
      max={@total}
      data-live-ui-widget="progress"
      data-live-ui-indeterminate={@indeterminate}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      aria-label={@label}
      {@rest}
    ><%= @label %></progress>
    """
  end
end
