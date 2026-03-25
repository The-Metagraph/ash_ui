defmodule UnifiedUi.Style do
  @moduledoc """
  Canonical authored style values for `UnifiedUi`.

  These values remain renderer-independent and are designed to lower into
  canonical `UnifiedIUR` styling during compilation.
  """

  alias UnifiedIUR.Style.Color
  alias UnifiedIUR.Token

  @type role_ref_t :: %{
          kind: :role_ref,
          id: atom() | String.t()
        }

  @type state_key :: :default | :focused | :selected | :disabled | :active | atom() | String.t()
  @type color_value :: Color.t() | Token.ref_t() | role_ref_t() | nil

  @attribute_families %{
    typography: [
      :font_family,
      :font_size,
      :font_weight,
      :italic?,
      :underline?,
      :blink?,
      :reverse?,
      :hidden?,
      :strikethrough?
    ],
    color: [:foreground, :background, :border_color, :role],
    spacing: [:padding, :padding_x, :padding_y, :margin, :margin_x, :margin_y, :gap],
    sizing: [:width, :height, :min_width, :min_height, :max_width, :max_height],
    alignment: [:align, :justify, :text_align, :anchor],
    border: [:width, :radius, :style, :color],
    visibility: [:hidden?, :collapsed?, :opacity],
    emphasis: [:weight, :intent, :elevation, :tone]
  }

  @semantic_roles [:success, :warning, :error, :info, :muted, :help, :placeholder]
  @component_states [:default, :focused, :selected, :disabled, :active]

  @type t :: %__MODULE__{
          theme_ref: atom() | String.t() | nil,
          component: atom() | String.t() | nil,
          variant: atom() | String.t() | nil,
          tone: atom() | String.t() | nil,
          token_refs: [Token.ref_t()],
          foreground: color_value(),
          background: color_value(),
          border_color: color_value(),
          typography: map(),
          spacing: map(),
          sizing: map(),
          alignment: map(),
          border: map(),
          visibility: map(),
          emphasis: map(),
          state_variants: %{optional(state_key()) => t()},
          inherit?: boolean(),
          metadata: map()
        }

  defstruct theme_ref: nil,
            component: nil,
            variant: nil,
            tone: nil,
            token_refs: [],
            foreground: nil,
            background: nil,
            border_color: nil,
            typography: %{},
            spacing: %{},
            sizing: %{},
            alignment: %{},
            border: %{},
            visibility: %{},
            emphasis: %{},
            state_variants: %{},
            inherit?: true,
            metadata: %{}

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: %__MODULE__{}
  def new(%__MODULE__{} = style), do: normalize(style)
  def new(style) when is_list(style), do: style |> Enum.into(%{}) |> new()

  def new(style) when is_map(style) do
    %__MODULE__{
      theme_ref: fetch(style, :theme_ref),
      component: fetch(style, :component),
      variant: fetch(style, :variant),
      tone: fetch(style, :tone),
      token_refs: fetch(style, :token_refs, []) |> normalize_token_refs(),
      foreground: style |> fetch(:foreground) |> normalize_color_value(),
      background: style |> fetch(:background) |> normalize_color_value(),
      border_color: style |> fetch(:border_color) |> normalize_color_value(),
      typography: style |> fetch(:typography, %{}) |> normalize_map(),
      spacing: style |> fetch(:spacing, %{}) |> normalize_map(),
      sizing: style |> fetch(:sizing, %{}) |> normalize_map(),
      alignment: style |> fetch(:alignment, %{}) |> normalize_map(),
      border: style |> fetch(:border, %{}) |> normalize_map(),
      visibility: style |> fetch(:visibility, %{}) |> normalize_map(),
      emphasis: style |> fetch(:emphasis, %{}) |> normalize_map(),
      state_variants: style |> fetch(:state_variants, %{}) |> normalize_state_variants(),
      inherit?: fetch(style, :inherit?, true),
      metadata: style |> fetch(:metadata, %{}) |> normalize_map()
    }
  end

  @spec merge(t() | keyword() | map() | nil, t() | keyword() | map() | nil) :: t()
  def merge(left, right) do
    left = new(left)
    right = new(right)

    %__MODULE__{
      theme_ref: right.theme_ref || left.theme_ref,
      component: right.component || left.component,
      variant: right.variant || left.variant,
      tone: right.tone || left.tone,
      token_refs: Enum.uniq(left.token_refs ++ right.token_refs),
      foreground: right.foreground || left.foreground,
      background: right.background || left.background,
      border_color: right.border_color || left.border_color,
      typography: Map.merge(left.typography, right.typography),
      spacing: Map.merge(left.spacing, right.spacing),
      sizing: Map.merge(left.sizing, right.sizing),
      alignment: Map.merge(left.alignment, right.alignment),
      border: Map.merge(left.border, right.border),
      visibility: Map.merge(left.visibility, right.visibility),
      emphasis: Map.merge(left.emphasis, right.emphasis),
      state_variants: merge_state_variants(left.state_variants, right.state_variants),
      inherit?: right.inherit?,
      metadata: Map.merge(left.metadata, right.metadata)
    }
  end

  @spec put_state_variant(t() | keyword() | map() | nil, state_key(), t() | keyword() | map()) ::
          t()
  def put_state_variant(style, state_key, variant) do
    style = new(style)
    variant = new(variant)

    %{style | state_variants: Map.put(style.state_variants, state_key, variant)}
  end

  @spec role_ref(atom() | String.t()) :: role_ref_t()
  def role_ref(id) when is_atom(id) or is_binary(id), do: %{kind: :role_ref, id: id}

  @spec role_reference?(term()) :: boolean()
  def role_reference?(%{kind: :role_ref, id: id}) when is_atom(id) or is_binary(id), do: true
  def role_reference?(_other), do: false

  @spec summary(t() | keyword() | map() | nil) :: map()
  def summary(style) do
    style = new(style)

    %{
      theme_ref: style.theme_ref,
      component: style.component,
      variant: style.variant,
      tone: style.tone,
      token_refs: style.token_refs,
      foreground: style.foreground,
      background: style.background,
      border_color: style.border_color,
      typography: style.typography,
      spacing: style.spacing,
      sizing: style.sizing,
      alignment: style.alignment,
      border: style.border,
      visibility: style.visibility,
      emphasis: style.emphasis,
      state_variants:
        style.state_variants
        |> Map.new(fn {state, variant} -> {state, summary(variant)} end),
      inherit?: style.inherit?,
      metadata: style.metadata
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Enum.into(%{})
  end

  @spec attribute_families() :: %{atom() => [atom()]}
  def attribute_families do
    @attribute_families
  end

  @spec semantic_roles() :: [atom()]
  def semantic_roles do
    @semantic_roles
  end

  @spec component_states() :: [atom()]
  def component_states do
    @component_states
  end

  defp normalize(%__MODULE__{} = style) do
    %__MODULE__{
      theme_ref: style.theme_ref,
      component: style.component,
      variant: style.variant,
      tone: style.tone,
      token_refs: normalize_token_refs(style.token_refs),
      foreground: normalize_color_value(style.foreground),
      background: normalize_color_value(style.background),
      border_color: normalize_color_value(style.border_color),
      typography: normalize_map(style.typography),
      spacing: normalize_map(style.spacing),
      sizing: normalize_map(style.sizing),
      alignment: normalize_map(style.alignment),
      border: normalize_map(style.border),
      visibility: normalize_map(style.visibility),
      emphasis: normalize_map(style.emphasis),
      state_variants: normalize_state_variants(style.state_variants),
      inherit?: style.inherit?,
      metadata: normalize_map(style.metadata)
    }
  end

  defp normalize_state_variants(nil), do: %{}

  defp normalize_state_variants(state_variants) when is_map(state_variants) do
    Map.new(state_variants, fn {key, variant} -> {key, new(variant)} end)
  end

  defp merge_state_variants(left, right) do
    Map.merge(left, right, fn _key, left_variant, right_variant ->
      merge(left_variant, right_variant)
    end)
  end

  defp normalize_token_refs(token_refs) do
    token_refs
    |> List.wrap()
    |> Enum.map(&Token.new/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_color_value(nil), do: nil

  defp normalize_color_value(value) do
    cond do
      role_reference?(value) ->
        role_ref(Map.get(value, :id, Map.get(value, "id")))

      token_reference_value?(value) ->
        Token.new(value)

      true ->
        Color.new(value)
    end
  end

  defp token_reference_value?(%{kind: :token_ref, path: path}) when is_list(path), do: true

  defp token_reference_value?(%{"kind" => :token_ref, "path" => path}) when is_list(path),
    do: true

  defp token_reference_value?(_other), do: false

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end
end
