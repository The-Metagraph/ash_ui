defmodule LiveUI.Renderer do
  @moduledoc """
  Minimal HEEx renderer package used by Ash UI in external renderer mode.
  """

  @spec render(map(), keyword()) :: {:ok, String.t()}
  def render(canonical_iur, opts \\ []) when is_map(canonical_iur) do
    {:ok,
     generate_heex(canonical_iur, %{
       optimize_patches: Keyword.get(opts, :optimize_patches, true),
       event_prefix: Keyword.get(opts, :event_prefix, "ash")
     })}
  end

  defp generate_heex(%{"type" => "screen"} = iur, opts) do
    patch_attrs =
      if Map.get(opts, :optimize_patches, true) do
        " phx-update=\"stream\" id=\"#{iur["id"]}\""
      else
        " id=\"#{iur["id"]}\""
      end

    """
    <div class="ash-screen ash-screen-#{iur["name"]}" data-screen-id="#{iur["id"]}"#{patch_attrs}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "row"} = iur, opts) do
    """
    <div class="ash-row" style="gap: #{Map.get(iur["props"] || %{}, "spacing", 8)}px">
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "column"} = iur, opts) do
    """
    <div class="ash-column" style="gap: #{Map.get(iur["props"] || %{}, "spacing", 8)}px">
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "text"} = iur, _opts) do
    content = Map.get(iur["props"] || %{}, "content", "")
    size = Map.get(iur["props"] || %{}, "size", 14)
    color = Map.get(iur["props"] || %{}, "color", "inherit")

    """
    <span class="ash-text" style="font-size: #{size}px; color: #{color};">#{content}</span>
    """
  end

  defp generate_heex(%{"type" => "button"} = iur, opts) do
    label = Map.get(iur["props"] || %{}, "label", "Button")
    variant = Map.get(iur["props"] || %{}, "variant", "primary")
    event_prefix = Map.get(opts, :event_prefix, "ash")

    """
    <button class="ash-button ash-button-#{variant}" phx-click="#{event_prefix}:click" data-target="#{iur["id"]}">#{label}</button>
    """
  end

  defp generate_heex(%{"type" => "input"} = iur, opts) do
    event_prefix = Map.get(opts, :event_prefix, "ash")

    """
    <input class="ash-input" name="#{Map.get(iur["props"] || %{}, "name", "input")}" placeholder="#{Map.get(iur["props"] || %{}, "placeholder", "")}" phx-blur="#{event_prefix}:blur" phx-change="#{event_prefix}:change" data-target="#{iur["id"]}" />
    """
  end

  defp generate_heex(%{"type" => "checkbox"} = iur, opts) do
    event_prefix = Map.get(opts, :event_prefix, "ash")

    """
    <input type="checkbox" class="ash-checkbox" name="#{Map.get(iur["props"] || %{}, "name", "checkbox")}" phx-click="#{event_prefix}:toggle" data-target="#{iur["id"]}" />
    """
  end

  defp generate_heex(%{"type" => "select"} = iur, opts) do
    event_prefix = Map.get(opts, :event_prefix, "ash")

    options =
      iur["props"]
      |> Kernel.||(%{})
      |> Map.get("options", [])
      |> Enum.map_join(fn option ->
        {label, value} = if is_binary(option), do: {option, option}, else: option
        "<option value=\"#{value}\">#{label}</option>"
      end)

    """
    <select class="ash-select" name="#{Map.get(iur["props"] || %{}, "name", "select")}" phx-change="#{event_prefix}:change" data-target="#{iur["id"]}">
      #{options}
    </select>
    """
  end

  defp generate_heex(iur, opts) do
    """
    <div class="ash-widget ash-widget-#{iur["type"]}" data-widget-id="#{iur["id"]}">
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_children(nil, _opts), do: ""
  defp generate_children([], _opts), do: ""
  defp generate_children(children, opts), do: Enum.map_join(children, &generate_heex(&1, opts))
end
