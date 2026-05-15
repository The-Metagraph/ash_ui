defmodule AshUI.Rendering.LiveUIAdapter do
  @moduledoc """
  Adapter for LiveUI renderer package.

  This module provides integration with the live_ui package for rendering
  to Phoenix LiveView HEEx templates. When the live_ui package is not
  available, this module provides stub implementations.

  ## LiveView-Specific Features

  This adapter supports:
  - Event bindings (phx-click, phx-blur, phx-change)
  - LiveView hooks attachment
  - Reactive assigns for data binding
  - Patch optimizations for efficient updates

  If LiveUI.Renderer is available, delegates to it. Otherwise, provides
  fallback implementation using the IURAdapter.
  """

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Telemetry

  @doc """
  Renders a canonical IUR to HEEx template string.

  ## Parameters
    * `canonical_iur` - Canonical IUR map from IURAdapter
    * `opts` - Rendering options

  ## Options
    * `:optimize_patches` - Enable LiveView patch optimizations (default: true)
    * `:assigns` - LiveView assigns for reactivity (default: %{})
    * `:socket` - LiveView socket for event binding (default: nil)
    * `:hooks` - LiveView hooks to attach (default: [])
    *: `:event_prefix` - Prefix for event names (default: "ash_ui")

  ## Returns
    * `{:ok, heex_string}` - HEEx template string
    * `{:error, reason}` - Rendering failed
  """
  @spec render(map(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render(canonical_iur, opts \\ []) when is_map(canonical_iur) do
    started_at = System.monotonic_time()
    metadata = render_metadata(canonical_iur, :live_ui)
    Telemetry.emit(:render, :start, %{count: 1}, metadata)
    force_fallback? = Keyword.get(opts, :force_fallback, false)

    result =
      if Code.ensure_loaded?(LiveUI.Renderer) and not force_fallback? do
        call_live_ui_renderer(canonical_iur, opts)
      else
        render_fallback(canonical_iur, opts)
      end

    emit_render_telemetry(result, started_at, metadata)
  end

  @doc """
  Checks if LiveUI renderer is available.

  ## Returns
    * `true` - LiveUI.Renderer is available
    * `false` - LiveUI.Renderer is not available
  """
  @spec available?() :: boolean()
  def available? do
    Code.ensure_loaded?(live_ui_renderer_module())
  end

  @doc """
  Converts an Ash IUR to LiveUI-compatible format and renders.

  ## Parameters
    * `ash_iur` - Ash IUR structure
    * `opts` - Rendering options

  ## Returns
    * `{:ok, heex_string}` - HEEx template string
    * `{:error, reason}` - Rendering failed
  """
  @spec render_ash_iur(IUR.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render_ash_iur(%IUR{} = ash_iur, opts \\ []) do
    with {:ok, canonical_iur} <- IURAdapter.to_canonical(ash_iur, opts),
         {:ok, heex} <- render(canonical_iur, opts) do
      {:ok, heex}
    else
      error -> error
    end
  end

  @doc """
  Configures LiveView event bindings for a screen.

  ## Parameters
    * `canonical_iur` - Canonical IUR map
    * `opts` - Options

  ## Returns
    * Event binding configuration map
  """
  @spec configure_event_bindings(map(), keyword()) :: map()
  def configure_event_bindings(%{"type" => "screen"} = iur, opts \\ []) do
    event_prefix = Keyword.get(opts, :event_prefix, "ash_ui")

    bindings = extract_event_bindings(iur, event_prefix)

    %{
      events: bindings,
      handlers: build_event_handlers(bindings),
      event_prefix: event_prefix
    }
  end

  @doc """
  Configures LiveView hooks for a screen.

  ## Parameters
    * `canonical_iur` - Canonical IUR map
    * `opts` - Options

  ## Returns
    * Hook configuration list
  """
  @spec configure_hooks(map(), keyword()) :: [map()]
  def configure_hooks(%{"type" => "screen"} = _iur, opts \\ []) do
    custom_hooks = Keyword.get(opts, :hooks, [])
    optimize_patches = Keyword.get(opts, :optimize_patches, true)

    default_hooks = [
      %{
        name: :ash_ui_lifecycle,
        on_mount: {AshUI.LiveView.Hooks, :on_mount_ash_ui}
      }
    ]

    patch_hooks =
      if optimize_patches do
        [
          %{
            name: :ash_ui_patches,
            on_mount: {AshUI.LiveView.PatchOptimizer, :on_mount_optimize}
          }
        ]
      else
        []
      end

    default_hooks ++ patch_hooks ++ custom_hooks
  end

  @doc """
  Configures LiveView assigns for reactive data binding.

  ## Parameters
    * `canonical_iur` - Canonical IUR map
    * `opts` - Options

  ## Returns
    * Assigns configuration map
  """
  @spec configure_assigns(map(), keyword()) :: map()
  def configure_assigns(%{"type" => "screen"} = iur, opts \\ []) do
    initial_assigns = Keyword.get(opts, :assigns, %{})
    bindings = Map.get(iur, "bindings", [])

    # Extract assigns from bidirectional bindings
    binding_assigns =
      bindings
      |> Enum.filter(fn binding ->
        Map.get(binding, "type") in ["bidirectional", "collection"]
      end)
      |> Enum.map(fn binding ->
        target = Map.get(binding, "target")
        source = Map.get(binding, "source", %{})
        {target, extract_default_value(source)}
      end)
      |> Map.new()

    Map.merge(initial_assigns, binding_assigns)
  end

  @doc """
  Configures LiveView patch optimizations.

  ## Parameters
    * `canonical_iur` - Canonical IUR map
    * `opts` - Options

  ## Returns
    * Patch optimization configuration
  """
  @spec configure_patch_optimization(map(), keyword()) :: map()
  def configure_patch_optimization(%{"type" => "screen"} = iur, opts \\ []) do
    enabled = Keyword.get(opts, :optimize_patches, true)
    static_elements = extract_static_elements(iur)

    %{
      enabled: enabled,
      static_ids: static_elements,
      dynamic_streams: extract_dynamic_streams(iur)
    }
  end

  # Private Functions

  defp live_ui_renderer_module do
    Module.concat(LiveUI, Renderer)
  end

  # Call actual LiveUI.Renderer if available
  defp call_live_ui_renderer(canonical_iur, opts) do
    renderer_module = live_ui_renderer_module()

    try do
      case renderer_module.render(canonical_iur, opts) do
        {:ok, heex} -> {:ok, heex}
        {:error, reason} -> {:error, {:live_ui_error, reason}}
        other -> {:error, {:unexpected_response, other}}
      end
    rescue
      error -> {:error, {:live_ui_exception, error}}
    end
  end

  # Fallback renderer when LiveUI is not available
  defp render_fallback(canonical_iur, opts) do
    optimize_patches = Keyword.get(opts, :optimize_patches, true)
    event_prefix = Keyword.get(opts, :event_prefix, "ash_ui")

    heex =
      generate_heex(canonical_iur, %{
        optimize_patches: optimize_patches,
        event_prefix: event_prefix,
        bindings: Map.get(canonical_iur, "bindings", [])
      })

    {:ok, heex}
  end

  # Generate HEEx from canonical IUR with options
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

  defp generate_heex(%{"type" => "icon"} = iur, _opts) do
    props = iur["props"] || %{}
    name = text_prop(props, ["name", "icon", "value"], "spark")
    label = text_prop(props, ["label", "text", "content"], name)

    """
    <span class="#{css_classes(["ash-icon", prop_class(iur)])}" role="img" aria-label="#{label}"#{style_attr(prop_style(iur))}>
      <span class="ash-icon-glyph">#{icon_glyph(name)}</span>
      <span class="ash-icon-label">#{label}</span>
    </span>
    """
  end

  defp generate_heex(%{"type" => "image"} = iur, _opts) do
    props = iur["props"] || %{}
    src = text_prop(props, ["src", "url"], "")
    alt = text_prop(props, ["alt", "label", "content"], "Image")
    caption = text_prop(props, ["caption", "description"])

    """
    <figure class="#{css_classes(["ash-image", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <img src="#{src}" alt="#{alt}" loading="lazy" />
      #{if caption, do: "<figcaption class=\"ash-image-caption\">#{caption}</figcaption>", else: ""}
    </figure>
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

  defp generate_heex(%{"type" => "list"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "List")
    description = text_prop(props, ["description", "help"])
    empty_text = text_prop(props, "empty_text", "No items available.")
    items = collection_items(props)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    items_html =
      case items do
        [] ->
          ~s(<li class="ash-list-empty">#{empty_text}</li>)

        collection ->
          Enum.map_join(collection, &render_list_item/1)
      end

    """
    <section class="#{css_classes(["ash-list", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-list-header">
        <h2 class="ash-list-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-list-description\">#{description}</p>", else: ""}
      </header>
      <ul class="ash-list-items">
        #{items_html}
      </ul>
      <div class="ash-list-body">
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-list-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-list-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "table"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Table")
    description = text_prop(props, ["description", "help"])
    empty_text = text_prop(props, "empty_text", "No rows available.")
    columns = table_columns(props)
    rows = collection_items(props)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    header_html = Enum.map_join(columns, &render_table_header/1)

    rows_html =
      case rows do
        [] ->
          """
          <tr class="ash-table-empty-row">
            <td class="ash-table-empty" colspan="#{max(length(columns), 1)}">#{empty_text}</td>
          </tr>
          """

        collection ->
          Enum.map_join(collection, &render_table_row(&1, columns))
      end

    """
    <section class="#{css_classes(["ash-table-surface", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-table-header">
        <h2 class="ash-table-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-table-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-table-wrapper">
        <table class="ash-table">
          <thead>
            <tr>#{header_html}</tr>
          </thead>
          <tbody>
            #{rows_html}
          </tbody>
        </table>
      </div>
      <div class="ash-table-body">
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-table-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-table-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "form_builder"} = iur, opts) do
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "event")

    submit_attrs =
      if binding do
        ~s( phx-submit="#{event_name(event_prefix, :action)}"#{attr("phx-value-action_id", binding["id"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", binding_signal(binding, "submit"))})
      else
        ""
      end

    """
    <form class="#{css_classes(["ash-form-builder", prop_class(iur)])}"#{style_attr(prop_style(iur))}#{submit_attrs}>
      #{generate_children(iur["children"], opts)}
    </form>
    """
  end

  defp generate_heex(%{"type" => "form_field"} = iur, opts) do
    props = iur["props"] || %{}
    label = text_prop(props, ["label", "title"])
    help = text_prop(props, ["help", "description"])

    """
    <div class="#{css_classes(["ash-form-field", prop_class(iur)])}"#{attr("data-field-name", dom_id(prop(props, "name")))}#{style_attr(prop_style(iur))}>
      #{if label, do: "<label class=\"ash-form-field-label\">#{label}</label>", else: ""}
      #{generate_children(iur["children"], opts)}
      #{if help, do: "<p class=\"ash-form-field-help\">#{help}</p>", else: ""}
    </div>
    """
  end

  defp generate_heex(%{"type" => "button"} = iur, opts) do
    label = Map.get(iur["props"] || %{}, "label", "Button")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    variant = Map.get(iur["props"] || %{}, "variant", "primary")
    button_type = Map.get(iur["props"] || %{}, "type", "button")
    disabled? = !!Map.get(iur["props"] || %{}, "disabled")
    binding = find_binding(opts, iur["id"], "event")

    class_name =
      css_classes([
        "ash-button",
        "ash-button-#{variant}",
        disabled? && "is-disabled",
        prop_class(iur)
      ])

    event_attrs =
      if binding && button_type != "submit" do
        click_event = event_name(event_prefix, :action)
        action_attr = attr("phx-value-action_id", binding["id"])
        element_attr = attr("phx-value-element_id", iur["id"])
        signal_attr = attr("phx-value-signal", binding_signal(binding, "click"))
        ~s( phx-click="#{click_event}"#{action_attr}#{element_attr}#{signal_attr})
      else
        ""
      end

    """
    <button type="#{button_type}" class="#{class_name}"#{style_attr(prop_style(iur))}#{if(disabled?, do: " disabled", else: "")}#{event_attrs}>#{label}</button>
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
    checked? = !!Map.get(iur["props"] || %{}, "checked")
    checked = if checked?, do: " checked", else: ""
    binding = find_binding(opts, iur["id"], "bidirectional")
    next_value = if checked?, do: "false", else: "true"

    """
    <input type="checkbox" class="#{css_classes(["ash-checkbox", prop_class(iur)])}" name="#{name}"#{style_attr(prop_style(iur))}#{checked} phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}#{attr("phx-value-value", next_value)} />
    """
  end

  defp generate_heex(%{"type" => "radio"} = iur, opts) do
    props = iur["props"] || %{}
    name = Map.get(props, "name", "radio")
    options = Map.get(props, "options", [])
    selected_value = Map.get(props, "value")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "bidirectional")

    options_html =
      Enum.map_join(options, fn option ->
        {label, option_value} = normalize_choice(option)

        checked =
          if to_string(option_value) == to_string(selected_value), do: " checked", else: ""

        """
        <label class="ash-radio-option">
          <input type="radio" name="#{name}" value="#{option_value}"#{checked} phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}#{attr("phx-value-value", option_value)} />
          <span class="ash-radio-option-label">#{label}</span>
        </label>
        """
      end)

    """
    <fieldset class="#{css_classes(["ash-radio-group", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{options_html}
    </fieldset>
    """
  end

  defp generate_heex(%{"type" => "switch"} = iur, opts) do
    props = iur["props"] || %{}
    checked? = !!Map.get(props, "checked")
    label = text_prop(props, ["label", "text", "content"], "Toggle")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "bidirectional")
    next_value = if checked?, do: "false", else: "true"

    """
    <button type="button" role="switch" aria-checked="#{checked?}" class="#{css_classes(["ash-switch", checked? && "is-on", prop_class(iur)])}"#{style_attr(prop_style(iur))} phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}#{attr("phx-value-value", next_value)}>
      <span class="ash-switch-track"><span class="ash-switch-thumb"></span></span>
      <span class="ash-switch-label">#{label}</span>
    </button>
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
        {label, option_value} = normalize_choice(option)

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

  defp generate_heex(%{"type" => "custom:link"} = iur, _opts) do
    props = iur["props"] || %{}
    href = text_prop(props, ["href", "to", "url"], "#")
    label = text_prop(props, ["label", "text", "content"], href)
    target = text_prop(props, "target")
    rel = text_prop(props, "rel")

    """
    <a class="#{css_classes(["ash-link", prop_class(iur)])}" href="#{href}"#{attr("target", target)}#{attr("rel", rel)}#{style_attr(prop_style(iur))}>#{label}</a>
    """
  end

  defp generate_heex(%{"type" => "custom:pick_list"} = iur, opts) do
    props = iur["props"] || %{}
    options = Map.get(props, "options", [])
    selected_value = Map.get(props, "value")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    binding = find_binding(opts, iur["id"], "bidirectional")

    options_html =
      Enum.map_join(options, fn option ->
        {label, option_value} = normalize_choice(option)
        selected? = to_string(option_value) == to_string(selected_value)

        """
        <button type="button" class="#{css_classes(["ash-pick-list-option", selected? && "is-selected"])}" phx-click="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")}#{attr("phx-value-value", option_value)}>#{label}</button>
        """
      end)

    """
    <div class="#{css_classes(["ash-pick-list", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{options_html}
    </div>
    """
  end

  defp generate_heex(%{"type" => "custom:field_group"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"])
    description = text_prop(props, ["description", "help"])

    """
    <section class="#{css_classes(["ash-field-group", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      #{if title, do: "<header class=\"ash-field-group-header\"><h2 class=\"ash-field-group-title\">#{title}</h2>#{if description, do: "<p class=\"ash-field-group-description\">#{description}</p>", else: ""}</header>", else: ""}
      <div class="ash-field-group-body">
        #{generate_children(iur["children"], opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:menu"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Menu")
    description = text_prop(props, ["description", "help"])
    nav_children = slot_children(iur, "nav")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if nav_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <nav class="#{css_classes(["ash-menu", prop_class(iur)])}" aria-label="#{title}"#{style_attr(prop_style(iur))}>
      <header class="ash-menu-header">
        <h2 class="ash-menu-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-menu-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-menu-nav" role="list">
        #{generate_children(nav_children, opts)}
      </div>
      <div class="ash-menu-body">
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-menu-footer">
        #{generate_children(footer_children, opts)}
      </footer>
    </nav>
    """
  end

  defp generate_heex(%{"type" => "custom:tabs"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Tabs")
    description = text_prop(props, ["description", "help"])
    nav_children = slot_children(iur, "nav")
    panel_children = slot_children(iur, "body")

    panel_children =
      if nav_children == [] and panel_children == [] do
        iur["children"] || []
      else
        panel_children
      end

    """
    <section class="#{css_classes(["ash-tabs", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-tabs-header">
        <h2 class="ash-tabs-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-tabs-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-tabs-nav" role="tablist" aria-label="#{title}">
        #{generate_children(nav_children, opts)}
      </div>
      <div class="ash-tabs-panels">
        #{generate_children(panel_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:command_palette"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Command palette")
    description = text_prop(props, ["description", "help"])
    search_children = slot_children(iur, "search")
    command_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    command_children =
      if search_children == [] and command_children == [] and footer_children == [] do
        iur["children"] || []
      else
        command_children
      end

    """
    <section class="#{css_classes(["ash-command-palette", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-command-palette-header">
        <h2 class="ash-command-palette-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-command-palette-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-command-palette-search">
        #{generate_children(search_children, opts)}
      </div>
      <div class="ash-command-palette-results">
        #{generate_children(command_children, opts)}
      </div>
      <footer class="ash-command-palette-footer">
        #{generate_children(footer_children, opts)}
      </footer>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:viewport"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Viewport")
    description = text_prop(props, ["description", "help"])
    body_children = slot_children(iur, "body")
    aside_children = slot_children(iur, "aside")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and aside_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-viewport", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-viewport-header">
        <h2 class="ash-viewport-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-viewport-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-viewport-frame">
        <div class="ash-viewport-body">
          #{generate_children(body_children, opts)}
        </div>
        <aside class="ash-viewport-aside">
          #{generate_children(aside_children, opts)}
        </aside>
      </div>
      <footer class="ash-viewport-footer">
        #{generate_children(footer_children, opts)}
      </footer>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:scroll_bar"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Scroll bar")
    description = text_prop(props, ["description", "help"])
    thumb_label = text_prop(props, ["thumb_label", "current_position"], "Focused lane")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-scroll-bar", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-scroll-bar-header">
        <h2 class="ash-scroll-bar-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-scroll-bar-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-scroll-bar-frame">
        <div class="ash-scroll-bar-body">
          #{generate_children(body_children, opts)}
        </div>
        <div class="ash-scroll-bar-track" aria-hidden="true">
          <span class="ash-scroll-bar-thumb">#{thumb_label}</span>
        </div>
      </div>
      <footer class="ash-scroll-bar-footer">
        #{generate_children(footer_children, opts)}
      </footer>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:split_pane"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Split pane")
    description = text_prop(props, ["description", "help"])
    primary_children = slot_children(iur, "primary")
    secondary_children = slot_children(iur, "secondary")
    action_children = slot_children(iur, "actions")

    primary_children =
      if primary_children == [] and secondary_children == [] and action_children == [] do
        iur["children"] || []
      else
        primary_children
      end

    """
    <section class="#{css_classes(["ash-split-pane", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-split-pane-header">
        <h2 class="ash-split-pane-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-split-pane-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-split-pane-layout">
        <section class="ash-split-pane-primary">
          #{generate_children(primary_children, opts)}
        </section>
        <section class="ash-split-pane-secondary">
          #{generate_children(secondary_children, opts)}
        </section>
      </div>
      <footer class="ash-split-pane-actions">
        #{generate_children(action_children, opts)}
      </footer>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:canvas"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Canvas")
    description = text_prop(props, ["description", "help"])
    toolbar_children = slot_children(iur, "toolbar")
    body_children = slot_children(iur, "body")
    legend_children = slot_children(iur, "legend")

    body_children =
      if toolbar_children == [] and body_children == [] and legend_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-canvas-surface", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-canvas-header">
        <h2 class="ash-canvas-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-canvas-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-canvas-toolbar">
        #{generate_children(toolbar_children, opts)}
      </div>
      <div class="ash-canvas-board">
        #{generate_children(body_children, opts)}
      </div>
      <aside class="ash-canvas-legend">
        #{generate_children(legend_children, opts)}
      </aside>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:overlay"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Overlay")
    description = text_prop(props, ["description", "help"])
    open? = truthy_prop(props, "open", false)
    body_children = slot_children(iur, "body")
    action_children = slot_children(iur, "actions")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and action_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-overlay-surface", open? && "is-open", !open? && "is-closed", prop_class(iur)])}" data-state="#{if(open?, do: "open", else: "closed")}"#{style_attr(prop_style(iur))}>
      <div class="ash-overlay-panel">
        <header class="ash-overlay-header">
          <h2 class="ash-overlay-title">#{title}</h2>
          #{if description, do: "<p class=\"ash-overlay-description\">#{description}</p>", else: ""}
        </header>
        <div class="ash-overlay-body">
          #{generate_children(body_children, opts)}
        </div>
        <footer class="ash-overlay-actions">
          #{generate_children(action_children, opts)}
        </footer>
        <div class="ash-overlay-footer">
          #{generate_children(footer_children, opts)}
        </div>
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:dialog"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Dialog")
    description = text_prop(props, ["description", "help"])
    open? = truthy_prop(props, "open", true)
    body_children = slot_children(iur, "body")
    action_children = slot_children(iur, "actions")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and action_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-dialog-surface", open? && "is-open", !open? && "is-closed", prop_class(iur)])}" data-state="#{if(open?, do: "open", else: "closed")}"#{style_attr(prop_style(iur))}>
      <div class="ash-dialog-panel">
        <header class="ash-dialog-header">
          <h2 class="ash-dialog-title">#{title}</h2>
          #{if description, do: "<p class=\"ash-dialog-description\">#{description}</p>", else: ""}
        </header>
        <div class="ash-dialog-body">
          #{generate_children(body_children, opts)}
        </div>
        <footer class="ash-dialog-actions">
          #{generate_children(action_children, opts)}
        </footer>
        <div class="ash-dialog-footer">
          #{generate_children(footer_children, opts)}
        </div>
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:alert_dialog"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Alert dialog")
    description = text_prop(props, ["description", "help"])
    open? = truthy_prop(props, "open", true)
    body_children = slot_children(iur, "body")
    action_children = slot_children(iur, "actions")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and action_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-alert-dialog-surface", open? && "is-open", !open? && "is-closed", prop_class(iur)])}" data-state="#{if(open?, do: "open", else: "closed")}"#{style_attr(prop_style(iur))}>
      <div class="ash-alert-dialog-panel">
        <header class="ash-alert-dialog-header">
          <h2 class="ash-alert-dialog-title">#{title}</h2>
          #{if description, do: "<p class=\"ash-alert-dialog-description\">#{description}</p>", else: ""}
        </header>
        <div class="ash-alert-dialog-body">
          #{generate_children(body_children, opts)}
        </div>
        <footer class="ash-alert-dialog-actions">
          #{generate_children(action_children, opts)}
        </footer>
        <div class="ash-alert-dialog-footer">
          #{generate_children(footer_children, opts)}
        </div>
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:context_menu"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Context menu")
    description = text_prop(props, ["description", "help"])
    open? = truthy_prop(props, "open", true)
    menu_children = slot_children(iur, "menu")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if menu_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-context-menu", open? && "is-open", !open? && "is-closed", prop_class(iur)])}" data-state="#{if(open?, do: "open", else: "closed")}"#{style_attr(prop_style(iur))}>
      <header class="ash-context-menu-header">
        <h2 class="ash-context-menu-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-context-menu-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-context-menu-items" role="menu">
        #{generate_children(menu_children, opts)}
      </div>
      <div class="ash-context-menu-body">
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-context-menu-footer">
        #{generate_children(footer_children, opts)}
      </footer>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:toast"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Toast")
    description = text_prop(props, ["description", "help"])
    visible? = truthy_prop(props, "visible", true)
    body_children = slot_children(iur, "body")
    action_children = slot_children(iur, "actions")
    footer_children = slot_children(iur, "footer")

    body_children =
      if body_children == [] and action_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-toast", visible? && "is-visible", !visible? && "is-hidden", prop_class(iur)])}" data-state="#{if(visible?, do: "visible", else: "hidden")}"#{style_attr(prop_style(iur))}>
      <header class="ash-toast-header">
        <h2 class="ash-toast-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-toast-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-toast-body">
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-toast-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-toast-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:tree_view"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Tree view")
    description = text_prop(props, ["description", "help"])
    model = tree_nodes(props)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-tree-view", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-tree-view-header">
        <h2 class="ash-tree-view-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-tree-view-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-tree-view-body">
        <ul class="ash-tree-view-list">
          #{render_tree_nodes(model)}
        </ul>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-tree-view-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-tree-view-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:markdown_viewer"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Markdown viewer")
    description = text_prop(props, ["description", "help"])
    content = text_prop(props, "content", "")
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-markdown-viewer", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-markdown-viewer-header">
        <h2 class="ash-markdown-viewer-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-markdown-viewer-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-markdown-viewer-body">
        #{render_markdown_content(content)}
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-markdown-viewer-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-markdown-viewer-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:log_viewer"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Log viewer")
    description = text_prop(props, ["description", "help"])
    entries = log_entries(props)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-log-viewer", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-log-viewer-header">
        <h2 class="ash-log-viewer-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-log-viewer-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-log-viewer-body">
        <div class="ash-log-viewer-lines">
          #{Enum.map_join(entries, &render_log_entry/1)}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-log-viewer-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-log-viewer-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:status"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Status")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    label = text_prop(model, "label", "Unknown")
    tone = text_prop(model, "tone", "neutral")
    detail = text_prop(model, ["detail", "description"])
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-status-surface", "ash-status-tone-#{tone}", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-status-header">
        <h2 class="ash-status-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-status-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-status-body">
        <p class="ash-status-pill">#{label}</p>
        #{if detail, do: "<p class=\"ash-status-detail\">#{detail}</p>", else: ""}
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-status-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-status-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:progress"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Progress")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    label = text_prop(model, "label", "Progress")
    detail = text_prop(model, ["detail", "description"])
    value = numeric_value(model, "value", 0)
    total = max(numeric_value(model, "total", 100), 1)
    percent = percentage(value, total)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-progress-surface", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-progress-header">
        <h2 class="ash-progress-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-progress-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-progress-body">
        <div class="ash-progress-summary">
          <span class="ash-progress-label">#{label}</span>
          <span class="ash-progress-value">#{percent}%</span>
        </div>
        <div class="ash-progress-track" aria-hidden="true">
          <span class="ash-progress-fill" style="width: #{percent}%"></span>
        </div>
        #{if detail, do: "<p class=\"ash-progress-detail\">#{detail}</p>", else: ""}
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-progress-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-progress-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:gauge"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Gauge")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    label = text_prop(model, "label", "Gauge")
    detail = text_prop(model, ["detail", "description"])
    value = numeric_value(model, "value", 0)
    max_value = max(numeric_value(model, "max", 100), 1)
    percent = percentage(value, max_value)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-gauge-surface", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-gauge-header">
        <h2 class="ash-gauge-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-gauge-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-gauge-body">
        <div class="ash-gauge-meter">
          <div class="ash-gauge-arc">
            <span class="ash-gauge-fill" style="height: #{percent}%"></span>
          </div>
          <div class="ash-gauge-summary">
            <span class="ash-gauge-label">#{label}</span>
            <span class="ash-gauge-value">#{percent}%</span>
          </div>
        </div>
        #{if detail, do: "<p class=\"ash-gauge-detail\">#{detail}</p>", else: ""}
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-gauge-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-gauge-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:inline_feedback"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Inline feedback")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    tone = text_prop(model, "tone", "neutral")
    feedback_title = text_prop(model, "title", title)
    detail = text_prop(model, ["detail", "description"])
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-inline-feedback", "ash-inline-feedback-#{tone}", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-inline-feedback-header">
        <h2 class="ash-inline-feedback-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-inline-feedback-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-inline-feedback-body">
        <p class="ash-inline-feedback-badge">#{feedback_title}</p>
        #{if detail, do: "<p class=\"ash-inline-feedback-detail\">#{detail}</p>", else: ""}
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-inline-feedback-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-inline-feedback-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:sparkline"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Sparkline")
    description = text_prop(props, ["description", "help"])
    series = series_points(props)
    max_value = series_max(series)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-sparkline-surface", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-sparkline-header">
        <h2 class="ash-sparkline-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-sparkline-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-sparkline-body">
        <div class="ash-sparkline-chart">
          #{Enum.map_join(series, &render_spark_point(&1, max_value))}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-sparkline-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-sparkline-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:bar_chart"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Bar chart")
    description = text_prop(props, ["description", "help"])
    series = series_points(props)
    max_value = series_max(series)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-bar-chart", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-bar-chart-header">
        <h2 class="ash-bar-chart-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-bar-chart-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-bar-chart-body">
        <div class="ash-bar-chart-bars">
          #{Enum.map_join(series, &render_bar_chart_column(&1, max_value))}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-bar-chart-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-bar-chart-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:line_chart"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Line chart")
    description = text_prop(props, ["description", "help"])
    series = series_points(props)
    max_value = series_max(series)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-line-chart", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-line-chart-header">
        <h2 class="ash-line-chart-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-line-chart-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-line-chart-body">
        <div class="ash-line-chart-grid">
          #{Enum.map_join(series, &render_line_chart_point(&1, max_value))}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-line-chart-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-line-chart-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:stream_widget"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Stream widget")
    description = text_prop(props, ["description", "help"])
    entries = log_entries(props)
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-stream-widget", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-stream-widget-header">
        <h2 class="ash-stream-widget-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-stream-widget-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-stream-widget-body">
        <div class="ash-stream-widget-entries">
          #{Enum.map_join(entries, &render_stream_entry/1)}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-stream-widget-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-stream-widget-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:process_monitor"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Process monitor")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    summary = text_prop(model, ["summary", "detail", "description"])
    processes = model_entries(model, "processes")
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-process-monitor", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-process-monitor-header">
        <h2 class="ash-process-monitor-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-process-monitor-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-process-monitor-body">
        #{if summary, do: "<p class=\"ash-process-monitor-summary\">#{summary}</p>", else: ""}
        <div class="ash-process-monitor-cards">
          #{Enum.map_join(processes, &render_process_card/1)}
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-process-monitor-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-process-monitor-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:supervision_tree_viewer"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Supervision tree viewer")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    root_label = text_prop(model, "label", "Supervisor")
    root_meta = text_prop(model, "meta")
    nodes = model_entries(model, "nodes")
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-supervision-tree-viewer", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-supervision-tree-viewer-header">
        <h2 class="ash-supervision-tree-viewer-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-supervision-tree-viewer-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-supervision-tree-viewer-body">
        <div class="ash-supervision-tree-root">
          <span class="ash-supervision-tree-root-label">#{root_label}</span>
          #{if root_meta, do: "<span class=\"ash-supervision-tree-root-meta\">#{root_meta}</span>", else: ""}
        </div>
        <ul class="ash-supervision-tree-list">
          #{render_supervision_nodes(nodes)}
        </ul>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-supervision-tree-viewer-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-supervision-tree-viewer-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "custom:cluster_dashboard"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, ["title", "label"], "Cluster dashboard")
    description = text_prop(props, ["description", "help"])
    model = metric_model(props)
    headline = text_prop(model, "headline", "Cluster snapshot")
    detail = text_prop(model, ["detail", "description"])
    regions = model_entries(model, "regions")
    alerts = model_entries(model, "alerts")
    action_children = slot_children(iur, "actions")
    body_children = slot_children(iur, "body")
    footer_children = slot_children(iur, "footer")

    body_children =
      if action_children == [] and body_children == [] and footer_children == [] do
        iur["children"] || []
      else
        body_children
      end

    """
    <section class="#{css_classes(["ash-cluster-dashboard", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <header class="ash-cluster-dashboard-header">
        <h2 class="ash-cluster-dashboard-title">#{title}</h2>
        #{if description, do: "<p class=\"ash-cluster-dashboard-description\">#{description}</p>", else: ""}
      </header>
      <div class="ash-cluster-dashboard-body">
        <article class="ash-cluster-dashboard-hero">
          <h3 class="ash-cluster-dashboard-headline">#{headline}</h3>
          #{if detail, do: "<p class=\"ash-cluster-dashboard-detail\">#{detail}</p>", else: ""}
        </article>
        <div class="ash-cluster-dashboard-grid">
          <section class="ash-cluster-dashboard-regions">
            #{Enum.map_join(regions, &render_region_card/1)}
          </section>
          <aside class="ash-cluster-dashboard-alerts">
            #{Enum.map_join(alerts, &render_alert_card/1)}
          </aside>
        </div>
        #{generate_children(body_children, opts)}
      </div>
      <footer class="ash-cluster-dashboard-actions">
        #{generate_children(action_children, opts)}
      </footer>
      <div class="ash-cluster-dashboard-footer">
        #{generate_children(footer_children, opts)}
      </div>
    </section>
    """
  end

  # Ariston-local composite (per ADR 0021 §2). Reads the synthesized
  # `props.row` map populated by `IURHydration` when this element is the
  # destination of a `ui_relationship ... repeat` directive. Mirrors the
  # clause in `packages/live_ui/lib/live_ui/renderer.ex` so the dual-
  # renderer fallback path produces the same HTML shape.
  defp generate_heex(%{"type" => "doc_block_numbered"} = iur, _opts) do
    props = iur["props"] || %{}
    row = Map.get(props, "row") || %{}
    block_id = to_string(Map.get(row, "id") || Map.get(props, "block_id") || iur["id"] || "")
    text = to_string(Map.get(row, "text") || Map.get(props, "content") || "")
    metadata = iur["metadata"] || %{}
    composition = Map.get(metadata, "composition") || %{}
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
  # tokens.css / app.css); no inline colours here. Mirrors the clause in
  # `packages/live_ui/lib/live_ui/renderer.ex` so both render paths produce
  # the same HTML shape.
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
  # HTML mirrors `packages/live_ui/lib/live_ui/renderer.ex` — both paths must
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

  # Ariston-local composite (per ADR 0021 §2). Renders a propose/accept block
  # in the conversation thread — the substrate behind ariston-ui's data-first
  # principle ("documents are projections of conversations"). When an operator
  # or agent proposes a change to a Workspace.Block, the thread shows a
  # proposal_card. In :pending state, action buttons (Accept / Reject) are
  # rendered so the operator can act. In terminal states (:accepted, :rejected,
  # :superseded) the card renders as a history record with a state badge only.
  #
  # Props:
  #   - proposer        — string, author of the proposal (e.g. "Codex")
  #   - timestamp       — string, when the proposal was made
  #   - proposed_text   — string, the Block.text being proposed
  #   - state           — "pending" | "accepted" | "rejected" | "superseded"
  #   - accept_event    — phx-click event name for the Accept button (pending only)
  #   - accept_value    — optional phx-value-id payload for the accept event
  #   - accent_variant  — optional; drives a data-accent attribute for CSS theming
  #                       (e.g. "pascal", "codex", "gemini", "mike")
  #
  # HTML mirrors `packages/live_ui/lib/live_ui/renderer.ex` — both paths must
  # produce the same structure so ariston-ui CSS works on either render path.
  defp generate_heex(%{"type" => "proposal_card"} = iur, _opts) do
    props = iur["props"] || %{}
    proposer = to_string(prop(props, "proposer") || "")
    timestamp = to_string(prop(props, "timestamp") || "")
    proposed_text = to_string(prop(props, "proposed_text") || "")
    state = to_string(prop(props, "state") || "pending")
    accept_event = prop(props, "accept_event")
    accept_value = prop(props, "accept_value")
    reject_event = prop(props, "reject_event")
    reject_value = prop(props, "reject_value")
    accent_variant = prop(props, "accent_variant")

    # Derive the proposer initial for the avatar badge.
    initial =
      case String.trim(proposer) do
        "" -> "?"
        name -> name |> String.upcase() |> String.at(0) || "?"
      end

    # Optional accent variant drives a data attribute used for CSS theming.
    accent_attr =
      if accent_variant && accent_variant != "",
        do: " data-accent=\"#{accent_variant}\"",
        else: ""

    # Avatar token: use accent_variant when present, else neutral.
    avatar_token = if accent_variant && accent_variant != "", do: accent_variant, else: "neutral"

    # State badge: shown in all states for at-a-glance recognition.
    state_dot_style = state_css_var(state)

    # Action buttons: only rendered in pending state.
    action_buttons_html =
      if state == "pending" do
        accept_click = if accept_event && accept_event != "", do: accept_event, else: ""
        # Symmetric with accept_event: callers can configure the reject phx-click name.
        # Falls back to the conventional "reject_proposal" so existing consumers don't break.
        reject_click =
          cond do
            reject_event && reject_event != "" -> reject_event
            true -> "reject_proposal"
          end

        accept_value_attr =
          if accept_value && to_string(accept_value) != "",
            do: " phx-value-id=\"#{accept_value}\"",
            else: ""

        # reject_value falls back to accept_value to preserve current behavior
        # (the existing code reused accept_value_attr on the reject button).
        reject_value_resolved =
          if reject_value && to_string(reject_value) != "", do: reject_value, else: accept_value

        reject_value_attr =
          if reject_value_resolved && to_string(reject_value_resolved) != "",
            do: " phx-value-id=\"#{reject_value_resolved}\"",
            else: ""

        """
          <div class="proposal-card__actions">
            <button class="proposal-card__btn proposal-card__btn--accept" style="background-color: var(--accent-strong, var(--accent));" phx-click="#{accept_click}"#{accept_value_attr}>Accept</button>
            <button class="proposal-card__btn proposal-card__btn--reject" style="color: var(--ink-faint, var(--ink));" phx-click="#{reject_click}"#{reject_value_attr}>Reject</button>
          </div>
        """
      else
        ""
      end

    """
    <div class="#{css_classes(["proposal-card", "proposal-card--#{state}", prop_class(iur)])}" data-state="#{state}"#{accent_attr}>
      <div class="proposal-card__header">
        <span class="proposal-card__avatar ash-avatar ash-avatar-small" style="background-color: var(--avatar-#{avatar_token}, var(--bg-2));" data-variant="#{avatar_token}" aria-hidden="true">
          <span aria-hidden="true">#{initial}</span>
        </span>
        <span class="proposal-card__proposer">#{proposer}</span>
        <span class="proposal-card__timestamp">#{timestamp}</span>
        <span class="proposal-card__state-badge" data-state="#{state}" style="#{state_dot_style}" aria-label="#{state}"></span>
      </div>
      <blockquote class="proposal-card__proposed-text">#{proposed_text}</blockquote>
      #{action_buttons_html}
    </div>
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
    open? = truthy_prop(props, "open", false)
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
    <span class="#{css_classes(["ash-avatar", shape_class, size_class, prop_class(iur)])}" style="background-color: var(--avatar-#{variant}, var(--bg-2));" data-variant="#{variant}"#{role_attr}#{aria_attr}#{style_attr(prop_style(iur))}>#{inner}</span>
    """
  end

  defp generate_heex(%{"type" => "presence_dot"} = iur, _opts) do
    props = iur["props"] || %{}
    state = prop(props, "state", "live")
    size = prop(props, "size", "medium")
    aria_label = prop(props, "aria_label")

    size_class =
      case size do
        "small" -> "ash-presence-dot-small"
        "large" -> "ash-presence-dot-large"
        _ -> "ash-presence-dot-medium"
      end

    bg_style = state_css_var(state)
    aria_attr = if aria_label, do: " aria-label=\"#{aria_label}\"", else: " aria-hidden=\"true\""

    """
    <span class="#{css_classes(["ash-presence-dot", size_class, prop_class(iur)])}" data-state="#{state}" style="#{bg_style}"#{aria_attr}#{style_attr(prop_style(iur))}></span>
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

  defp generate_heex(%{"type" => "unread_badge"} = iur, _opts) do
    props = iur["props"] || %{}
    count = prop(props, "count", 0)
    loud = prop(props, "loud", false)
    aria_label = prop(props, "aria_label")

    loud_class = if loud, do: "is-loud", else: ""
    aria_attr = if aria_label, do: ~s( aria-label="#{aria_label}"), else: ""

    """
    <span class="#{css_classes(["ash-unread-badge", loud_class, prop_class(iur)])}" data-count="#{count}"#{style_attr(prop_style(iur))}#{aria_attr}>#{count}</span>
    """
  end

  defp generate_heex(%{"type" => "sidebar_item"} = iur, opts) do
    props = iur["props"] || %{}
    label = text_prop(props, "label", "")
    glyph = text_prop(props, "glyph", "")
    meta = text_prop(props, "meta", "")
    active = prop(props, "active", false)
    blocked = prop(props, "blocked", false)
    event = text_prop(props, "event", "operator_select")
    item_id = text_prop(props, "item_id", "")
    event_value_key = text_prop(props, "event_value_key", "item_id")
    href = prop(props, "href")
    kind = text_prop(props, "kind", "")
    aria_label = prop(props, "aria_label")

    active_attr = ~s( data-active="#{active}")
    kind_attr = if kind != "", do: ~s( data-kind="#{kind}"), else: ""
    aria_attr = if aria_label, do: ~s( aria-label="#{aria_label}"), else: ""

    blocked_html =
      if blocked,
        do: ~s(<span class="ash-sidebar-item-blocked" aria-hidden="true"></span>),
        else: ""

    meta_html =
      if meta != "", do: ~s(<span class="ash-sidebar-item-meta">#{meta}</span>), else: ""

    trailing_html = generate_children(iur["children"] || [], opts)

    trailing_wrapper =
      if trailing_html != "",
        do: ~s(<span class="ash-sidebar-item-trailing">#{trailing_html}</span>),
        else: ""

    inner = """
    <span class="ash-sidebar-item-name">
      <span class="ash-sidebar-item-glyph" aria-hidden="true">#{glyph}</span>
      <span class="ash-sidebar-item-copy">
        <span class="ash-sidebar-item-label">#{label}</span>
        #{meta_html}
      </span>
    </span>
    <span class="ash-sidebar-item-side">
      #{blocked_html}
      #{trailing_wrapper}
    </span>
    """

    if href do
      """
      <a class="#{css_classes(["ash-sidebar-item", prop_class(iur)])}" href="#{href}"#{active_attr}#{kind_attr}#{aria_attr}#{style_attr(prop_style(iur))}>
        #{inner}
      </a>
      """
    else
      value_attr = if item_id != "", do: ~s( phx-value-#{event_value_key}="#{item_id}"), else: ""

      """
      <button type="button" class="#{css_classes(["ash-sidebar-item", prop_class(iur)])}" phx-click="#{event}"#{value_attr}#{active_attr}#{kind_attr}#{aria_attr}#{style_attr(prop_style(iur))}>
        #{inner}
      </button>
      """
    end
  end

  defp generate_heex(%{"type" => "sidebar_section"} = iur, opts) do
    props = iur["props"] || %{}
    title = text_prop(props, "title", "")
    action_glyph = text_prop(props, "action_glyph", "")
    action_label = text_prop(props, "action_label", "")
    action_event = text_prop(props, "action_event", "")

    action_html =
      if action_event != "" do
        """
        <button type="button" class="ash-sidebar-section-action" phx-click="#{action_event}"#{if action_label != "", do: ~s( aria-label="#{action_label}" title="#{action_label}"), else: ""}>#{action_glyph}</button>
        """
      else
        ""
      end

    """
    <section class="#{css_classes(["ash-sidebar-section", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <div class="ash-sidebar-section-header">
        <span class="ash-sidebar-section-title">#{title}</span>
        #{action_html}
      </div>
      <div class="ash-sidebar-section-body">
        #{generate_children(iur["children"] || [], opts)}
      </div>
    </section>
    """
  end

  defp generate_heex(%{"type" => "sidebar_shell"} = iur, opts) do
    props = iur["props"] || %{}
    collapsed = prop(props, "collapsed", false)

    """
    <aside class="#{css_classes(["ash-sidebar-shell", prop_class(iur)])}" data-collapsed="#{collapsed}"#{style_attr(prop_style(iur))}>
      <div class="ash-sidebar-shell-scroll">
        #{generate_children(iur["children"] || [], opts)}
      </div>
    </aside>
    """
  end

  defp generate_heex(%{"type" => "mode_nav"} = iur, _opts) do
    props = iur["props"] || %{}
    items = prop(props, "items", [])
    event = text_prop(props, "event", "set_mode")
    event_value_key = text_prop(props, "event_value_key", "mode")
    aria_label = text_prop(props, "aria_label", "Primary navigation")

    items_html =
      Enum.map_join(items, fn item ->
        item = normalize_item(item)
        label = text_prop(item, "label", "")
        value = text_prop(item, "value", "")
        shortcut = text_prop(item, "shortcut", "")
        current = if prop(item, "current", false), do: "true", else: "false"

        shortcut_html =
          if shortcut != "",
            do: ~s(<span class="ash-mode-nav-shortcut">#{shortcut}</span>),
            else: ""

        """
        <button type="button" class="ash-mode-nav-item" aria-current="#{current}" phx-click="#{event}" phx-value-#{event_value_key}="#{value}">
          <span class="ash-mode-nav-label">#{label}</span>
          #{shortcut_html}
        </button>
        """
      end)

    """
    <nav class="#{css_classes(["ash-mode-nav", prop_class(iur)])}" aria-label="#{aria_label}"#{style_attr(prop_style(iur))}>
      #{items_html}
    </nav>
    """
  end

  defp generate_heex(%{"type" => "top_strip"} = iur, opts) do
    props = iur["props"] || %{}
    brand = text_prop(props, "brand", "Ariston")
    context = text_prop(props, "context", "")
    current_theme = text_prop(props, "current_theme", "system")
    theme_event = text_prop(props, "theme_event", "set_theme")
    palette_event = text_prop(props, "palette_event", "open_palette")
    pane_event = text_prop(props, "pane_event", "toggle_pane")
    pane_open = prop(props, "pane_open", false)
    children = iur["children"] || []
    center = Enum.at(children, 0)

    theme_button = fn value, glyph, label ->
      pressed = if current_theme == value, do: "true", else: "false"

      """
      <button type="button" class="ash-top-strip-theme-button" aria-pressed="#{pressed}" aria-label="#{label}" title="#{label}" phx-click="#{theme_event}" phx-value-theme="#{value}">#{glyph}</button>
      """
    end

    """
    <header class="#{css_classes(["ash-top-strip", prop_class(iur)])}"#{style_attr(prop_style(iur))}>
      <div class="ash-top-strip-identity">
        <span class="ash-top-strip-mark" aria-hidden="true">⊢</span>
        <div class="ash-top-strip-crumb">
          <b>#{brand}</b>
          #{if context != "", do: ~s(<span class="ash-top-strip-sep">/</span><span>#{context}</span>), else: ""}
        </div>
      </div>
      <div class="ash-top-strip-center">
        #{if center, do: generate_heex(center, opts), else: ""}
      </div>
      <div class="ash-top-strip-actions">
        <div class="ash-top-strip-theme" role="group" aria-label="Theme">
          #{theme_button.("light", "☼", "light")}
          #{theme_button.("system", "⚙", "system")}
          #{theme_button.("dark", "☾", "dark")}
        </div>
        <button type="button" class="ash-top-strip-pane-toggle" aria-pressed="#{pane_open}" phx-click="#{pane_event}" title="toggle reference pane" aria-label="toggle reference pane">
          ▥
        </button>
        <button type="button" class="ash-top-strip-palette" phx-click="#{palette_event}" title="quick jump" aria-label="quick jump">
          <span>⌕</span>
          <span>jump</span>
          <span class="ash-top-strip-shortcut">⌘K</span>
        </button>
      </div>
    </header>
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
    title = text_prop(props, "title", "")
    meta = text_prop(props, "meta", "")
    row_id = prop(props, "row_id")
    event = prop(props, "event", "select_artifact")
    event_value_key = prop(props, "event_value_key", "row_id")
    active = prop(props, "active", false)
    href = prop(props, "href")
    extra_class = prop(props, "class", "")
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

  defp generate_heex(%{"type" => "pipeline_stepper_horizontal"} = iur, opts) do
    props = iur["props"] || %{}
    steps = Map.get(props, "steps", [])
    active_index = Map.get(props, "active_index", 0)
    _event = Map.get(props, "event", "select_step")
    event_value_key = Map.get(props, "event_value_key", "step_index")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")

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
          ~s(<button type="button" class="ash-pipeline-stepper-horizontal-step" data-state="#{state}" phx-click="#{event_name(event_prefix, :action)}" phx-value-step_index="#{step_index}"#{value_attr}>
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
    max_val = max(numeric_value(props, "max", 100), 1)
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
    open? = truthy_prop(props, "open", false)
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
    tone = text_prop(props, "tone", "info")
    kicker = text_prop(props, "kicker")
    body_text = text_prop(props, ["text", "content", "body"])
    children = iur["children"] || []

    """
    <section class="#{css_classes(["ash-event-callout", prop_class(iur)])}"#{style_attr(prop_style(iur))} data-tone="#{tone}">
      <div class="ash-event-callout-content">
        #{if kicker, do: "<span class=\"ash-event-callout-kicker\">#{kicker}</span>", else: ""}
        <div class="ash-event-callout-body">
          #{if body_text, do: body_text, else: generate_children(children, opts)}
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

    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    disabled_attr = if disabled, do: " disabled", else: ""
    children_html = generate_children(iur["children"], opts)
    _event_prefix = event_prefix

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

  defp generate_children(children, opts) when is_list(children) do
    Enum.map_join(children, &generate_heex(&1, opts))
  end

  # Extract event bindings from IUR
  defp extract_event_bindings(iur, event_prefix) do
    events = []

    events = extract_events_from_children(iur["children"] || [], events, event_prefix)
    events = extract_events_from_bindings(iur["bindings"] || [], events, event_prefix)

    Enum.uniq(events)
  end

  defp extract_events_from_children(children, events, event_prefix) do
    Enum.reduce(children, events, fn child, acc ->
      case child["type"] do
        "button" ->
          [%{event: event_name(event_prefix, :action), target: child["id"]} | acc]

        "input" ->
          [
            %{event: event_name(event_prefix, :change), target: child["id"]} | acc
          ]

        "checkbox" ->
          [%{event: event_name(event_prefix, :change), target: child["id"]} | acc]

        _ ->
          extract_events_from_children(child["children"] || [], acc, event_prefix)
      end
    end)
  end

  defp extract_events_from_bindings(bindings, events, event_prefix) do
    Enum.reduce(bindings, events, fn binding, acc ->
      type = Map.get(binding, "type")

      event_type =
        case type do
          "event" -> :action
          "bidirectional" -> :change
          "collection" -> :change
          _ -> :change
        end

      [%{event: event_name(event_prefix, event_type), target: binding["target"]} | acc]
    end)
  end

  defp build_event_handlers(bindings) do
    Enum.map(bindings, fn binding ->
      %{
        event: binding.event,
        handler: :"handle_#{String.replace(binding.event, ":", "_")}",
        target: binding.target
      }
    end)
  end

  defp extract_default_value(source) when is_map(source) do
    Map.get(source, "default", nil)
  end

  defp extract_default_value(_), do: nil

  defp extract_static_elements(iur) do
    # Elements that don't need reactive updates
    extract_static(iur["children"] || [], [])
  end

  defp extract_static(children, acc) when is_list(children) do
    Enum.reduce(children, acc, fn child, acc2 ->
      if child["type"] in ["text", "divider", "spacer"] and
           not has_signals(child) do
        [child["id"] | acc2]
      else
        extract_static(child["children"] || [], acc2)
      end
    end)
  end

  defp extract_static(_, acc), do: acc

  defp has_signals(child) do
    signals = Map.get(child, "signals", [])
    length(signals) > 0
  end

  defp extract_dynamic_streams(iur) do
    # Extract bindings that should be streams (collections)
    bindings = iur["bindings"] || []

    bindings
    |> Enum.filter(fn binding -> Map.get(binding, "type") == "collection" end)
    |> Enum.map(fn binding -> Map.get(binding, "target") end)
  end

  defp emit_render_telemetry(result, started_at, metadata) do
    duration = System.monotonic_time() - started_at

    case result do
      {:ok, _rendered} = success ->
        Telemetry.emit(
          :render,
          :complete,
          %{count: 1, duration: duration},
          Map.put(metadata, :status, :ok)
        )

        success

      {:error, reason} = error ->
        error_metadata = Map.merge(metadata, %{status: :error, error: inspect(reason)})
        Telemetry.emit(:render, :error, %{count: 1, duration: duration}, error_metadata)
        error
    end
  end

  defp render_metadata(canonical_iur, renderer) do
    %{
      renderer: renderer,
      resource_id: Map.get(canonical_iur, "id"),
      resource_type: :screen,
      screen_id: Map.get(canonical_iur, "id")
    }
  end

  defp render_text_input(iur, opts, css_base) do
    props = iur["props"] || %{}
    name = Map.get(props, "name", "input")
    placeholder = Map.get(props, "placeholder", "")
    value = Map.get(props, "value", "")
    type = Map.get(props, "type", "text")
    binding = find_binding(opts, iur["id"], "bidirectional")
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    value_attr = if type == "file", do: "", else: attr("value", value)

    """
    <input type="#{type}" class="#{css_classes(["ash-#{css_base}", prop_class(iur)])}" name="#{name}"#{value_attr} placeholder="#{placeholder}"#{style_attr(prop_style(iur))} phx-blur="#{event_name(event_prefix, :change)}" phx-change="#{event_name(event_prefix, :change)}"#{attr("phx-value-binding_id", binding && binding["id"])}#{attr("phx-value-target", binding && binding["target"])}#{attr("phx-value-element_id", iur["id"])}#{attr("phx-value-signal", "change")} />
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

  defp truthy_prop(props, key, default) do
    case prop(props, key, default) do
      value when value in [true, "true", "open", "visible", 1, "1", "yes"] -> true
      _ -> false
    end
  end

  defp text_prop(props, keys, default \\ nil)

  defp text_prop(props, keys, default) when is_list(keys) do
    Enum.reduce_while(keys, default, fn key, _acc ->
      case prop(props, key) do
        value when value in [nil, "", []] -> {:cont, default}
        value -> {:halt, to_string(value)}
      end
    end)
  end

  defp text_prop(props, key, default), do: text_prop(props, [key], default)

  defp normalize_choice(option) when is_map(option) do
    {text_prop(option, ["label", "title", "value"], ""), prop(option, "value")}
  end

  defp normalize_choice({label, value}), do: {label, value}
  defp normalize_choice(option) when is_binary(option), do: {option, option}
  defp normalize_choice(option), do: {to_string(option), option}

  defp normalize_item(item) when is_map(item), do: item

  defp normalize_item(item) when is_list(item) do
    if Keyword.keyword?(item), do: Enum.into(item, %{}), else: %{"value" => item}
  end

  defp normalize_item(item), do: %{"value" => item}

  defp collection_items(props) do
    items = prop(props, "items")
    collection = prop(props, "collection")
    entries = prop(props, "entries")

    cond do
      is_list(items) -> items
      is_map(collection) -> prop(collection, "items", [])
      is_list(entries) -> entries
      true -> []
    end
  end

  defp table_columns(props) do
    case prop(props, "columns", []) do
      columns when is_list(columns) and columns != [] ->
        columns

      _other ->
        collection_items(props)
        |> List.first()
        |> normalize_item()
        |> Map.keys()
        |> Enum.sort()
        |> Enum.map(&%{"key" => &1, "label" => Macro.camelize(&1)})
    end
  end

  defp render_list_item(item) do
    item = normalize_item(item)
    title = text_prop(item, ["title", "label", "name", "value"], "Item")
    summary = text_prop(item, ["summary", "description", "message"])
    meta = text_prop(item, ["meta", "status"])

    """
    <li class="ash-list-item">
      <div class="ash-list-item-main">
        <p class="ash-list-item-title">#{title}</p>
        #{if summary, do: "<p class=\"ash-list-item-summary\">#{summary}</p>", else: ""}
      </div>
      #{if meta, do: "<span class=\"ash-list-item-meta\">#{meta}</span>", else: ""}
    </li>
    """
  end

  defp render_table_header(column) do
    column = normalize_item(column)
    label = text_prop(column, ["label", "title", "key"], "")
    "<th>#{label}</th>"
  end

  defp render_table_row(item, columns) do
    item = normalize_item(item)

    cells =
      columns
      |> Enum.map_join(fn column ->
        column = normalize_item(column)
        key = text_prop(column, "key", "")
        value = table_cell_value(item, key)
        "<td>#{value}</td>"
      end)

    "<tr>#{cells}</tr>"
  end

  defp table_cell_value(item, key) when is_binary(key) do
    value =
      Map.get(item, key) ||
        try do
          Map.get(item, String.to_existing_atom(key))
        rescue
          ArgumentError -> nil
        end

    case value do
      nil -> ""
      value -> to_string(value)
    end
  end

  defp tree_nodes(props) do
    case prop(props, "model", []) do
      nodes when is_list(nodes) -> nodes
      %{} = node -> [node]
      _other -> []
    end
  end

  defp render_tree_nodes([]) do
    ~s(<li class="ash-tree-view-empty">No nodes loaded.</li>)
  end

  defp render_tree_nodes(nodes) when is_list(nodes) do
    Enum.map_join(nodes, fn node ->
      node = normalize_item(node)
      label = text_prop(node, ["label", "title", "name", "value"], "Node")
      meta = text_prop(node, ["meta", "status"])
      children = Map.get(node, "children") || Map.get(node, :children) || []

      """
      <li class="ash-tree-view-node">
        <div class="ash-tree-view-node-row">
          <span class="ash-tree-view-node-label">#{label}</span>
          #{if meta, do: "<span class=\"ash-tree-view-node-meta\">#{meta}</span>", else: ""}
        </div>
        #{if children != [], do: "<ul class=\"ash-tree-view-children\">#{render_tree_nodes(children)}</ul>", else: ""}
      </li>
      """
    end)
  end

  defp render_markdown_content(markdown) when markdown in [nil, ""] do
    ~s(<p class="ash-markdown-viewer-empty">No markdown content loaded.</p>)
  end

  defp render_markdown_content(markdown) do
    markdown
    |> String.split("\n", trim: false)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join(fn line ->
      cond do
        String.starts_with?(line, "## ") ->
          "<h3>#{String.trim_leading(line, "## ")}</h3>"

        String.starts_with?(line, "# ") ->
          "<h2>#{String.trim_leading(line, "# ")}</h2>"

        String.starts_with?(line, "- ") ->
          "<p class=\"ash-markdown-viewer-bullet\">• #{String.trim_leading(line, "- ")}</p>"

        true ->
          "<p>#{line}</p>"
      end
    end)
  end

  defp log_entries(props) do
    case prop(props, "entries", []) do
      entries when is_list(entries) -> entries
      _other -> []
    end
  end

  defp render_log_entry(entry) do
    entry = normalize_item(entry)
    timestamp = text_prop(entry, ["timestamp", "time"], "--:--:--")
    level = text_prop(entry, "level", "INFO")
    message = text_prop(entry, ["message", "summary", "value"], "")

    """
    <article class="ash-log-viewer-entry">
      <span class="ash-log-viewer-time">#{timestamp}</span>
      <span class="ash-log-viewer-level">#{level}</span>
      <span class="ash-log-viewer-message">#{message}</span>
    </article>
    """
  end

  defp metric_model(props) do
    case prop(props, "model", %{}) do
      %{} = model -> model
      _other -> %{}
    end
  end

  defp numeric_value(model, key, default) do
    case prop(model, key, default) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        round(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, _rest} -> parsed
          :error -> default
        end

      _other ->
        default
    end
  end

  defp percentage(value, total) when is_integer(value) and is_integer(total) and total > 0 do
    value
    |> Kernel./(total)
    |> Kernel.*(100)
    |> round()
    |> min(100)
    |> max(0)
  end

  defp series_points(props) do
    case prop(props, "series", []) do
      series when is_list(series) -> series
      _other -> []
    end
  end

  defp series_max(series) do
    series
    |> Enum.map(&numeric_value(normalize_item(&1), "value", 0))
    |> Enum.max(fn -> 1 end)
    |> max(1)
  end

  defp render_spark_point(point, max_value) do
    point = normalize_item(point)
    label = text_prop(point, "label", "")
    value = numeric_value(point, "value", 0)
    height = chart_height(value, max_value)

    """
    <span class="ash-sparkline-point" title="#{label}: #{value}">
      <span class="ash-sparkline-bar" style="height: #{height}%"></span>
      <span class="ash-sparkline-label">#{label}</span>
    </span>
    """
  end

  defp render_bar_chart_column(point, max_value) do
    point = normalize_item(point)
    label = text_prop(point, "label", "")
    value = numeric_value(point, "value", 0)
    height = chart_height(value, max_value)

    """
    <article class="ash-bar-chart-column">
      <span class="ash-bar-chart-value">#{value}</span>
      <span class="ash-bar-chart-bar" style="height: #{height}%"></span>
      <span class="ash-bar-chart-label">#{label}</span>
    </article>
    """
  end

  defp render_line_chart_point(point, max_value) do
    point = normalize_item(point)
    label = text_prop(point, "label", "")
    value = numeric_value(point, "value", 0)
    height = chart_height(value, max_value)

    """
    <article class="ash-line-chart-point">
      <span class="ash-line-chart-marker" style="bottom: #{height}%"></span>
      <span class="ash-line-chart-stem" style="height: #{height}%"></span>
      <span class="ash-line-chart-value">#{value}</span>
      <span class="ash-line-chart-label">#{label}</span>
    </article>
    """
  end

  defp chart_height(value, max_value) when max_value > 0 do
    value
    |> Kernel./(max_value)
    |> Kernel.*(100)
    |> round()
    |> min(100)
    |> max(8)
  end

  defp render_stream_entry(entry) do
    entry = normalize_item(entry)
    timestamp = text_prop(entry, ["timestamp", "time"], "--:--:--")
    label = text_prop(entry, ["label", "level"], "feed")
    message = text_prop(entry, ["message", "summary", "value"], "")

    """
    <article class="ash-stream-widget-entry">
      <span class="ash-stream-widget-time">#{timestamp}</span>
      <span class="ash-stream-widget-label">#{label}</span>
      <p class="ash-stream-widget-message">#{message}</p>
    </article>
    """
  end

  defp model_entries(model, key) do
    case prop(model, key, []) do
      entries when is_list(entries) -> entries
      _other -> []
    end
  end

  defp render_process_card(process) do
    process = normalize_item(process)
    name = text_prop(process, ["name", "label", "title"], "process")
    state = text_prop(process, ["state", "status"], "unknown")
    meta = text_prop(process, "meta")

    """
    <article class="ash-process-monitor-card">
      <span class="ash-process-monitor-name">#{name}</span>
      <span class="ash-process-monitor-state">#{state}</span>
      #{if meta, do: "<span class=\"ash-process-monitor-meta\">#{meta}</span>", else: ""}
    </article>
    """
  end

  defp render_supervision_nodes([]) do
    ~s(<li class="ash-supervision-tree-empty">No supervised children loaded.</li>)
  end

  defp render_supervision_nodes(nodes) when is_list(nodes) do
    Enum.map_join(nodes, fn node ->
      node = normalize_item(node)
      label = text_prop(node, ["label", "title", "name"], "node")
      meta = text_prop(node, ["meta", "status"])
      children = Map.get(node, "children") || Map.get(node, :children) || []

      """
      <li class="ash-supervision-tree-node">
        <div class="ash-supervision-tree-node-row">
          <span class="ash-supervision-tree-node-label">#{label}</span>
          #{if meta, do: "<span class=\"ash-supervision-tree-node-meta\">#{meta}</span>", else: ""}
        </div>
        #{if children != [], do: "<ul class=\"ash-supervision-tree-children\">#{render_supervision_nodes(children)}</ul>", else: ""}
      </li>
      """
    end)
  end

  defp render_region_card(region) do
    region = normalize_item(region)
    label = text_prop(region, ["label", "title"], "region")
    status = text_prop(region, ["status", "state"], "unknown")
    load = text_prop(region, "load")

    """
    <article class="ash-cluster-dashboard-region">
      <span class="ash-cluster-dashboard-region-label">#{label}</span>
      <span class="ash-cluster-dashboard-region-status">#{status}</span>
      #{if load, do: "<span class=\"ash-cluster-dashboard-region-load\">#{load}</span>", else: ""}
    </article>
    """
  end

  defp render_alert_card(alert) do
    alert = normalize_item(alert)
    title = text_prop(alert, ["title", "label"], "Alert")
    message = text_prop(alert, ["message", "summary", "value"], "")

    """
    <article class="ash-cluster-dashboard-alert">
      <span class="ash-cluster-dashboard-alert-title">#{title}</span>
      <p class="ash-cluster-dashboard-alert-message">#{message}</p>
    </article>
    """
  end

  defp slot_children(iur, slot) do
    desired = to_string(slot)

    (iur["children"] || [])
    |> Enum.filter(&(child_slot(&1) == desired))
  end

  defp child_slot(child) do
    metadata = child["metadata"] || %{}
    slot = Map.get(metadata, "slot", Map.get(metadata, :slot, "body"))
    to_string(slot)
  end

  defp icon_glyph(nil), do: "•"

  defp icon_glyph(name) do
    case to_string(name) do
      "sparkles" -> "✦"
      "star" -> "★"
      "check" -> "✓"
      "alert" -> "!"
      "image" -> "▣"
      other -> other |> String.first() |> Kernel.||("•") |> String.upcase()
    end
  end

  defp dom_id(nil), do: nil
  defp dom_id(value) when is_atom(value), do: Atom.to_string(value)
  defp dom_id(value), do: to_string(value)

  defp css_classes(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&nil_or_empty?/1)
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
    |> Enum.reject(&nil_or_empty?/1)
    |> Kernel.++(if nil_or_empty?(extra), do: [], else: [extra])
    |> Enum.join("; ")
  end

  defp event_name(prefix, :action), do: "#{prefix}_action"
  defp event_name(prefix, :change), do: "#{prefix}_change"

  defp nil_or_empty?(value), do: value in [nil, ""]

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

  defp render_phoenix_form_field(field) when is_map(field) do
    name = field_value(field, "name", "")
    type = field_value(field, "type", "text")
    label = field_value(field, "label", nil)
    placeholder = field_value(field, "placeholder", "")
    autocomplete = field_value(field, "autocomplete", nil)
    value = field_value(field, "value", "")
    required? = !!field_value(field, "required", false)
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

  defp field_value(field, key, default) when is_map(field) do
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

  # Minimal HTML escaping for segment content in redline_inline and code_block_syntax_highlighted.
  # Replaces the five XML/HTML special characters so user-supplied text
  # cannot inject raw markup into the rendered output.
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
