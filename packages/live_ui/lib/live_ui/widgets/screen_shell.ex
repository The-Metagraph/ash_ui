defmodule LiveUi.Widgets.ScreenShell do
  @moduledoc """
  Baseline screen shell used by direct native `live_ui` screens.
  """

  use LiveUi.Component,
    family: :layout,
    name: :screen_shell,
    assigns: [:title],
    slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:title, :string, required: true)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <main
      id={@id}
      data-live-ui-widget="screen-shell"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <header>
        <h1><%= @title %></h1>
      </header>
      <section>
        <%= render_slot(@inner_block) %>
      </section>
    </main>
    """
  end
end
