defmodule LiveUi.Widgets.Toggle do
  @moduledoc """
  Baseline native toggle widget.
  """

  use LiveUi.Component, family: :input, name: :toggle, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:name, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <label
      id={@id}
      data-live-ui-widget="toggle"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
    >
      <input type="checkbox" name={@name} checked={@checked} disabled={@disabled} {@rest} />
      <span data-live-ui-toggle-state={if @checked, do: "on", else: "off"}></span>
    </label>
    """
  end
end
