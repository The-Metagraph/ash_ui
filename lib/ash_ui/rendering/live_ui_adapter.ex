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

  alias AshUI.Rendering.IURAdapter
  alias AshUI.Compilation.IUR
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

    result =
      if Code.ensure_loaded?(LiveUI.Renderer) do
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
    event_prefix = Map.get(opts, :event_prefix, "ash_ui")
    variant = Map.get(iur["props"] || %{}, "variant", "primary")
    binding = find_binding(opts, iur["id"], "event")

    click_event = event_name(event_prefix, :action)
    action_attr = attr("phx-value-action_id", binding && binding["id"])
    element_attr = attr("phx-value-element_id", iur["id"])
    signal_attr = attr("phx-value-signal", binding_signal(binding, "click"))
    class_name = css_classes(["ash-button", "ash-button-#{variant}", prop_class(iur)])

    """
    <button type="button" class="#{class_name}"#{style_attr(prop_style(iur))} phx-click="#{click_event}"#{action_attr}#{element_attr}#{signal_attr}>#{label}</button>
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
    |> Enum.reject(&is_nil_or_empty?/1)
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
    |> Enum.reject(&is_nil_or_empty?/1)
    |> Kernel.++(if is_nil_or_empty?(extra), do: [], else: [extra])
    |> Enum.join("; ")
  end

  defp event_name(prefix, :action), do: "#{prefix}_action"
  defp event_name(prefix, :change), do: "#{prefix}_change"

  defp is_nil_or_empty?(value), do: value in [nil, ""]
end
