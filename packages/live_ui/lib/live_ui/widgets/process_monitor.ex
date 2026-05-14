defmodule LiveUi.Widgets.ProcessMonitor do
  @moduledoc """
  Native process-monitor widget.
  """

  use LiveUi.Component, family: :operational, name: :process_monitor, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:processes, :list, default: [])

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="process-monitor"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= for process <- @processes do %>
        <div data-process-id={process[:id]}>
          <span><%= process[:pid] || process[:label] || process[:id] %></span>
          <span><%= inspect(process[:state]) %></span>
        </div>
      <% end %>
    </section>
    """
  end
end
