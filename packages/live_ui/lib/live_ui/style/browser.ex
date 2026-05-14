defmodule LiveUi.Style.Browser do
  @moduledoc """
  Browser-facing realization contract for resolved `live_ui` style profiles.

  `live_ui` continues to preserve semantic hooks such as `tone`, `variant`,
  `state`, and native classes. This payload adds the browser-visible output that
  can be consumed uniformly by direct-native widgets and canonical `UnifiedIUR`
  lowering.

  The precedence order is:

  1. native component defaults
  2. native variant and state hooks
  3. canonical theme resolution
  4. local style overrides
  5. browser-host attrs
  """

  alias UnifiedIUR.Style, as: CanonicalStyle
  alias UnifiedIUR.Style.TextAttributes

  @type top_level_field ::
          :foreground
          | :background
          | :border_color
          | :border
          | :text
          | :spacing
          | :sizing
          | :alignment
          | :visibility
          | :emphasis

  @type diagnostic_field :: top_level_field() | String.t()

  @type precedence_stage ::
          :native_component_defaults
          | :native_variant_and_state_hooks
          | :canonical_theme_resolution
          | :local_style_overrides
          | :browser_host_attrs

  @type mode :: :semantic_only | :mixed | :realized

  @type diagnostics :: %{
          fallback: :semantic_hooks | :mixed | :realized_output,
          semantic_only_fields: [top_level_field()],
          unsupported_fields: [diagnostic_field()],
          ignored_fields: [diagnostic_field()]
        }

  @type t :: %__MODULE__{
          mode: mode(),
          css_vars: %{optional(String.t()) => String.t()},
          attrs: %{optional(String.t()) => String.t()},
          realized_fields: [top_level_field()],
          semantic_only_fields: [top_level_field()],
          unsupported_fields: [diagnostic_field()],
          diagnostics: diagnostics(),
          precedence: [precedence_stage()]
        }

  @default_precedence [
    :native_component_defaults,
    :native_variant_and_state_hooks,
    :canonical_theme_resolution,
    :local_style_overrides,
    :browser_host_attrs
  ]

  @enforce_keys [
    :css_vars,
    :attrs,
    :realized_fields,
    :semantic_only_fields,
    :unsupported_fields,
    :diagnostics
  ]
  defstruct mode: :semantic_only,
            css_vars: %{},
            attrs: %{},
            realized_fields: [],
            semantic_only_fields: [],
            unsupported_fields: [],
            diagnostics: %{
              fallback: :semantic_hooks,
              semantic_only_fields: [],
              unsupported_fields: [],
              ignored_fields: []
            },
            precedence: @default_precedence

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil) do
    %__MODULE__{
      css_vars: %{},
      attrs: %{},
      realized_fields: [],
      semantic_only_fields: [],
      unsupported_fields: [],
      diagnostics: %{
        fallback: :semantic_hooks,
        semantic_only_fields: [],
        unsupported_fields: [],
        ignored_fields: []
      }
    }
  end

  def new(%__MODULE__{} = browser) do
    %__MODULE__{
      mode: normalize_mode(browser.mode),
      css_vars: normalize_string_map(browser.css_vars),
      attrs: normalize_string_map(browser.attrs),
      realized_fields: normalize_atom_fields(browser.realized_fields),
      semantic_only_fields: normalize_atom_fields(browser.semantic_only_fields),
      unsupported_fields: normalize_diagnostics(browser.unsupported_fields),
      diagnostics:
        normalize_diagnostics_map(
          browser.diagnostics,
          browser.semantic_only_fields,
          browser.unsupported_fields
        ),
      precedence: normalize_precedence(browser.precedence)
    }
  end

  def new(browser) when is_list(browser), do: browser |> Enum.into(%{}) |> new()

  def new(browser) when is_map(browser) do
    %__MODULE__{
      mode: browser |> fetch(:mode, :semantic_only) |> normalize_mode(),
      css_vars: browser |> fetch(:css_vars, %{}) |> normalize_string_map(),
      attrs: browser |> fetch(:attrs, %{}) |> normalize_string_map(),
      realized_fields: browser |> fetch(:realized_fields, []) |> normalize_atom_fields(),
      semantic_only_fields:
        browser |> fetch(:semantic_only_fields, []) |> normalize_atom_fields(),
      unsupported_fields: browser |> fetch(:unsupported_fields, []) |> normalize_diagnostics(),
      diagnostics:
        browser
        |> fetch(:diagnostics, %{})
        |> normalize_diagnostics_map(
          fetch(browser, :semantic_only_fields, []),
          fetch(browser, :unsupported_fields, [])
        ),
      precedence: browser |> fetch(:precedence, @default_precedence) |> normalize_precedence()
    }
  end

  @spec realize(CanonicalStyle.t() | keyword() | map() | nil) :: t()
  def realize(style) do
    canonical = CanonicalStyle.new(style)

    css_vars =
      %{}
      |> maybe_put("--live-ui-foreground", serialize_color(canonical.foreground))
      |> maybe_put("--live-ui-background", serialize_color(canonical.background))
      |> maybe_put("--live-ui-border-color", serialize_color(canonical.border_color))
      |> Map.merge(border_vars(canonical.border))
      |> Map.merge(text_vars(canonical.text))
      |> Map.merge(spacing_vars(canonical.spacing))
      |> Map.merge(sizing_vars(canonical.sizing))
      |> Map.merge(alignment_vars(canonical.alignment))
      |> Map.merge(visibility_vars(canonical.visibility))

    realized_fields =
      []
      |> maybe_track_field(canonical.foreground, :foreground)
      |> maybe_track_field(canonical.background, :background)
      |> maybe_track_field(canonical.border_color, :border_color)
      |> maybe_track_field(canonical.border, :border)
      |> maybe_track_field(canonical.text, :text, &text_realized?/1)
      |> maybe_track_field(canonical.spacing, :spacing)
      |> maybe_track_field(canonical.sizing, :sizing)
      |> maybe_track_field(canonical.alignment, :alignment)
      |> maybe_track_field(canonical.visibility, :visibility, &visibility_realized?/1)
      |> Enum.uniq()
      |> Enum.sort()

    semantic_only_fields =
      canonical
      |> semantic_fields()
      |> Enum.sort()

    unsupported_fields =
      canonical
      |> unsupported_fields()
      |> Enum.sort_by(&to_string/1)

    ignored_fields =
      canonical
      |> ignored_fields()
      |> Enum.sort_by(&to_string/1)

    mode = infer_mode(css_vars, semantic_only_fields, unsupported_fields)
    diagnostics = diagnostics(mode, semantic_only_fields, unsupported_fields, ignored_fields)

    %__MODULE__{
      mode: mode,
      css_vars: css_vars,
      attrs:
        browser_attrs(
          mode,
          css_vars,
          realized_fields,
          semantic_only_fields,
          unsupported_fields,
          ignored_fields
        ),
      realized_fields: realized_fields,
      semantic_only_fields: semantic_only_fields,
      unsupported_fields: unsupported_fields,
      diagnostics: diagnostics,
      precedence: @default_precedence
    }
  end

  defp browser_attrs(
         mode,
         css_vars,
         realized_fields,
         semantic_only_fields,
         unsupported_fields,
         ignored_fields
       ) do
    %{}
    |> maybe_put("style", inline_style(css_vars))
    |> maybe_put("data-live-ui-browser-style", Atom.to_string(mode))
    |> maybe_put("data-live-ui-browser-fallback", fallback_label(mode))
    |> maybe_put("data-live-ui-realized-style-fields", join_fields(realized_fields))
    |> maybe_put("data-live-ui-semantic-style-fields", join_fields(semantic_only_fields))
    |> maybe_put("data-live-ui-unsupported-style-fields", join_fields(unsupported_fields))
    |> maybe_put("data-live-ui-ignored-style-fields", join_fields(ignored_fields))
  end

  defp semantic_fields(%CanonicalStyle{} = style) do
    []
    |> maybe_track_field(style.emphasis, :emphasis)
  end

  defp unsupported_fields(%CanonicalStyle{} = style) do
    text_unsupported(style.text) ++ visibility_unsupported(style.visibility)
  end

  defp ignored_fields(%CanonicalStyle{} = style) do
    []
    |> Enum.concat(ignored_state_variants(style.state_variants))
  end

  defp ignored_state_variants(variants) when variants == %{}, do: []

  defp ignored_state_variants(variants) when is_map(variants) do
    variants
    |> Map.keys()
    |> Enum.map_join(",", fn key -> "state_variants.#{key}" end)
    |> case do
      "" -> []
      value -> String.split(value, ",")
    end
  end

  defp border_vars(border) when border in [%{}, nil], do: %{}

  defp border_vars(border) do
    border = normalize_map(border)

    %{}
    |> maybe_put("--live-ui-border-width", serialize_length(fetch(border, :weight)))
    |> maybe_put("--live-ui-border-radius", serialize_radius(fetch(border, :radius)))
    |> maybe_put("--live-ui-border-style", serialize_border_style(fetch(border, :style)))
  end

  defp text_vars(%TextAttributes{} = text) do
    decorations =
      []
      |> maybe_append(fetch_flag(text, :underline?), "underline")
      |> maybe_append(fetch_flag(text, :strikethrough?), "line-through")
      |> Enum.join(" ")
      |> case do
        "" -> nil
        value -> value
      end

    %{}
    |> maybe_put("--live-ui-font-weight", if(fetch_flag(text, :bold?), do: "700"))
    |> maybe_put("--live-ui-font-style", if(fetch_flag(text, :italic?), do: "italic"))
    |> maybe_put("--live-ui-text-decoration", decorations)
    |> maybe_put("--live-ui-text-opacity", if(fetch_flag(text, :dim?), do: "0.72"))
    |> maybe_put("--live-ui-visibility", if(fetch_flag(text, :hidden?), do: "hidden"))
  end

  defp spacing_vars(spacing) when spacing in [%{}, nil], do: %{}

  defp spacing_vars(spacing) do
    spacing = normalize_map(spacing)

    %{}
    |> maybe_put("--live-ui-padding", serialize_spacing(fetch(spacing, :padding)))
    |> maybe_put("--live-ui-padding-inline", serialize_spacing(fetch(spacing, :padding_x)))
    |> maybe_put("--live-ui-padding-block", serialize_spacing(fetch(spacing, :padding_y)))
    |> maybe_put("--live-ui-margin", serialize_spacing(fetch(spacing, :margin)))
    |> maybe_put("--live-ui-margin-inline", serialize_spacing(fetch(spacing, :margin_x)))
    |> maybe_put("--live-ui-margin-block", serialize_spacing(fetch(spacing, :margin_y)))
    |> maybe_put("--live-ui-gap", serialize_spacing(fetch(spacing, :gap)))
  end

  defp sizing_vars(sizing) when sizing in [%{}, nil], do: %{}

  defp sizing_vars(sizing) do
    sizing = normalize_map(sizing)

    %{}
    |> maybe_put("--live-ui-width", serialize_size(fetch(sizing, :width)))
    |> maybe_put("--live-ui-height", serialize_size(fetch(sizing, :height)))
    |> maybe_put("--live-ui-min-width", serialize_size(fetch(sizing, :min_width)))
    |> maybe_put("--live-ui-min-height", serialize_size(fetch(sizing, :min_height)))
    |> maybe_put("--live-ui-max-width", serialize_size(fetch(sizing, :max_width)))
    |> maybe_put("--live-ui-max-height", serialize_size(fetch(sizing, :max_height)))
  end

  defp alignment_vars(alignment) when alignment in [%{}, nil], do: %{}

  defp alignment_vars(alignment) do
    alignment = normalize_map(alignment)

    %{}
    |> maybe_put("--live-ui-align-items", serialize_align(fetch(alignment, :align)))
    |> maybe_put("--live-ui-justify-content", serialize_justify(fetch(alignment, :justify)))
    |> maybe_put("--live-ui-text-align", serialize_text_align(fetch(alignment, :text_align)))
    |> maybe_put("--live-ui-align-self", serialize_align(fetch(alignment, :anchor)))
  end

  defp visibility_vars(visibility) when visibility in [%{}, nil], do: %{}

  defp visibility_vars(visibility) do
    visibility = normalize_map(visibility)

    %{}
    |> maybe_put("--live-ui-display", if(fetch(visibility, :collapsed?), do: "none"))
    |> maybe_put("--live-ui-visibility", if(fetch(visibility, :hidden?), do: "hidden"))
    |> maybe_put("--live-ui-opacity", serialize_opacity(fetch(visibility, :opacity)))
  end

  defp inline_style(css_vars) when css_vars == %{}, do: nil

  defp inline_style(css_vars) do
    css_vars
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join("; ", fn {key, value} -> "#{key}: #{value}" end)
  end

  defp infer_mode(css_vars, semantic_only_fields, unsupported_fields) do
    cond do
      map_size(css_vars) == 0 ->
        :semantic_only

      semantic_only_fields == [] and unsupported_fields == [] ->
        :realized

      true ->
        :mixed
    end
  end

  defp diagnostics(mode, semantic_only_fields, unsupported_fields, ignored_fields) do
    %{
      fallback: fallback_mode(mode),
      semantic_only_fields: semantic_only_fields,
      unsupported_fields: unsupported_fields,
      ignored_fields: ignored_fields
    }
  end

  defp fallback_mode(:semantic_only), do: :semantic_hooks
  defp fallback_mode(:mixed), do: :mixed
  defp fallback_mode(:realized), do: :realized_output

  defp fallback_label(mode), do: mode |> fallback_mode() |> Atom.to_string()

  defp text_realized?(%TextAttributes{} = text) do
    Enum.any?([
      fetch_flag(text, :bold?),
      fetch_flag(text, :dim?),
      fetch_flag(text, :italic?),
      fetch_flag(text, :underline?),
      fetch_flag(text, :hidden?),
      fetch_flag(text, :strikethrough?)
    ])
  end

  defp visibility_realized?(visibility) do
    visibility = normalize_map(visibility)

    fetch(visibility, :hidden?) || fetch(visibility, :collapsed?) || fetch(visibility, :opacity)
  end

  defp text_unsupported(%TextAttributes{} = text) do
    []
    |> maybe_append(fetch_flag(text, :blink?), "text.blink?")
    |> maybe_append(fetch_flag(text, :reverse?), "text.reverse?")
  end

  defp visibility_unsupported(visibility) do
    visibility = normalize_map(visibility)

    []
    |> maybe_append(fetch(visibility, :disabled?), "visibility.disabled?")
  end

  defp join_fields([]), do: nil
  defp join_fields(fields), do: Enum.map_join(fields, ",", &to_string/1)

  defp maybe_track_field(fields, value, field_name, predicate \\ &present?/1) do
    if predicate.(value), do: [field_name | fields], else: fields
  end

  defp maybe_append(values, truthy?, value) do
    if truthy?, do: [value | values], else: values
  end

  defp present?(nil), do: false
  defp present?(%{} = map), do: map != %{}
  defp present?(%TextAttributes{} = text), do: text != %TextAttributes{}
  defp present?(""), do: false
  defp present?(_value), do: true

  defp serialize_color(nil), do: nil

  defp serialize_color(%{mode: :rgb, red: red, green: green, blue: blue}),
    do: "rgb(#{red}, #{green}, #{blue})"

  defp serialize_color(%{mode: :indexed, index: index}), do: "var(--live-ui-color-index-#{index})"
  defp serialize_color(%{mode: :named, name: name}), do: to_string(name)
  defp serialize_color(value), do: to_string(value)

  defp serialize_spacing(value), do: serialize_length(value)
  defp serialize_size(value), do: serialize_length(value)
  defp serialize_radius(:full), do: "9999px"
  defp serialize_radius(value), do: serialize_length(value)

  defp serialize_length(nil), do: nil
  defp serialize_length(value) when is_integer(value), do: "#{value}px"
  defp serialize_length(value) when is_float(value), do: "#{value}px"

  defp serialize_length(value) when is_binary(value) do
    case String.trim(value) do
      "none" -> "0"
      "hairline" -> "0.5px"
      "thin" -> "1px"
      "sm" -> "0.5rem"
      "md" -> "0.75rem"
      "lg" -> "1rem"
      "xl" -> "1.5rem"
      "xxl" -> "2rem"
      "full" -> "100%"
      trimmed -> trimmed
    end
  end

  defp serialize_length(value) when is_atom(value) do
    case value do
      :none -> "0"
      :hairline -> "0.5px"
      :thin -> "1px"
      :sm -> "0.5rem"
      :md -> "0.75rem"
      :lg -> "1rem"
      :xl -> "1.5rem"
      :xxl -> "2rem"
      :full -> "100%"
      _other -> Atom.to_string(value)
    end
  end

  defp serialize_border_style(nil), do: nil
  defp serialize_border_style(value) when is_atom(value), do: Atom.to_string(value)
  defp serialize_border_style(value), do: to_string(value)

  defp serialize_align(nil), do: nil
  defp serialize_align(:start), do: "flex-start"
  defp serialize_align(:end), do: "flex-end"
  defp serialize_align(value) when is_atom(value), do: Atom.to_string(value)

  defp serialize_align(value) when is_binary(value) do
    case String.trim(value) do
      "start" -> "flex-start"
      "end" -> "flex-end"
      trimmed -> trimmed
    end
  end

  defp serialize_justify(nil), do: nil
  defp serialize_justify(:start), do: "flex-start"
  defp serialize_justify(:end), do: "flex-end"
  defp serialize_justify(:between), do: "space-between"
  defp serialize_justify(:around), do: "space-around"
  defp serialize_justify(:evenly), do: "space-evenly"
  defp serialize_justify(value) when is_atom(value), do: Atom.to_string(value)

  defp serialize_justify(value) when is_binary(value) do
    case String.trim(value) do
      "start" -> "flex-start"
      "end" -> "flex-end"
      "between" -> "space-between"
      "around" -> "space-around"
      "evenly" -> "space-evenly"
      trimmed -> trimmed
    end
  end

  defp serialize_text_align(nil), do: nil
  defp serialize_text_align(value) when is_atom(value), do: Atom.to_string(value)
  defp serialize_text_align(value), do: to_string(value)

  defp serialize_opacity(nil), do: nil
  defp serialize_opacity(value) when is_number(value), do: to_string(value)
  defp serialize_opacity(value), do: to_string(value)

  defp normalize_string_map(nil), do: %{}

  defp normalize_string_map(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_string_map(_other), do: %{}

  defp normalize_atom_fields(fields) do
    fields
    |> List.wrap()
    |> Enum.map(&normalize_field_atom/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_diagnostics(fields) do
    fields
    |> List.wrap()
    |> Enum.map(fn
      field when is_atom(field) -> field
      field when is_binary(field) -> field
      field -> to_string(field)
    end)
    |> Enum.uniq()
  end

  defp normalize_diagnostics_map(map, semantic_only_fields, unsupported_fields)
       when is_map(map) do
    %{
      fallback:
        map
        |> fetch(:fallback, :semantic_hooks)
        |> normalize_fallback(),
      semantic_only_fields:
        map
        |> fetch(:semantic_only_fields, semantic_only_fields)
        |> normalize_atom_fields(),
      unsupported_fields:
        map
        |> fetch(:unsupported_fields, unsupported_fields)
        |> normalize_diagnostics(),
      ignored_fields:
        map
        |> fetch(:ignored_fields, [])
        |> normalize_diagnostics()
    }
  end

  defp normalize_diagnostics_map(_other, semantic_only_fields, unsupported_fields) do
    %{
      fallback: :semantic_hooks,
      semantic_only_fields: normalize_atom_fields(semantic_only_fields),
      unsupported_fields: normalize_diagnostics(unsupported_fields),
      ignored_fields: []
    }
  end

  defp normalize_precedence(precedence) do
    precedence
    |> List.wrap()
    |> Enum.map(&normalize_precedence_stage/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> @default_precedence
      normalized -> normalized
    end
  end

  defp normalize_precedence_stage(stage) when stage in @default_precedence, do: stage

  defp normalize_precedence_stage(stage) when is_binary(stage) do
    stage
    |> String.to_atom()
    |> normalize_precedence_stage()
  rescue
    ArgumentError -> nil
  end

  defp normalize_precedence_stage(_other), do: nil

  defp normalize_mode(mode) when mode in [:semantic_only, :mixed, :realized], do: mode

  defp normalize_mode(mode) when is_binary(mode) do
    mode
    |> String.to_existing_atom()
    |> normalize_mode()
  rescue
    ArgumentError -> :semantic_only
  end

  defp normalize_mode(_other), do: :semantic_only

  defp normalize_fallback(value)
       when value in [:semantic_hooks, :mixed, :realized_output],
       do: value

  defp normalize_fallback(value) when is_binary(value) do
    value
    |> String.to_existing_atom()
    |> normalize_fallback()
  rescue
    ArgumentError -> :semantic_hooks
  end

  defp normalize_fallback(_other), do: :semantic_hooks

  defp normalize_field_atom(field) when is_atom(field), do: field

  defp normalize_field_atom(field) when is_binary(field) do
    try do
      String.to_existing_atom(field)
    rescue
      ArgumentError -> nil
    end
  end

  defp normalize_field_atom(_other), do: nil

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp fetch_flag(text, key), do: Map.get(text, key, false)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
