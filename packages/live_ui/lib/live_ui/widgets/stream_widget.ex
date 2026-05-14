defmodule LiveUi.Widgets.StreamWidget do
  @moduledoc """
  Native stream widget for append-only operational feeds.
  """

  use LiveUi.Component, family: :operational, name: :stream_widget, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:entries, :list, default: [])
  attr(:ordering, :string, default: "append_only")

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="stream-widget"
      data-live-ui-ordering={@ordering}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= for entry <- @entries do %>
        <p data-entry-id={entry[:id]} data-severity={entry[:severity]}><%= entry[:message] %></p>
      <% end %>
    </section>
    """
  end
end
