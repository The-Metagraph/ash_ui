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

  defp generate_heex(%{"type" => "list"} = iur, opts) do
    props = iur["props"] || %{}
    ordered? = Map.get(props, "ordered", false)
    tag = if ordered?, do: "ol", else: "ul"

    items_html =
      cond do
        iur["children"] not in [nil, []] ->
          Enum.map_join(iur["children"], fn child ->
            "<li class=\"ash-list-item\">#{generate_heex(child, opts)}</li>"
          end)

        Map.get(props, "items", []) != [] ->
          Enum.map_join(Map.get(props, "items", []), fn item ->
            "<li class=\"ash-list-item\">#{render_list_item(item)}</li>"
          end)

        Map.get(props, "empty_text") ->
          "<li class=\"ash-list-item ash-list-empty\">#{Map.get(props, "empty_text")}</li>"

        true ->
          ""
      end

    """
    <#{tag} class="#{css_classes(["ash-list", prop_class(iur)])}"#{style_attr(default_list_style(prop_style(iur)))}>
      #{items_html}
    </#{tag}>
    """
  end

  defp generate_heex(%{"type" => "table"} = iur, opts) do
    props = iur["props"] || %{}
    caption_html = render_table_caption(Map.get(props, "caption"))
    header_html = render_table_header(Map.get(props, "columns", []))
    body_html = render_table_body(iur, opts)

    """
    <table class="#{css_classes(["ash-table", prop_class(iur)])}"#{style_attr(default_table_style(prop_style(iur)))}>
      #{caption_html}
      #{header_html}
      #{body_html}
    </table>
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

  defp render_list_item(%{"title" => title, "body" => body}) do
    """
    <div class="ash-list-item-body">
      <strong>#{title}</strong>
      <span>#{body}</span>
    </div>
    """
  end

  defp render_list_item(item), do: html_escape(item)

  defp render_table_caption(nil), do: ""
  defp render_table_caption(""), do: ""

  defp render_table_caption(caption) do
    "<caption>#{caption}</caption>"
  end

  defp render_table_header([]), do: ""

  defp render_table_header(columns) do
    headings =
      Enum.map_join(columns, fn column ->
        "<th>#{render_table_cell_value(column)}</th>"
      end)

    "<thead><tr>#{headings}</tr></thead>"
  end

  defp render_table_body(%{"children" => children} = _iur, opts) when children not in [nil, []] do
    rows =
      Enum.map_join(children, fn child ->
        render_table_row(child, opts)
      end)

    "<tbody>#{rows}</tbody>"
  end

  defp render_table_body(%{"props" => props}, _opts) do
    rows = Map.get(props || %{}, "rows", [])

    body =
      cond do
        rows != [] ->
          Enum.map_join(rows, fn row ->
            values =
              row
              |> List.wrap()
              |> Enum.map_join(fn value -> "<td>#{render_table_cell_value(value)}</td>" end)

            "<tr>#{values}</tr>"
          end)

        Map.get(props || %{}, "empty_text") ->
          "<tr><td colspan=\"100%\">#{Map.get(props || %{}, "empty_text")}</td></tr>"

        true ->
          ""
      end

    "<tbody>#{body}</tbody>"
  end

  defp render_table_row(%{"children" => cells} = row, opts) do
    style = style_attr(prop_style(row))

    contents =
      Enum.map_join(cells || [], fn cell ->
        "<td>#{generate_heex(cell, opts)}</td>"
      end)

    "<tr#{style}>#{contents}</tr>"
  end

  defp render_table_row(row, _opts) do
    "<tr><td>#{render_table_cell_value(row)}</td></tr>"
  end

  defp render_table_cell_value(%{"label" => label, "value" => value}), do: "#{label}: #{value}"
  defp render_table_cell_value({label, value}), do: "#{label}: #{value}"
  defp render_table_cell_value(value), do: html_escape(value)

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

  defp default_list_style(extra) do
    merge_style(
      [
        "display: flex",
        "flex-direction: column",
        "gap: 14px",
        "list-style: none",
        "margin: 0",
        "padding: 0"
      ],
      extra
    )
  end

  defp default_table_style(extra) do
    merge_style(
      [
        "width: 100%",
        "border-collapse: collapse",
        "border-spacing: 0"
      ],
      extra
    )
  end

  defp html_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp event_name(prefix, :action), do: "#{prefix}_action"
  defp event_name(prefix, :change), do: "#{prefix}_change"
end
