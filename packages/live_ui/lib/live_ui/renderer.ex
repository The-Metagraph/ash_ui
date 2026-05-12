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

  # Ariston-local composite (per ADR 0021 §2). Reads the synthesized
  # `props.row` map populated by `IURHydration` when this element is the
  # destination of a `ui_relationship ... repeat` directive. The widget
  # renders the same HTML shape as `AristonUiWeb.Widgets.DocBlockNumbered`
  # so the ariston-ui CSS picks it up. The block-mark glyph and styling
  # come from tokens.css; no literal colors live here.
  defp generate_heex(%{"type" => "doc_block_numbered"} = iur, _opts) do
    props = iur["props"] || %{}
    row = Map.get(props, "row") || %{}
    block_id = to_string(Map.get(row, "id") || Map.get(props, "block_id") || iur["id"] || "")
    text = to_string(Map.get(row, "text") || Map.get(props, "content") || "")
    metadata = iur["metadata"] || %{}
    composition = Map.get(metadata, "composition") || %{}
    # `repeat_row_index` is 0-based on the clone; humans want 1-based.
    raw_index = Map.get(composition, "repeat_row_index")
    index = if is_integer(raw_index), do: raw_index + 1, else: Map.get(props, "index", 1)
    is_active = Map.get(props, "is_active", false)

    """
    <section class="ariston-doc-block-numbered" data-block-id="#{block_id}" data-active="#{to_string(is_active)}">
      <div class="ariston-doc-block-mark" aria-hidden="true">
        <span class="ariston-doc-block-glyph">⊢</span>
        <span class="ariston-doc-block-index">#{index}</span>
      </div>
      <div class="ariston-doc-block-body">#{text}</div>
    </section>
    """
  end

  # Ariston-local composite (per ADR 0021 §2). Renders one row in a chat
  # stream: avatar (left), meta line (author + timestamp + optional
  # presence_dot), and a body bubble. CSS lives in the consumer (ariston-ui
  # tokens.css / app.css); no inline colours here. The HTML shape mirrors the
  # clause in `lib/ash_ui/rendering/live_ui_adapter.ex` — both paths must
  # produce the same structure so ariston-ui CSS picks it up correctly.
  defp generate_heex(%{"type" => "chat_message_row"} = iur, _opts) do
    props = iur["props"] || %{}
    author = to_string(prop(props, "author") || "")
    timestamp = to_string(prop(props, "timestamp") || "")
    body = to_string(prop(props, "body") || "")
    avatar_variant = to_string(prop(props, "avatar_variant") || "neutral")
    presence = prop(props, "presence")

    # Derive the single initial for the avatar badge from the author name.
    initial =
      case String.trim(author) do
        "" -> "?"
        name -> name |> String.upcase() |> String.at(0) || "?"
      end

    # presence_dot HTML — rendered only when a presence state is provided.
    presence_html =
      if presence do
        state = to_string(presence)
        bg_style = state_css_var(state)

        "<span class=\"chat-message-row__presence ash-presence-dot ash-presence-dot-small\" data-state=\"#{state}\" style=\"#{bg_style}\" aria-hidden=\"true\"></span>"
      else
        ""
      end

    # Body lines: replace \n with <br> so multi-line messages render correctly.
    body_html = String.replace(body, "\n", "<br>")

    """
    <article class="#{css_classes(["chat-message-row", "chat-message-row--#{avatar_variant}", prop_class(iur)])}">
      <span class="chat-message-row__avatar ash-avatar ash-avatar-medium" style="background-color: var(--avatar-#{avatar_variant}, var(--bg-2));" data-variant="#{avatar_variant}" aria-hidden="true">
        <span aria-hidden="true">#{initial}</span>
      </span>
      <div class="chat-message-row__content">
        <div class="chat-message-row__meta">
          <span class="chat-message-row__author">#{author}</span>
          <span class="chat-message-row__timestamp">#{timestamp}</span>
          #{presence_html}
        </div>
        <div class="chat-message-row__body">#{body_html}</div>
      </div>
    </article>
    """
  end

  # Ariston-local composite (per ADR 0021 §2). Renders the "Mike : Codex
  # listening" thin presence-strip row shown in the conversation focus area of
  # the document-chat-workspace prototype. The prototype's `.voice-pair` li
  # shows: an operator avatar+name badge (with a state dot via CSS ::after),
  # a colon separator, the agent name, and a status label. We keep the same
  # semantic HTML shape so ariston-ui CSS picks it up correctly.
  #
  # Props:
  #   - participant_a  — operator name (e.g. "Mike")
  #   - participant_b  — agent name (e.g. "Codex")
  #   - state          — one of "listening", "idle", "muted", "active" (maps to
  #                      existing presence_dot tokens via state_css_var/1)
  #   - accent_variant — optional; drives a subtle accent token on the row
  #                      (e.g. "pascal", "codex", "gemini", "mike")
  #
  # HTML mirrors `lib/ash_ui/rendering/live_ui_adapter.ex` — both paths must
  # produce the same structure so ariston-ui CSS works on either render path.
  defp generate_heex(%{"type" => "voice_pair_presence"} = iur, _opts) do
    props = iur["props"] || %{}
    participant_a = to_string(prop(props, "participant_a") || "")
    participant_b = to_string(prop(props, "participant_b") || "")
    state = to_string(prop(props, "state") || "idle")
    accent_variant = prop(props, "accent_variant")

    # Derive the single initial for the operator avatar badge.
    initial_a =
      case String.trim(participant_a) do
        "" -> "?"
        name -> name |> String.upcase() |> String.at(0) || "?"
      end

    # Presence dot on the operator badge: drives background-color via token.
    dot_style = state_css_var(state)

    # Optional accent variant drives a data attribute used for CSS theming.
    accent_attr =
      if accent_variant && accent_variant != "",
        do: " data-accent=\"#{accent_variant}\"",
        else: ""

    """
    <li class="#{css_classes(["voice-pair-presence", prop_class(iur)])}" data-state="#{state}"#{accent_attr}>
      <span class="voice-pair-presence__operator">
        <span class="voice-pair-presence__avatar ash-avatar ash-avatar-small" style="background-color: var(--avatar-#{if accent_variant && accent_variant != "", do: accent_variant, else: "neutral"}, var(--bg-2));" data-variant="#{if accent_variant && accent_variant != "", do: accent_variant, else: "neutral"}" aria-hidden="true">
          <span aria-hidden="true">#{initial_a}</span>
        </span>
        <span class="voice-pair-presence__dot ash-presence-dot ash-presence-dot-small" data-state="#{state}" style="#{dot_style}" aria-hidden="true"></span>
        <b class="voice-pair-presence__name-a">#{participant_a}</b>
      </span>
      <span class="voice-pair-presence__sep" aria-hidden="true">:</span>
      <b class="voice-pair-presence__name-b">#{participant_b}</b>
      <span class="voice-pair-presence__status">#{state}</span>
    </li>
    """
  end

  # Track-B widgets bundled from PRs #79-#97.

  defp generate_heex(%{"type" => "inline_rich_text_heading"} = iur, _opts) do
    props = iur["props"] || %{}
    level = normalize_heading_level(prop(props, "level", "h1"))
    segments = normalize_segments(prop(props, "segments", []))

    inner =
      segments
      |> Enum.map_join("", &render_segment/1)

    """
    <#{level} class="#{css_classes(["ash-inline-rich-text-heading", "ash-inline-rich-text-heading-#{level}", prop_class(iur)])}"#{style_attr(prop_style(iur))}>#{inner}</#{level}>
    """
  end

  defp generate_heex(%{"type" => "disclosure"} = iur, opts) do
    props = iur["props"] || %{}
    summary = text_prop(props, ["summary", "label", "title"], "")
    open? = truthy_disclosure_prop(prop(props, "open", false))
    open_attr = if open?, do: " open", else: ""

    """
    <details class="#{css_classes(["ash-disclosure", prop_class(iur)])}"#{open_attr}#{style_attr(prop_style(iur))}>
      <summary class="ash-disclosure-summary">#{summary}</summary>
      <div class="ash-disclosure-body">
        #{generate_children(iur["children"], opts)}
      </div>
    </details>
    """
  end

  defp generate_heex(%{"type" => "phoenix_form"} = iur, opts) do
    props = iur["props"] || %{}
    submit_event = text_prop(props, ["submit_event"], "submit")
    change_event = text_prop(props, ["change_event"], "validate")
    submit_label = text_prop(props, ["submit_label"], "Submit")
    submit_variant = text_prop(props, ["submit_variant"], "primary")
    fields = Map.get(props, "fields") || Map.get(props, :fields) || []

    fields_heex =
      fields
      |> Enum.map(&render_phoenix_form_field/1)
      |> Enum.join("\n")

    submit_class =
      css_classes(["ash-phoenix-form-submit", "ash-phoenix-form-submit-#{submit_variant}"])

    """
    <form class="#{css_classes(["ash-phoenix-form", prop_class(iur)])}"#{style_attr(prop_style(iur))} phx-submit="#{submit_event}" phx-change="#{change_event}">
      #{fields_heex}
      <button type="submit" class="#{submit_class}">#{submit_label}</button>
      #{generate_children(iur["children"], opts)}
    </form>
    """
  end

  defp generate_heex(%{"type" => "kicker"} = iur, _opts) do
    props = iur["props"] || %{}
    items = prop(props, "items", [])
    separator = prop(props, "separator", "·")

    items_html =
      items
      |> Enum.with_index()
      |> Enum.map_join("", fn {item, index} ->
        sep_html =
          if index > 0 and separator != "" do
            "<li class=\"ash-kicker-separator\" aria-hidden=\"true\">#{separator}</li>"
          else
            ""
          end

        "#{sep_html}<li class=\"ash-kicker-item\">#{item}</li>"
      end)

    """
    <ul class="#{css_classes(["ash-kicker", prop_class(iur)])}"#{style_attr(prop_style(iur))}>#{items_html}</ul>
    """
  end

  defp generate_heex(%{"type" => "avatar"} = iur, _opts) do
    props = iur["props"] || %{}
    initials = prop(props, "initials")
    image_src = prop(props, "image_src")
    variant = prop(props, "variant", "neutral")
    size = prop(props, "size", "medium")
    shape = prop(props, "shape", "round")
    aria_label = prop(props, "aria_label")

    shape_class = if shape == "square", do: "ash-avatar-square", else: ""

    size_class =
      case size do
        "small" -> "ash-avatar-small"
        "large" -> "ash-avatar-large"
        _ -> "ash-avatar-medium"
      end

    role_attr = if aria_label, do: " role=\"img\"", else: ""
    aria_attr = if aria_label, do: " aria-label=\"#{aria_label}\"", else: ""

    inner =
      if image_src do
        alt = aria_label || initials || ""
        "<img src=\"#{image_src}\" class=\"ash-avatar-image\" alt=\"#{alt}\" />"
      else
        "<span aria-hidden=\"true\">#{initials}</span>"
      end

    """
    <span class="#{css_classes(["ash-avatar", shape_class, size_class, prop_class(iur)])}" style="background-color: var(--avatar-#{variant}, var(--bg-2));" data-variant="#{variant}"#{role_attr}#{aria_attr}>#{inner}</span>
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

  defp generate_heex(%{"type" => "segmented_button_group"} = iur, _opts) do
    props = iur["props"] || %{}
    options = prop(props, "options", [])
    active = prop(props, "active")
    event = prop(props, "event", "select_segment")
    event_value_key = prop(props, "event_value_key", "value")
    aria_label = prop(props, "aria_label", "")

    options_html =
      Enum.map_join(options, fn option ->
        option = normalize_item(option)
        value = text_prop(option, "value", "")
        label = text_prop(option, "label", "")
        pressed = if value == to_string(active || ""), do: "true", else: "false"
        value_attr = " phx-value-#{event_value_key}=\"#{value}\""

        "<button type=\"button\" class=\"ash-segmented-button-group-option\" aria-pressed=\"#{pressed}\" phx-click=\"#{event}\"#{value_attr}>#{label}</button>"
      end)

    """
    <div role="group" class="#{css_classes(["ash-segmented-button-group", prop_class(iur)])}"#{style_attr(prop_style(iur))} aria-label="#{aria_label}">
      #{options_html}
    </div>
    """
  end

  defp generate_heex(%{"type" => "list_item_multi_column"} = iur, opts) do
    props = iur["props"] || %{}
    columns = prop(props, "columns", "1fr")
    row_id = prop(props, "row_id")
    event = prop(props, "event", "select_row")
    event_value_key = prop(props, "event_value_key", "row_id")
    active = prop(props, "active", false)
    href = prop(props, "href")
    extra_class = prop(props, "class", "")
    css = css_classes(["ash-list-item-multi-column", extra_class])
    grid_style = merge_style("grid-template-columns: #{columns}", prop_style(iur))

    if href do
      """
      <a class="#{css}"#{style_attr(grid_style)} href="#{href}" data-active="#{active}">
        #{generate_children(iur["children"], opts)}
      </a>
      """
    else
      phx_value = if row_id, do: " phx-value-#{event_value_key}=\"#{row_id}\"", else: ""

      """
      <button class="#{css}"#{style_attr(grid_style)} data-active="#{active}" phx-click="#{event}"#{phx_value}>
        #{generate_children(iur["children"], opts)}
      </button>
      """
    end
  end

  defp generate_heex(%{"type" => "artifact_row"} = iur, opts) do
    props = iur["props"] || %{}
    title = Map.get(props, "title", "")
    meta = Map.get(props, "meta", "")
    row_id = Map.get(props, "row_id")
    event = Map.get(props, "event", "select_artifact")
    event_value_key = Map.get(props, "event_value_key", "row_id")
    active = Map.get(props, "active", false)
    href = Map.get(props, "href")
    extra_class = Map.get(props, "class", "")
    css = css_classes(["ash-artifact-row", extra_class])

    meta_html =
      if meta != "", do: "<span class=\"ash-artifact-row-meta\">#{meta}</span>", else: ""

    trailing_html = generate_children(iur["children"] || [], opts)

    trailing_wrapper =
      if trailing_html != "",
        do: "<div class=\"ash-artifact-row-trailing\">#{trailing_html}</div>",
        else: ""

    if href do
      """
      <a class="#{css}"#{style_attr(prop_style(iur))} href="#{href}" data-active="#{active}">
        <div class="ash-artifact-row-content">
          <span class="ash-artifact-row-title">#{title}</span>
          #{meta_html}
        </div>
        #{trailing_wrapper}
      </a>
      """
    else
      phx_value = if row_id, do: " phx-value-#{event_value_key}=\"#{row_id}\"", else: ""

      """
      <button class="#{css}"#{style_attr(prop_style(iur))} data-active="#{active}" phx-click="#{event}"#{phx_value}>
        <div class="ash-artifact-row-content">
          <span class="ash-artifact-row-title">#{title}</span>
          #{meta_html}
        </div>
        #{trailing_wrapper}
      </button>
      """
    end
  end

  defp generate_heex(%{"type" => "sticky_frosted_header"} = iur, opts) do
    props = iur["props"] || %{}
    height = prop(props, "height", 64)
    extra_class = prop(props, "class", "")
    css = css_classes(["ash-sticky-frosted-header", extra_class])
    children = iur["children"] || []
    leading = Enum.at(children, 0)
    title = Enum.at(children, 1)
    trailing = Enum.at(children, 2)

    """
    <header class="#{css}"#{style_attr(merge_style(["height: #{height}px"], prop_style(iur)))}>
      <div class="ash-sticky-frosted-header-leading">
        #{if leading, do: generate_heex(leading, opts), else: ""}
      </div>
      <div class="ash-sticky-frosted-header-title">
        #{if title, do: generate_heex(title, opts), else: ""}
      </div>
      <div class="ash-sticky-frosted-header-trailing">
        #{if trailing, do: generate_heex(trailing, opts), else: ""}
      </div>
    </header>
    """
  end

  defp generate_heex(%{"type" => "pipeline_stepper_horizontal"} = iur, _opts) do
    props = iur["props"] || %{}
    steps = Map.get(props, "steps", [])
    active_index = Map.get(props, "active_index", 0)
    event = Map.get(props, "event", "select_step")
    event_value_key = Map.get(props, "event_value_key", "step_index")

    steps_html =
      steps
      |> Enum.with_index()
      |> Enum.map_join(fn {step, pos} ->
        step = if is_map(step), do: step, else: %{}
        label = Map.get(step, "label", Map.get(step, :label, ""))
        step_index = Map.get(step, "index", Map.get(step, :index, pos))
        state = step_state(pos, active_index)

        connector_html =
          if pos > 0 do
            done_val = if pos <= active_index, do: "true", else: "false"

            ~s(<div class="ash-pipeline-stepper-horizontal-connector" data-done="#{done_val}" aria-hidden="true"></div>)
          else
            ""
          end

        value_attr =
          if event_value_key == "step_index" do
            ""
          else
            ~s( phx-value-#{event_value_key}="#{step_index}")
          end

        connector_html <>
          ~s(<button type="button" class="ash-pipeline-stepper-horizontal-step" data-state="#{state}" phx-click="#{event}" phx-value-step_index="#{step_index}"#{value_attr}>
      <div class="ash-pipeline-stepper-horizontal-marker" aria-hidden="true"></div>
      <span class="ash-pipeline-stepper-horizontal-label">#{label}</span>
    </button>)
      end)

    """
    <div class="#{css_classes(["ash-pipeline-stepper-horizontal", prop_class(iur)])}"#{style_attr(prop_style(iur))} role="list">
      #{steps_html}
    </div>
    """
  end

  defp generate_heex(%{"type" => "segmented_progress_bar"} = iur, _opts) do
    props = iur["props"] || %{}
    segments = Map.get(props, "segments", [])
    label = Map.get(props, "label")
    aria_label = label || "Progress"
    completed_pct = compute_completed_pct(segments)

    label_html =
      if label do
        ~s(<span class="ash-segmented-progress-bar-label">#{label}</span>)
      else
        ""
      end

    segments_html =
      Enum.map_join(segments, fn segment ->
        segment = if is_map(segment), do: segment, else: %{}
        state = Map.get(segment, "state", Map.get(segment, :state, "future"))
        state_str = if is_atom(state), do: Atom.to_string(state), else: to_string(state)
        weight = Map.get(segment, "weight", Map.get(segment, :weight, 1))
        weight = if is_number(weight) and weight > 0, do: weight, else: 1
        seg_label = Map.get(segment, "label", Map.get(segment, :label))

        label_attrs =
          if seg_label do
            ~s( aria-label="#{seg_label}" title="#{seg_label}")
          else
            ""
          end

        ~s(<div class="ash-segmented-progress-bar-segment" data-state="#{state_str}" style="flex: #{weight}"#{label_attrs}></div>)
      end)

    """
    <div class="#{css_classes(["ash-segmented-progress-bar", prop_class(iur)])}"#{style_attr(prop_style(iur))} role="progressbar" aria-label="#{aria_label}" aria-valuenow="#{completed_pct}" aria-valuemin="0" aria-valuemax="100">
      #{label_html}
      <div class="ash-segmented-progress-bar-track">
        #{segments_html}
      </div>
    </div>
    """
  end

  defp generate_heex(%{"type" => "workflow_stage_list_vertical"} = iur, _opts) do
    props = iur["props"] || %{}
    stages = Map.get(props, "stages", [])
    active_index = Map.get(props, "active_index", 0)

    indexed = Enum.with_index(stages)

    items_html =
      Enum.map_join(indexed, fn {stage, pos} ->
        label =
          if is_map(stage),
            do: Map.get(stage, "label") || Map.get(stage, :label, ""),
            else: to_string(stage)

        node_index =
          if is_map(stage),
            do: Map.get(stage, "index") || Map.get(stage, :index) || pos + 1,
            else: pos + 1

        state =
          cond do
            pos < active_index -> "done"
            pos == active_index -> "active"
            true -> "pending"
          end

        connector =
          if pos > 0 do
            done = if pos <= active_index, do: "true", else: "false"

            "<div class=\"ash-workflow-stage-list-vertical-connector\" data-done=\"#{done}\" aria-hidden=\"true\"></div>"
          else
            ""
          end

        aria_current = if state == "active", do: " aria-current=\"step\"", else: ""

        "#{connector}<li class=\"ash-workflow-stage-list-vertical-item\" data-state=\"#{state}\"#{aria_current}><div class=\"ash-workflow-stage-list-vertical-node\" aria-hidden=\"true\">#{node_index}</div><span class=\"ash-workflow-stage-list-vertical-label\">#{label}</span></li>"
      end)

    """
    <ol class="#{css_classes(["ash-workflow-stage-list-vertical", prop_class(iur)])}" aria-label="Workflow stages"#{style_attr(prop_style(iur))}>
      #{items_html}
    </ol>
    """
  end

  defp generate_heex(%{"type" => "meter_thin"} = iur, _opts) do
    props = iur["props"] || %{}
    raw_value = Map.get(props, "value", Map.get(props, "percent", 0))
    max_val = max(prop(props, "max", 100) || 100, 1)
    label = text_prop(props, ["label", "text"])

    pct =
      cond do
        is_float(raw_value) and raw_value >= 0.0 and raw_value < 1.0 ->
          raw_value * 100

        is_integer(raw_value) ->
          raw_value / max_val * 100

        is_float(raw_value) ->
          raw_value / max_val * 100

        true ->
          0.0
      end

    pct = max(0.0, min(100.0, pct))
    pct_str = if pct == trunc(pct), do: "#{trunc(pct)}", else: "#{Float.round(pct, 1)}"

    label_html =
      if label,
        do: "<span class=\"ash-meter-thin-label\">#{label}</span>",
        else: ""

    """
    <div class="#{css_classes(["ash-meter-thin", prop_class(iur)])}" role="progressbar" aria-valuenow="#{pct_str}" aria-valuemin="0" aria-valuemax="100"#{style_attr(prop_style(iur))}>
      #{label_html}
      <div class="ash-meter-thin-track">
        <div class="ash-meter-thin-fill" style="width: #{pct_str}%"></div>
      </div>
    </div>
    """
  end

  defp generate_heex(%{"type" => "slide_over_panel"} = iur, opts) do
    props = iur["props"] || %{}
    open? = prop(props, "open", false) == true
    width = text_prop(props, ["width"], "32rem")
    aria_label = text_prop(props, ["aria_label", "aria-label", "label"], "Side panel")

    style =
      merge_style(["width: #{width}"], prop_style(iur))

    """
    <aside class="#{css_classes(["ash-slide-over-panel", prop_class(iur)])}" data-open="#{open?}" role="complementary" aria-label="#{aria_label}"#{style_attr(style)}>
      #{generate_children(iur["children"], opts)}
    </aside>
    """
  end

  defp generate_heex(%{"type" => "event_callout"} = iur, opts) do
    props = iur["props"] || %{}
    tone = prop(props, "tone", "info")
    kicker = text_prop(props, "kicker")
    body_text = text_prop(props, ["text", "content", "body"])
    action_children = iur["children"] || []

    """
    <section class="#{css_classes(["ash-event-callout", prop_class(iur)])}"#{style_attr(prop_style(iur))} data-tone="#{tone}">
      <div class="ash-event-callout-content">
        #{if kicker, do: "<span class=\"ash-event-callout-kicker\">#{kicker}</span>", else: ""}
        <div class="ash-event-callout-body">
          #{if body_text, do: body_text, else: generate_children(action_children, opts)}
        </div>
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "redline_inline"} = iur, _opts) do
    props = iur["props"] || %{}
    state = prop(props, "state", "proposed")
    segments = prop(props, "segments") || []

    segments_html =
      Enum.map_join(segments, fn segment ->
        type = Map.get(segment, "type") || Map.get(segment, :type, "keep")
        content = Map.get(segment, "content") || Map.get(segment, :content, "")
        escaped = escape_html(content)

        case {to_string(type), state} do
          {"del", "accepted"} -> ""
          {"ins", "rejected"} -> ""
          {"del", _} -> "<del>#{escaped}</del>"
          {"ins", _} -> "<ins>#{escaped}</ins>"
          _ -> escaped
        end
      end)

    """
    <span class="#{css_classes(["ash-redline-inline", prop_class(iur)])}"#{style_attr(prop_style(iur))} data-state="#{state}">#{segments_html}</span>
    """
  end

  defp generate_heex(%{"type" => "code_block_syntax_highlighted"} = iur, _opts) do
    props = iur["props"] || %{}
    language = Map.get(props, "language") || Map.get(props, :language)
    tokens = Map.get(props, "tokens") || Map.get(props, :tokens) || []

    lang_attr =
      if language && language != "", do: " data-language=\"#{escape_html(language)}\"", else: ""

    tokens_html =
      Enum.map_join(tokens, fn token ->
        type = Map.get(token, "type") || Map.get(token, :type, "text")
        content = Map.get(token, "content") || Map.get(token, :content, "")
        escaped = escape_html(content)
        "<span data-token=\"#{type}\">#{escaped}</span>"
      end)

    class = css_classes(["ash-code-block-syntax-highlighted", prop_class(iur)])

    """
    <pre class="#{class}"#{lang_attr}#{style_attr(prop_style(iur))}><code>#{tokens_html}</code></pre>
    """
  end

  defp generate_heex(%{"type" => "chat_composer"} = iur, opts) do
    props = iur["props"] || %{}
    name = Map.get(props, "name") || Map.get(props, :name, "message")
    value = Map.get(props, "value") || Map.get(props, :value, "")
    placeholder = Map.get(props, "placeholder") || Map.get(props, :placeholder, "Type a message")
    rows = Map.get(props, "rows") || Map.get(props, :rows, 3)
    disabled = Map.get(props, "disabled") || Map.get(props, :disabled, false)
    send_event = Map.get(props, "send_event") || Map.get(props, :send_event, "send_message")

    change_event =
      Map.get(props, "change_event") || Map.get(props, :change_event, "change_message")

    disabled_attr = if disabled, do: " disabled", else: ""
    children_html = generate_children(iur["children"], opts)

    class = css_classes(["ash-chat-composer", prop_class(iur)])

    """
    <div class="#{class}"#{style_attr(prop_style(iur))}>
      <form class="ash-chat-composer-form" phx-change="#{change_event}">
        <textarea class="ash-chat-composer-textarea" name="#{name}" rows="#{rows}" placeholder="#{placeholder}"#{disabled_attr}>#{value}</textarea>
        <div class="ash-chat-composer-tool-row">
          <div class="ash-chat-composer-tools-leading">#{children_html}</div>
          <div class="ash-chat-composer-tools-trailing">
            <button type="button" class="ash-chat-composer-send-btn" phx-click="#{send_event}"#{disabled_attr}>Send</button>
          </div>
        </div>
      </form>
    </div>
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

  # Track-B widget helpers bundled from PRs #79-#97.

  @valid_heading_levels ~w(h1 h2 h3 h4 h5 h6)

  defp normalize_heading_level(value) when is_atom(value),
    do: normalize_heading_level(Atom.to_string(value))

  defp normalize_heading_level(value) when is_binary(value) do
    downcased = String.downcase(value)
    if downcased in @valid_heading_levels, do: downcased, else: "h1"
  end

  defp normalize_heading_level(_), do: "h1"

  defp normalize_segments(segments) when is_list(segments) do
    Enum.flat_map(segments, &normalize_segment/1)
  end

  defp normalize_segments(_), do: []

  defp normalize_segment(%{"type" => type, "value" => value})
       when is_binary(value) and type in ["text", "em"],
       do: [%{type: type, value: value}]

  defp normalize_segment(%{type: type, value: value})
       when is_binary(value) and type in [:text, :em],
       do: [%{type: Atom.to_string(type), value: value}]

  defp normalize_segment({:em, value}) when is_binary(value), do: [%{type: "em", value: value}]

  defp normalize_segment({:text, value}) when is_binary(value),
    do: [%{type: "text", value: value}]

  defp normalize_segment(_), do: []

  defp render_segment(%{type: "em", value: value}), do: "<em>#{value}</em>"
  defp render_segment(%{type: "text", value: value}), do: value

  defp truthy_disclosure_prop(value)
       when value in [true, "true", "open", "visible", 1, "1", "yes"],
       do: true

  defp truthy_disclosure_prop(_), do: false

  defp render_phoenix_form_field(field) when is_map(field) do
    name = phoenix_form_field_value(field, "name", "")
    type = phoenix_form_field_value(field, "type", "text")
    label = phoenix_form_field_value(field, "label", nil)
    placeholder = phoenix_form_field_value(field, "placeholder", "")
    autocomplete = phoenix_form_field_value(field, "autocomplete", nil)
    value = phoenix_form_field_value(field, "value", "")
    required? = !!phoenix_form_field_value(field, "required", false)
    required_attr = if required?, do: " required", else: ""

    label_heex =
      if is_binary(label) and label != "" do
        ~s(<label for="#{name}" class="ash-phoenix-form-label">#{label}</label>)
      else
        ""
      end

    """
    <div class="ash-phoenix-form-field">
      #{label_heex}
      <input id="#{name}" name="#{name}" type="#{type}" class="ash-phoenix-form-input" value="#{value}" placeholder="#{placeholder}"#{attr("autocomplete", autocomplete)}#{required_attr} />
    </div>
    """
  end

  defp render_phoenix_form_field(_), do: ""

  defp phoenix_form_field_value(field, key, default) when is_map(field) do
    Map.get(field, key, Map.get(field, String.to_atom(key), default))
  rescue
    ArgumentError -> Map.get(field, key, default)
  end

  defp state_css_var("live"), do: "background-color: var(--presence-live, var(--accent));"
  defp state_css_var("idle"), do: "background-color: var(--presence-idle, var(--ink-faint));"

  defp state_css_var("warn"),
    do: "background-color: var(--presence-warn, var(--warn, var(--accent-strong)));"

  defp state_css_var("muted"), do: "background-color: var(--presence-muted, var(--rule));"
  defp state_css_var("quiet"), do: "background-color: var(--presence-quiet, var(--rule-faint));"
  defp state_css_var(other), do: "background-color: var(--presence-#{other}, var(--ink-faint));"

  defp step_state(pos, active_index) when pos < active_index, do: "done"
  defp step_state(pos, active_index) when pos == active_index, do: "active"
  defp step_state(_pos, _active_index), do: "pending"

  defp compute_completed_pct([]), do: 0

  defp compute_completed_pct(segments) do
    get_weight = fn seg ->
      w = Map.get(seg, "weight", Map.get(seg, :weight, 1))
      if is_number(w) and w > 0, do: w, else: 1
    end

    total = Enum.reduce(segments, 0, fn seg, acc -> acc + get_weight.(seg) end)

    completed =
      segments
      |> Enum.filter(fn seg ->
        s = Map.get(seg, "state", Map.get(seg, :state))
        s == :completed or s == "completed"
      end)
      |> Enum.reduce(0, fn seg, acc -> acc + get_weight.(seg) end)

    if total > 0, do: round(completed / total * 100), else: 0
  end

  # Minimal HTML escaping for redline_inline and code_block_syntax_highlighted.
  defp escape_html(nil), do: ""

  defp escape_html(content) when is_binary(content) do
    content
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp escape_html(content), do: escape_html(to_string(content))
end
