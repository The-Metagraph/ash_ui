defmodule LiveUi.Forms.FieldGroup do
  @moduledoc """
  Baseline native field-group component.
  """

  use LiveUi.Component, family: :input, name: :field_group, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:legend, :string, default: nil)
  attr(:description, :string, default: nil)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <fieldset
      id={@id}
      data-live-ui-widget="field-group"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= if @legend do %>
        <legend><%= @legend %></legend>
      <% end %>
      <%= if @description do %>
        <p data-live-ui-field-group="description"><%= @description %></p>
      <% end %>
      <%= render_slot(@inner_block) %>
    </fieldset>
    """
  end
end
