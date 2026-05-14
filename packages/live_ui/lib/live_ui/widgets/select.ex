defmodule LiveUi.Widgets.Select do
  @moduledoc """
  Baseline native select widget.
  """

  use LiveUi.Component, family: :input, name: :select, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:name, :string, required: true)
  attr(:options, :list, default: [])
  attr(:multiple, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <select
      id={@id}
      name={@name}
      multiple={@multiple}
      disabled={@disabled}
      data-live-ui-widget="select"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= for option <- @options do %>
        <option
          value={option[:value]}
          selected={option[:selected]}
          disabled={option[:disabled]}
        ><%= option[:label] %></option>
      <% end %>
    </select>
    """
  end
end
