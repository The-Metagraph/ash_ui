defmodule ElmUi.Style do
  @moduledoc """
  Native styling primitives and normalization helpers for `elm_ui`.
  """

  @typography [:display, :title, :body, :label, :caption, :code]
  @color_roles [:accent, :muted, :info, :success, :warning, :danger, :surface, :content]
  @spacing [:none, :xs, :sm, :md, :lg, :xl]
  @sizing [:xs, :sm, :md, :lg, :xl, :fill]
  @alignment [:start, :center, :end, :stretch, :between]
  @borders [:none, :subtle, :strong, :accent, :focus_ring]
  @backgrounds [:transparent, :canvas, :panel, :elevated, :scrim, :accent_tint]
  @visibility [:visible, :muted, :hidden]
  @emphasis [:normal, :subtle, :strong, :intense]
  @state_variants [:default, :focused, :disabled, :selected, :open, :editing, :loading, :current]

  @primitive_keys [
    :typography,
    :tone,
    :color_role,
    :size,
    :spacing,
    :align,
    :surface,
    :background,
    :border,
    :visibility,
    :emphasis
  ]

  @portable_keys @primitive_keys ++
                   [:hooks, :variant, :style_refs, :theme_tokens, :state_variants, :composition]

  @spec primitives() :: map()
  def primitives do
    %{
      typography: @typography,
      color_roles: @color_roles,
      spacing: @spacing,
      sizing: @sizing,
      alignment: @alignment,
      borders: @borders,
      backgrounds: @backgrounds,
      visibility: @visibility,
      emphasis: @emphasis
    }
  end

  @spec portable_keys() :: [atom()]
  def portable_keys, do: @portable_keys

  @spec widget_style_hooks() :: [atom()]
  def widget_style_hooks do
    [:variant, :tone, :state_variants, :composition, :style_refs, :theme_tokens]
  end

  @spec state_variant_keys() :: [atom()]
  def state_variant_keys, do: @state_variants

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :native_style_primitives,
      :portable_style_meaning,
      :state_variant_hooks,
      :theme_token_references
    ]
  end

  @spec normalize(keyword() | map()) :: map()
  def normalize(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_map(attrs)

    attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      normalized_key = normalize_key(key)

      cond do
        normalized_key == :hooks ->
          Map.put(acc, :hooks, normalize_hooks(value))

        normalized_key == :style_refs ->
          Map.put(acc, :style_refs, normalize_refs(value))

        normalized_key == :theme_tokens ->
          Map.put(acc, :theme_tokens, normalize_map(value))

        normalized_key == :state_variants ->
          Map.put(acc, :state_variants, normalize_state_variants(value))

        normalized_key == :composition ->
          Map.put(acc, :composition, normalize_map(value))

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

  defp normalize_refs(value) when is_list(value), do: Enum.reject(value, &is_nil/1)
  defp normalize_refs(nil), do: []
  defp normalize_refs(value), do: [value]

  defp normalize_hooks(value) when is_list(value) do
    value
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_key/1)
  end

  defp normalize_hooks(nil), do: []
  defp normalize_hooks(value), do: [normalize_key(value)]

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
