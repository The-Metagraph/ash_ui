defmodule LiveUi.Widgets.Canvas do
  @moduledoc """
  Native canvas primitive for positioned drawing operations.
  """

  alias LiveUi.BrowserAttrs

  use LiveUi.Component, family: :display, name: :canvas, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:operations, :list, default: [])
  attr(:width, :integer, default: nil)
  attr(:height, :integer, default: nil)
  attr(:unit, :string, default: "cell")
  attr(:background, :string, default: nil)
  attr(:clip, :boolean, default: true)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:diagnostics, LiveUi.Diagnostics.validate_canvas(assigns.operations))
      |> assign(:resolved_rest, BrowserAttrs.merge(browser_attrs(assigns), assigns.rest))

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="canvas"
      data-live-ui-width={@width}
      data-live-ui-height={@height}
      data-live-ui-unit={@unit}
      data-live-ui-background={@background}
      data-live-ui-clip={@clip}
      data-live-ui-operation-count={length(@operations)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@resolved_rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
      <%= for operation <- @operations do %>
        <div
          data-live-ui-canvas-op={operation[:kind] || operation["kind"]}
          data-live-ui-canvas-x={coord(operation, :position, :x)}
          data-live-ui-canvas-y={coord(operation, :position, :y)}
          style={operation_style(operation)}
        >
          <%= operation[:text] || operation["text"] %>
        </div>
      <% end %>
    </section>
    """
  end

  defp browser_attrs(assigns) do
    %{}
    |> maybe_put("--live-ui-canvas-columns", assigns.width)
    |> maybe_put("--live-ui-canvas-rows", assigns.height)
    |> maybe_put("--live-ui-width", if(assigns.width, do: "fit-content"))
    |> maybe_put("--live-ui-overflow", if(assigns.clip, do: "hidden", else: "visible"))
    |> Map.merge(background_css(assigns.background))
    |> BrowserAttrs.from_css_vars()
  end

  defp background_css(nil), do: %{}
  defp background_css(""), do: %{}

  defp background_css(value) do
    case to_string(value) do
      "transparent" ->
        %{"--live-ui-background" => "transparent"}

      "surface" ->
        %{"--live-ui-background" => "var(--live-ui-theme-surface-base)"}

      "analysis" ->
        %{
          "--live-ui-background" =>
            "linear-gradient(180deg, color-mix(in srgb, var(--live-ui-theme-surface-base) 84%, var(--live-ui-theme-accent) 16%) 0%, color-mix(in srgb, var(--live-ui-theme-surface-base) 96%, black) 100%)"
        }

      _other ->
        %{"--live-ui-background" => "var(--live-ui-theme-surface-panel)"}
    end
  end

  defp operation_style(operation) do
    operation
    |> position_css_vars()
    |> BrowserAttrs.style_string()
  end

  defp position_css_vars(operation) do
    x = coord(operation, :position, :x) || 0
    y = coord(operation, :position, :y) || 0

    %{
      "--live-ui-canvas-col" => to_string(x + 1),
      "--live-ui-canvas-row" => to_string(y + 1)
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, to_string(value))

  defp coord(operation, key, axis) do
    operation
    |> fetch_map(key)
    |> case do
      nil -> nil
      map -> Map.get(map, axis) || Map.get(map, Atom.to_string(axis))
    end
  end

  defp fetch_map(operation, key) do
    Map.get(operation, key) || Map.get(operation, Atom.to_string(key))
  end
end
