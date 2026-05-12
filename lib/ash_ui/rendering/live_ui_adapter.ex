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
end
