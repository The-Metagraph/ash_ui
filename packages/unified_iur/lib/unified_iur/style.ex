defmodule UnifiedIUR.Style do
  @moduledoc """
  Canonical renderer-independent style values for `UnifiedIUR`.
  """

  alias UnifiedIUR.Style.{Color, TextAttributes}

  @type state_key :: :default | :focused | :selected | :disabled | :active | atom() | String.t()
  @type scalar_or_map :: term()

  @type t :: %__MODULE__{
          foreground: Color.t() | nil,
          background: Color.t() | nil,
          border_color: Color.t() | nil,
          text: TextAttributes.t(),
          spacing: map(),
          sizing: map(),
          alignment: map(),
          visibility: map(),
          border: map(),
          emphasis: map(),
          state_variants: %{optional(state_key()) => t()},
          extra: map()
        }

  defstruct foreground: nil,
            background: nil,
            border_color: nil,
            text: %TextAttributes{},
            spacing: %{},
            sizing: %{},
            alignment: %{},
            visibility: %{},
            border: %{},
            emphasis: %{},
            state_variants: %{},
            extra: %{}

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}

  def new(%__MODULE__{} = style) do
    %__MODULE__{
      foreground: Color.new(style.foreground),
      background: Color.new(style.background),
      border_color: Color.new(style.border_color),
      text: TextAttributes.new(style.text),
      spacing: normalize_map(style.spacing),
      sizing: normalize_map(style.sizing),
      alignment: normalize_map(style.alignment),
      visibility: normalize_map(style.visibility),
      border: normalize_map(style.border),
      emphasis: normalize_map(style.emphasis),
      state_variants: normalize_variants(style.state_variants),
      extra: normalize_map(style.extra)
    }
  end

  def new(style) when is_list(style), do: style |> Enum.into(%{}) |> new()

  def new(style) when is_map(style) do
    %__MODULE__{
      foreground: style |> fetch(:foreground) |> Color.new(),
      background: style |> fetch(:background) |> Color.new(),
      border_color: style |> fetch(:border_color) |> Color.new(),
      text: style |> fetch(:text, %{}) |> TextAttributes.new(),
      spacing: style |> fetch(:spacing, %{}) |> normalize_map(),
      sizing: style |> fetch(:sizing, %{}) |> normalize_map(),
      alignment: style |> fetch(:alignment, %{}) |> normalize_map(),
      visibility: style |> fetch(:visibility, %{}) |> normalize_map(),
      border: style |> fetch(:border, %{}) |> normalize_map(),
      emphasis: style |> fetch(:emphasis, %{}) |> normalize_map(),
      state_variants: style |> fetch(:state_variants, %{}) |> normalize_variants(),
      extra: style |> fetch(:extra, %{}) |> normalize_map()
    }
  end

  @spec merge(t() | keyword() | map() | nil, t() | keyword() | map() | nil) :: t()
  def merge(left, right) do
    left = new(left)
    right = new(right)

    %__MODULE__{
      foreground: right.foreground || left.foreground,
      background: right.background || left.background,
      border_color: right.border_color || left.border_color,
      text: TextAttributes.merge(left.text, right.text),
      spacing: Map.merge(left.spacing, right.spacing),
      sizing: Map.merge(left.sizing, right.sizing),
      alignment: Map.merge(left.alignment, right.alignment),
      visibility: Map.merge(left.visibility, right.visibility),
      border: Map.merge(left.border, right.border),
      emphasis: Map.merge(left.emphasis, right.emphasis),
      state_variants: merge_variants(left.state_variants, right.state_variants),
      extra: Map.merge(left.extra, right.extra)
    }
  end

  @spec put_state_variant(t() | keyword() | map() | nil, state_key(), t() | keyword() | map()) ::
          t()
  def put_state_variant(style, state_key, variant) do
    style = new(style)
    variant = new(variant)

    %{style | state_variants: Map.put(style.state_variants, state_key, variant)}
  end

  @spec state_variant(t() | keyword() | map() | nil, state_key()) :: t() | nil
  def state_variant(style, state_key) do
    style
    |> new()
    |> Map.get(:state_variants)
    |> Map.get(state_key)
  end

  defp merge_variants(left, right) do
    Map.merge(left, right, fn _key, left_variant, right_variant ->
      merge(left_variant, right_variant)
    end)
  end

  defp normalize_variants(nil), do: %{}

  defp normalize_variants(variants) when is_map(variants) do
    variants
    |> Map.new(fn {key, value} -> {key, new(value)} end)
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
