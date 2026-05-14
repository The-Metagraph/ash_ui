defmodule LiveUi.Forms.Field do
  @moduledoc """
  Baseline native field wrapper connecting labels, controls, and help content.
  """

  use LiveUi.Component, family: :input, name: :field, slots: [:label, :control, :help]

  LiveUi.Component.common_attrs()
  attr(:name, :string, default: nil)
  slot(:label)
  slot(:control, required: true)
  slot(:help)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-live-ui-widget="field"
      data-live-ui-name={@name}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <div data-live-ui-field-slot="label"><%= render_slot(@label) %></div>
      <div data-live-ui-field-slot="control"><%= render_slot(@control) %></div>
      <%= if @help != [] do %>
        <div data-live-ui-field-slot="help"><%= render_slot(@help) %></div>
      <% end %>
    </div>
    """
  end
end
