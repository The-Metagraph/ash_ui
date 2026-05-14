defmodule LiveUi.Widgets.TextInput do
  @moduledoc """
  Baseline native text input widget.
  """

  use LiveUi.Component, family: :input, name: :text_input, events: [:change, :submit]

  LiveUi.Component.common_attrs()
  attr(:name, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:input_type, :string, default: "text")
  attr(:multiline, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  @impl true
  def render(%{multiline: true} = assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      placeholder={@placeholder}
      disabled={@disabled}
      data-live-ui-widget="text-input"
      data-live-ui-input-mode="multiline"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    ><%= @value %></textarea>
    """
  end

  def render(assigns) do
    ~H"""
    <input
      id={@id}
      type={@input_type}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      disabled={@disabled}
      data-live-ui-widget="text-input"
      data-live-ui-input-mode="singleline"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    />
    """
  end
end
