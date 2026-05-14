defmodule LiveUi.Widgets.LogViewer do
  @moduledoc """
  Native log-viewer widget.
  """

  use LiveUi.Component, family: :data, name: :log_viewer, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:entries, :list, default: [])
  attr(:wrap, :boolean, default: true)
  attr(:show_timestamps, :boolean, default: true)

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="log-viewer"
      data-live-ui-wrap={@wrap}
      data-live-ui-show-timestamps={@show_timestamps}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= for entry <- @entries do %>
        <p data-entry-id={entry[:id]} data-severity={entry[:severity]}>
          <%= if @show_timestamps && entry[:timestamp] do %>[<%= entry[:timestamp] %>] <% end %>
          <%= entry[:message] %>
        </p>
      <% end %>
    </section>
    """
  end
end
