defmodule UnifiedIUR.Attachment do
  @moduledoc """
  Canonical attachment normalization for style, theme, interaction, and binding
  metadata on `UnifiedIUR` elements.
  """

  alias UnifiedIUR.{Binding, Interaction, Style, Theme, Token}

  @type component_key :: atom() | String.t() | nil

  @spec merge(map(), keyword() | map(), keyword()) :: map()
  def merge(attributes, opts, attach_opts \\ []) do
    attributes = normalize_map(attributes)
    opts = normalize_map(opts)

    validate_attachment_inputs!(opts)

    attributes
    |> maybe_put(:style, normalize_local_style(opts, attach_opts))
    |> maybe_put(:theme, normalize_theme(opts, attach_opts))
    |> maybe_put(:interactions, normalize_interactions(opts, attach_opts))
    |> maybe_put(:bindings, normalize_bindings(opts, attach_opts))
    |> maybe_put(:interaction_scope, normalize_interaction_scope(opts))
  end

  defp normalize_local_style(opts, attach_opts) do
    base_style =
      case Keyword.fetch(attach_opts, :local_style) do
        {:ok, style} -> style
        :error -> fetch(opts, :style)
      end

    tone =
      case Keyword.fetch(attach_opts, :tone) do
        {:ok, value} -> value
        :error -> fetch(opts, :tone)
      end

    style =
      base_style
      |> normalize_style_source()
      |> maybe_put_nested(:emphasis, :tone, tone)
      |> Style.new()

    if empty_style?(style), do: nil, else: style
  end

  defp normalize_theme(opts, attach_opts) do
    component = Keyword.get(attach_opts, :component)

    theme_source =
      case fetch(opts, :theme) do
        nil -> %{}
        %Theme{id: id} -> %{id: id}
        value when is_atom(value) or is_binary(value) -> %{id: value}
        value when is_list(value) -> Enum.into(value, %{})
        value when is_map(value) -> Map.new(value)
      end

    token_refs =
      theme_source
      |> fetch(:token_refs, fetch(opts, :token_refs, fetch(opts, :style_refs, [])))
      |> normalize_token_refs()

    base_theme_attachment =
      %{}
      |> maybe_put(:id, fetch(opts, :theme_id, fetch(theme_source, :id)))
      |> maybe_put(:variant, fetch(theme_source, :variant, fetch(opts, :variant)))
      |> maybe_put(:state, fetch(theme_source, :state, fetch(opts, :state)))
      |> maybe_put(:inherit?, fetch(theme_source, :inherit?, fetch(opts, :inherit_style?)))
      |> maybe_put(:token_refs, if(token_refs == [], do: nil, else: token_refs))

    theme_attachment =
      if base_theme_attachment == %{} do
        %{}
      else
        maybe_put(base_theme_attachment, :component, fetch(theme_source, :component, component))
      end

    if theme_attachment == %{}, do: nil, else: theme_attachment
  end

  defp normalize_interactions(opts, attach_opts) do
    explicit_interaction = fetch_marker(opts, :interaction)
    explicit_interactions = fetch_marker(opts, :interactions)
    fallback_interactions = Keyword.get(attach_opts, :fallback_interactions, [])

    interactions =
      cond do
        explicit_interactions != :missing -> List.wrap(explicit_interactions)
        explicit_interaction != :missing -> [explicit_interaction]
        true -> List.wrap(fallback_interactions)
      end
      |> Enum.reject(&empty_value?/1)
      |> Enum.map(&Interaction.new/1)

    if interactions == [], do: nil, else: interactions
  end

  defp normalize_bindings(opts, attach_opts) do
    explicit_binding = fetch_marker(opts, :binding)
    explicit_bindings = fetch_marker(opts, :bindings)
    fallback_bindings = Keyword.get(attach_opts, :fallback_bindings, [])

    bindings =
      cond do
        explicit_bindings != :missing -> List.wrap(explicit_bindings)
        explicit_binding != :missing -> [explicit_binding]
        true -> List.wrap(fallback_bindings)
      end
      |> Enum.reject(&empty_value?/1)
      |> Enum.map(&Binding.new/1)

    if bindings == [], do: nil, else: bindings
  end

  defp normalize_interaction_scope(opts) do
    opts
    |> fetch(:interaction_scope)
    |> normalize_map()
    |> maybe_put(:mode, fetch(opts, :interaction_scope_mode))
    |> maybe_put(:namespace, fetch(opts, :interaction_scope_namespace))
    |> maybe_put(
      :target_path,
      normalize_optional_path(fetch(opts, :interaction_scope_target_path))
    )
    |> maybe_put(:inherit?, fetch(opts, :interaction_scope_inherit?))
    |> case do
      %{} = scope when map_size(scope) == 0 -> nil
      scope -> scope
    end
  end

  defp validate_attachment_inputs!(opts) do
    if fetch_marker(opts, :binding) != :missing and fetch_marker(opts, :bindings) != :missing do
      raise ArgumentError, "binding and bindings cannot both be provided for one element"
    end

    if fetch_marker(opts, :interaction) != :missing and
         fetch_marker(opts, :interactions) != :missing do
      raise ArgumentError, "interaction and interactions cannot both be provided for one element"
    end
  end

  defp normalize_style_source(nil), do: %{}

  defp normalize_style_source(%Style{} = style) do
    style
  end

  defp normalize_style_source(style) when is_list(style) do
    style
    |> Enum.into(%{})
    |> normalize_style_source()
  end

  defp normalize_style_source(style) when is_map(style) do
    style
    |> Map.new()
    |> Map.drop([
      :style_refs,
      "style_refs",
      :token_refs,
      "token_refs",
      :variant,
      "variant",
      :theme,
      "theme",
      :theme_id,
      "theme_id"
    ])
    |> move_embedded_tone()
  end

  defp normalize_token_refs(nil), do: []

  defp normalize_token_refs(token_refs) do
    token_refs
    |> List.wrap()
    |> Enum.reject(&empty_value?/1)
    |> Enum.map(fn value ->
      case Token.new(value) do
        nil -> nil
        reference -> reference
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_optional_path(nil), do: nil
  defp normalize_optional_path(path) when is_atom(path) or is_binary(path), do: [path]
  defp normalize_optional_path(path) when is_list(path), do: path

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp fetch_marker(source, key) do
    cond do
      Map.has_key?(source, key) -> Map.get(source, key)
      Map.has_key?(source, Atom.to_string(key)) -> Map.get(source, Atom.to_string(key))
      true -> :missing
    end
  end

  defp empty_style?(%Style{} = style), do: style == %Style{}

  defp empty_value?(nil), do: true
  defp empty_value?(%{} = value), do: map_size(value) == 0
  defp empty_value?([]), do: true
  defp empty_value?(_value), do: false

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_nested(map, _outer_key, _inner_key, nil), do: map

  defp maybe_put_nested(map, outer_key, inner_key, value) do
    Map.update(
      map,
      outer_key,
      %{inner_key => value},
      &Map.put(normalize_map(&1), inner_key, value)
    )
  end

  defp move_embedded_tone(style_map) do
    tone = fetch(style_map, :tone)

    style_map
    |> Map.drop([:tone, "tone"])
    |> maybe_put_nested(:emphasis, :tone, tone)
  end
end
