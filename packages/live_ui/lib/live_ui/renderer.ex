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
    props = iur["props"] || %{}
    content = text_prop(props, ["content", "text"], "")
    size = prop(props, "size", 14)
    color = prop(props, "color", "inherit")
    weight = prop(props, "weight", "normal")
    align = prop(props, "align", "inherit")

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

  defp generate_heex(%{"type" => "label"} = iur, _opts) do
    props = iur["props"] || %{}
    content = text_prop(props, ["text", "content", "label"], "")

    """
    <label class="#{css_classes(["ash-label", prop_class(iur)])}"#{attr("for", dom_id(prop(props, "for")))}#{style_attr(prop_style(iur))}>#{content}</label>
    """
  end

  defp generate_heex(%{"type" => "badge"} = iur, opts) do
    props = iur["props"] || %{}
    presentation = prop(props, "presentation", "default")
    content = text_prop(props, ["text", "label", "content"], "")

    """
    <span class="#{css_classes(["ash-badge", "ash-badge-#{presentation}", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{content}
      #{generate_children(iur["children"], opts)}
    </span>
    """
  end

  defp generate_heex(%{"type" => "hero"} = iur, opts) do
    props = iur["props"] || %{}
    eyebrow = text_prop(props, "eyebrow")
    title = text_prop(props, "title")
    message = text_prop(props, "message")

    """
    <section class="#{css_classes(["ash-hero", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{if eyebrow, do: "<p class=\"ash-hero-eyebrow\">#{eyebrow}</p>", else: ""}
      #{if title, do: "<h1 class=\"ash-hero-title\">#{title}</h1>", else: ""}
      #{if message, do: "<p class=\"ash-hero-message\">#{message}</p>", else: ""}
      #{generate_children(iur["children"], opts)}
    </section>
    """
  end

  defp generate_heex(%{"type" => "stat"} = iur, _opts) do
    props = iur["props"] || %{}
    title = text_prop(props, "title")
    value = text_prop(props, "value")
    message = text_prop(props, "message")

    """
    <article class="#{css_classes(["ash-stat", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{if title, do: "<p class=\"ash-stat-title\">#{title}</p>", else: ""}
      #{if value, do: "<p class=\"ash-stat-value\">#{value}</p>", else: ""}
      #{if message, do: "<p class=\"ash-stat-message\">#{message}</p>", else: ""}
    </article>
    """
  end

  defp generate_heex(%{"type" => "key_value"} = iur, _opts) do
    props = iur["props"] || %{}
    label = text_prop(props, ["label", "title"])
    value = text_prop(props, "value")
    description = text_prop(props, "description")

    """
    <dl class="#{css_classes(["ash-key-value", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{if label, do: "<dt class=\"ash-key-value-label\">#{label}</dt>", else: ""}
      #{if value, do: "<dd class=\"ash-key-value-value\">#{value}</dd>", else: ""}
      #{if description, do: "<dd class=\"ash-key-value-description\">#{description}</dd>", else: ""}
    </dl>
    """
  end

  defp generate_heex(%{"type" => "info_list"} = iur, _opts) do
    props = iur["props"] || %{}
    items = prop(props, "items", [])
    list_tag = if prop(props, "ordered?", false), do: "ol", else: "ul"

    items_html =
      Enum.map_join(items, fn item ->
        item = normalize_item(item)
        label = text_prop(item, ["label", "title", "value", "id"], "")
        value = text_prop(item, "value")

        """
        <li class="ash-info-list-item">
          <span class="ash-info-list-label">#{label}</span>
          #{if value && value != label, do: "<span class=\"ash-info-list-value\">#{value}</span>", else: ""}
        </li>
        """
      end)

    """
    <#{list_tag} class="#{css_classes(["ash-info-list", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{items_html}
    </#{list_tag}>
    """
  end

  defp generate_heex(%{"type" => "form_builder"} = iur, opts) do
    """
    <form class="#{css_classes(["ash-form-builder", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{generate_children(iur["children"], opts)}
    </form>
    """
  end

  defp generate_heex(%{"type" => "form_field"} = iur, opts) do
    props = iur["props"] || %{}

    """
    <div class="#{css_classes(["ash-form-field", prop_class(iur)])}"#{attr("data-field-name", dom_id(prop(props, "name")))}#{style_attr(prop_style(iur))}>
      #{generate_children(iur["children"], opts)}
    </div>
    """
  end

  defp generate_heex(%{"type" => "button"} = iur, opts) do
    label = Map.get(iur["props"] || %{}, "label", "Button")
    variant = Map.get(iur["props"] || %{}, "variant", "primary")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "event")

    """
    <button type="button" class="#{css_classes(["ash-button", "ash-button-#{variant}", prop_class(iur)])}"#{style_attr(prop_style(iur))} phx-click="#{event_name(event_prefix, :action)}"#{attr("phx-value-action_id", binding && binding["id"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", binding_signal(binding, "click"))}>#{label}</button>
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
    <textarea class="#{css_classes(["ash-textarea", prop_class(iur)])}" name="#{name}" rows="#{rows}" placeholder="#{placeholder}"#{style_attr(prop_style(iur))} phx-blur="#{event_name(event_prefix, :change)}" phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}>#{value}</textarea>
    """
  end

  defp generate_heex(%{"type" => "checkbox"} = iur, opts) do
    name = Map.get(iur["props"] || %{}, "name", "checkbox")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    checked = if Map.get(iur["props"] || %{}, "checked"), do: " checked", else: ""
    binding = find_binding(opts, iur["id"], "bidirectional")

    """
    <input type="checkbox" class="#{css_classes(["ash-checkbox", prop_class(iur)])}" name="#{name}"#{style_attr(prop_style(iur))}#{checked} phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")} />
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
    <select class="#{css_classes(["ash-select", prop_class(iur)])}" name="#{name}"#{style_attr(prop_style(iur))} phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}>
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

  defp generate_heex(%{"type" => "presence_dot"} = iur, _opts) do
    props = iur["props"] || %{}
    state = Map.get(props, "state", "live")
    size = Map.get(props, "size", "medium")
    aria_label = Map.get(props, "aria_label")

    size_class =
      case size do
        "small" -> "ash-presence-dot-small"
        "large" -> "ash-presence-dot-large"
        _ -> "ash-presence-dot-medium"
      end

    bg_style = state_css_var(state)
    aria_attr = if aria_label, do: " aria-label=\"#{aria_label}\"", else: " aria-hidden=\"true\""

    """
    <span class="#{css_classes(["ash-presence-dot", size_class, prop_class(iur)])}" data-state="#{state}" style="#{bg_style}"#{aria_attr}></span>
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
    <input type="#{type}" class="#{css_classes(["ash-#{css_base}", prop_class(iur)])}" name="#{name}" value="#{value}" placeholder="#{placeholder}"#{style_attr(prop_style(iur))} phx-blur="#{event_name(event_prefix, :change)}" phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")} />
    """
  end

  defp find_binding(opts, element_id, type) do
    opts
    |> Map.get(:bindings, [])
    |> Enum.find(fn binding ->
      binding["element_id"] == element_id and binding["type"] == type
    end)
  end

  defp binding_signal(nil, default), do: default

  defp binding_signal(binding, default) do
    metadata = Map.get(binding, "metadata", %{})
    Map.get(metadata, "owner_signal") || Map.get(metadata, "signal") || default
  end

  defp prop_class(iur), do: Map.get(iur["props"] || %{}, "class")

  defp prop_style(iur) do
    props = iur["props"] || %{}

    prop(props, "inline_style") ||
      case prop(props, "style") do
        %{"extra" => %{"css" => css}} when is_binary(css) and css != "" -> css
        %{extra: %{css: css}} when is_binary(css) and css != "" -> css
        style when is_binary(style) -> style
        _other -> nil
      end
  end

  defp prop(props, key, default \\ nil) when is_map(props) and is_binary(key) do
    Map.get(props, key, Map.get(props, String.to_atom(key), default))
  rescue
    ArgumentError -> Map.get(props, key, default)
  end

  defp text_prop(props, keys, default \\ nil)

  defp text_prop(props, keys, default) when is_list(keys) do
    Enum.find_value(keys, default, fn key ->
      case prop(props, key) do
        value when value in [nil, "", []] -> false
        value -> to_string(value)
      end
    end)
  end

  defp text_prop(props, key, default), do: text_prop(props, [key], default)

  defp normalize_item(item) when is_map(item), do: item

  defp normalize_item(item) when is_list(item) do
    if Keyword.keyword?(item), do: Enum.into(item, %{}), else: %{"value" => item}
  end

  defp normalize_item(item), do: %{"value" => item}

  defp dom_id(nil), do: nil
  defp dom_id(value) when is_atom(value), do: Atom.to_string(value)
  defp dom_id(value), do: to_string(value)

  defp css_classes(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp state_css_var("live"), do: "background-color: var(--presence-live, var(--accent));"
  defp state_css_var("idle"), do: "background-color: var(--presence-idle, var(--ink-faint));"

  defp state_css_var("warn"),
    do: "background-color: var(--presence-warn, var(--warn, var(--accent-strong)));"

  defp state_css_var("muted"), do: "background-color: var(--presence-muted, var(--rule));"
  defp state_css_var("quiet"), do: "background-color: var(--presence-quiet, var(--rule-faint));"
  defp state_css_var(other), do: "background-color: var(--presence-#{other}, var(--ink-faint));"

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
