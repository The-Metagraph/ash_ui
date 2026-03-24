defmodule LiveUI.Renderer do
  @moduledoc """
  Minimal HEEx renderer package used by Ash UI in external renderer mode.
  """

  @spec render(map(), keyword()) :: {:ok, String.t()}
  def render(canonical_iur, opts \\ []) when is_map(canonical_iur) do
    {:ok,
     generate_heex(canonical_iur, %{
       optimize_patches: Keyword.get(opts, :optimize_patches, true),
       event_prefix: Keyword.get(opts, :event_prefix, "ash_ui"),
       bindings: Map.get(canonical_iur, "bindings", [])
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
    <div class="#{css_classes(["ash-screen", "ash-screen-#{iur["name"]}", prop_class(iur)])}"#{style_attr(prop_style(iur))} data-screen-id="#{iur["id"]}"#{patch_attrs}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "row"} = iur, opts) do
    spacing = Map.get(iur["props"] || %{}, "spacing", 8)

    style =
      merge_style(["display: flex", "flex-direction: row", "gap: #{spacing}px"], prop_style(iur))

    """
    <div class="#{css_classes(["ash-row", prop_class(iur)])}"#{style_attr(style)}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "column"} = iur, opts) do
    spacing = Map.get(iur["props"] || %{}, "spacing", 8)

    style =
      merge_style(
        ["display: flex", "flex-direction: column", "gap: #{spacing}px"],
        prop_style(iur)
      )

    """
    <div class="#{css_classes(["ash-column", prop_class(iur)])}"#{style_attr(style)}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "grid"} = iur, opts) do
    props = iur["props"] || %{}
    columns = Map.get(props, "columns", 2)
    spacing = Map.get(props, "spacing", 8)

    style =
      merge_style(
        [
          "display: grid",
          "grid-template-columns: repeat(#{columns}, minmax(0, 1fr))",
          "gap: #{spacing}px"
        ],
        prop_style(iur)
      )

    """
    <div class="#{css_classes(["ash-grid", prop_class(iur)])}"#{style_attr(style)}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "stack"} = iur, opts) do
    style =
      merge_style(
        ["display: grid", "gap: #{Map.get(iur["props"] || %{}, "spacing", 0)}px"],
        prop_style(iur)
      )

    """
    <div class="#{css_classes(["ash-stack", prop_class(iur)])}"#{style_attr(style)}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "card"} = iur, opts) do
    """
    <section class="#{css_classes(["ash-card", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{generate_children(iur["children"], opts)}
    </section>
    """
  end

  defp generate_heex(%{"type" => "text"} = iur, _opts) do
    content = Map.get(iur["props"] || %{}, "content", "")
    size = Map.get(iur["props"] || %{}, "size", 14)
    color = Map.get(iur["props"] || %{}, "color", "inherit")
    weight = Map.get(iur["props"] || %{}, "weight", "normal")
    align = Map.get(iur["props"] || %{}, "align", "inherit")

    style =
      merge_style(
        [
          "font-size: #{size}px",
          "color: #{color}",
          "font-weight: #{weight}",
          "text-align: #{align}"
        ],
        prop_style(iur)
      )

    """
    <span class="#{css_classes(["ash-text", prop_class(iur)])}"#{style_attr(style)}>#{content}</span>
    """
  end

  defp generate_heex(%{"type" => "button"} = iur, opts) do
    label = Map.get(iur["props"] || %{}, "label", "Button")
    variant = Map.get(iur["props"] || %{}, "variant", "primary")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "event")

    """
    <button type="button" class="#{css_classes(["ash-button", "ash-button-#{variant}", prop_class(iur)])}"#{style_attr(prop_style(iur))} phx-click="#{event_name(event_prefix, :action)}"#{attr("phx-value-action_id", binding && binding["id"])}>#{label}</button>
    """
  end

  defp generate_heex(%{"type" => "input"} = iur, opts) do
    render_text_input(iur, opts, "input")
  end

  defp generate_heex(%{"type" => "textarea"} = iur, opts) do
    name = Map.get(iur["props"] || %{}, "name", "textarea")
    placeholder = Map.get(iur["props"] || %{}, "placeholder", "")
    value = Map.get(iur["props"] || %{}, "value", "")
    rows = Map.get(iur["props"] || %{}, "rows", 4)
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "bidirectional")

    """
    <textarea class="#{css_classes(["ash-textarea", prop_class(iur)])}" name="#{name}" rows="#{rows}" placeholder="#{placeholder}"#{style_attr(prop_style(iur))} phx-blur="#{event_name(event_prefix, :change)}" phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}>#{value}</textarea>
    """
  end

  defp generate_heex(%{"type" => "checkbox"} = iur, opts) do
    name = Map.get(iur["props"] || %{}, "name", "checkbox")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    checked = if Map.get(iur["props"] || %{}, "checked"), do: " checked", else: ""
    binding = find_binding(opts, iur["id"], "bidirectional")

    """
    <input type="checkbox" class="#{css_classes(["ash-checkbox", prop_class(iur)])}" name="#{name}"#{style_attr(prop_style(iur))}#{checked} phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])} />
    """
  end

  defp generate_heex(%{"type" => "select"} = iur, opts) do
    name = Map.get(iur["props"] || %{}, "name", "select")
    options = Map.get(iur["props"] || %{}, "options", [])
    selected_value = Map.get(iur["props"] || %{}, "value")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "bidirectional")

    options_html =
      Enum.map_join(options, fn option ->
        {label, option_value} = if is_binary(option), do: {option, option}, else: option

        selected =
          if to_string(option_value) == to_string(selected_value), do: " selected", else: ""

        "<option value=\"#{option_value}\"#{selected}>#{label}</option>"
      end)

    """
    <select class="#{css_classes(["ash-select", prop_class(iur)])}" name="#{name}"#{style_attr(prop_style(iur))} phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}>
      #{options_html}
    </select>
    """
  end

  defp generate_heex(%{"type" => "divider"} = iur, _opts) do
    """
    <hr class="#{css_classes(["ash-divider", prop_class(iur)])}"#{style_attr(prop_style(iur))} />
    """
  end

  defp generate_heex(%{"type" => "spacer"} = iur, _opts) do
    size = Map.get(iur["props"] || %{}, "size", 8)

    """
    <div class="#{css_classes(["ash-spacer", prop_class(iur)])}"#{style_attr(merge_style(["height: #{size}px"], prop_style(iur)))}></div>
    """
  end

  defp generate_heex(iur, opts) do
    """
    <div class="#{css_classes(["ash-widget", "ash-widget-#{iur["type"]}", prop_class(iur)])}"#{style_attr(prop_style(iur))} data-widget-id="#{iur["id"]}">
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_children(nil, _opts), do: ""
  defp generate_children([], _opts), do: ""
  defp generate_children(children, opts), do: Enum.map_join(children, &generate_heex(&1, opts))

  defp render_text_input(iur, opts, css_base) do
    props = iur["props"] || %{}
    name = Map.get(props, "name", "input")
    placeholder = Map.get(props, "placeholder", "")
    value = Map.get(props, "value", "")
    type = Map.get(props, "type", "text")
    binding = find_binding(opts, iur["id"], "bidirectional")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")

    """
    <input type="#{type}" class="#{css_classes(["ash-#{css_base}", prop_class(iur)])}" name="#{name}" value="#{value}" placeholder="#{placeholder}"#{style_attr(prop_style(iur))} phx-blur="#{event_name(event_prefix, :change)}" phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])} />
    """
  end

  defp find_binding(opts, element_id, type) do
    opts
    |> Map.get(:bindings, [])
    |> Enum.find(fn binding ->
      binding["element_id"] == element_id and binding["type"] == type
    end)
  end

  defp prop_class(iur), do: Map.get(iur["props"] || %{}, "class")
  defp prop_style(iur), do: Map.get(iur["props"] || %{}, "style")

  defp css_classes(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp style_attr(nil), do: ""
  defp style_attr(""), do: ""
  defp style_attr(style), do: " style=\"#{style}\""

  defp attr(_name, nil), do: ""
  defp attr(_name, ""), do: ""
  defp attr(name, value), do: " #{name}=\"#{value}\""

  defp merge_style(defaults, extra) do
    defaults
    |> List.wrap()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Kernel.++(if extra in [nil, ""], do: [], else: [extra])
    |> Enum.join("; ")
  end

  defp event_name(prefix, :action), do: "#{prefix}_action"
  defp event_name(prefix, :change), do: "#{prefix}_change"
end
