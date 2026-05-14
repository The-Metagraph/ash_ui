defmodule DesktopUi.Style do
  @moduledoc """
  Native styling primitives and normalization helpers for `desktop_ui`.
  """

  @colors [
    :canvas,
    :surface,
    :content,
    :muted,
    :accent,
    :info,
    :success,
    :warning,
    :danger,
    :selection,
    :focus_ring
  ]
  @text_attributes [:bold, :italic, :underline, :strikethrough, :monospace, :uppercase]
  @semantic_roles [
    :title,
    :body,
    :label,
    :caption,
    :window_chrome,
    :primary_action,
    :secondary_action,
    :status_info,
    :status_warning,
    :status_danger,
    :selection
  ]
  @variants [:default, :quiet, :accented, :outlined, :filled, :dense, :elevated, :panel]
  @padding [:none, :xs, :sm, :md, :lg]
  @borders [:none, :hairline, :single, :double, :focus_ring]
  @state_variants [:focused, :disabled, :selected, :active, :open, :loading, :current]

  @primitive_keys [
    :theme,
    :variant,
    :fg,
    :bg,
    :attrs,
    :padding,
    :border,
    :semantic_role,
    :tone,
    :weight,
    :elevation,
    :intent
  ]
  @portable_keys @primitive_keys ++ [:style_refs, :theme_tokens, :state_variants]

  @spec primitives() :: map()
  def primitives do
    %{
      colors: @colors,
      text_attributes: @text_attributes,
      semantic_roles: @semantic_roles,
      variants: @variants,
      padding: @padding,
      borders: @borders
    }
  end

  @spec portable_keys() :: [atom()]
  def portable_keys, do: @portable_keys

  @spec widget_style_hooks() :: [atom()]
  def widget_style_hooks do
    [:variant, :semantic_role, :theme_tokens, :state_variants, :intent, :style_refs]
  end

  @spec state_variant_keys() :: [atom()]
  def state_variant_keys, do: @state_variants

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :native_style_primitives,
      :component_variants,
      :semantic_role_mapping,
      :shared_native_and_canonical_style_model
    ]
  end

  @spec validation_state() :: map()
  def validation_state do
    %{
      primitive_surface: :ready,
      component_variants: :ready,
      direct_native_surface: :ready
    }
  end

  @spec normalize(keyword() | map()) :: map()
  def normalize(attrs) when is_map(attrs) or is_list(attrs) do
    attrs
    |> normalize_map()
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      normalized_key = normalize_key(key)

      cond do
        normalized_key == :attrs ->
          Map.put(acc, :attrs, normalize_attrs(value))

        normalized_key == :style_refs ->
          Map.put(acc, :style_refs, normalize_list(value))

        normalized_key == :theme_tokens ->
          Map.put(acc, :theme_tokens, normalize_map(value))

        normalized_key == :state_variants ->
          Map.put(acc, :state_variants, normalize_state_variants(value))

        normalized_key in @portable_keys ->
          Map.put(acc, normalized_key, value)

        true ->
          acc
      end
    end)
    |> compact_map()
  end

  defp normalize_state_variants(value) when is_map(value) or is_list(value) do
    value
    |> normalize_map()
    |> Enum.reduce(%{}, fn {state, styles}, acc ->
      state = normalize_key(state)

      if state in @state_variants do
        Map.put(acc, state, normalize(styles))
      else
        acc
      end
    end)
  end

  defp normalize_state_variants(_value), do: %{}

  defp normalize_attrs(value) when is_list(value) do
    value
    |> Enum.map(&normalize_key/1)
    |> Enum.uniq()
  end

  defp normalize_attrs(nil), do: []
  defp normalize_attrs(value), do: [normalize_key(value)]

  defp normalize_list(value) when is_list(value) do
    value
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_key/1)
  end

  defp normalize_list(nil), do: []
  defp normalize_list(value), do: [normalize_key(value)]

  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end
end
