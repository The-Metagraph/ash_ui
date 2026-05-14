defmodule LiveUi.Widgets.MarkdownViewer do
  @moduledoc """
  Native markdown/document viewer widget.
  """

  use LiveUi.Component, family: :data, name: :markdown_viewer

  LiveUi.Component.common_attrs()
  attr(:source, :string, required: true)
  attr(:mode, :string, default: "rendered")

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      data-live-ui-widget="markdown-viewer"
      data-live-ui-mode={@mode}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <pre><%= @source %></pre>
    </article>
    """
  end
end
