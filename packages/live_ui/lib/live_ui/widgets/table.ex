defmodule LiveUi.Widgets.Table do
  @moduledoc """
  Native table widget for structured data.
  """

  use LiveUi.Component, family: :data, name: :table, events: [:click, :selection]

  LiveUi.Component.common_attrs()
  attr(:columns, :list, default: [])
  attr(:rows, :list, default: [])
  attr(:dense, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <table
      id={@id}
      data-live-ui-widget="table"
      data-live-ui-dense={@dense}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <thead>
        <tr>
          <%= for column <- @columns do %>
            <th data-column-id={column[:id]}><%= column[:label] %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for row <- @rows do %>
          <tr
            data-row-id={row[:id]}
            data-selected={row[:selected]}
            class={row[:class]}
            {Map.get(row, :attrs, %{})}
          >
            <%= for cell <- row[:cells] || [] do %>
              <td><%= cell %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
