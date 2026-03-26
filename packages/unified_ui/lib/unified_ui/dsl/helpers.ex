defmodule UnifiedUi.Dsl.Helpers do
  @moduledoc """
  Author-facing helpers for building canonical authored metadata values.
  """

  alias UnifiedIUR.Style.Color
  alias UnifiedIUR.Token
  alias UnifiedUi.Binding
  alias UnifiedUi.Style

  @spec annotation_map(keyword() | map() | nil) :: map()
  def annotation_map(nil), do: %{}
  def annotation_map(values) when is_list(values), do: Map.new(values)
  def annotation_map(values) when is_map(values), do: Map.new(values)

  @spec tag_list([atom() | String.t()] | nil) :: [atom() | String.t()]
  def tag_list(nil), do: []
  def tag_list(values) when is_list(values), do: values |> Enum.uniq() |> Enum.reject(&is_nil/1)

  @spec path_segments(atom() | String.t() | [atom() | String.t()] | nil) ::
          [atom() | String.t()]
  def path_segments(nil), do: []
  def path_segments(value) when is_atom(value) or is_binary(value), do: [value]
  def path_segments(values) when is_list(values), do: values

  @spec metadata(keyword() | map()) :: keyword()
  def metadata(values) when is_list(values), do: values
  def metadata(values) when is_map(values), do: Enum.into(values, [])

  @spec named_color(atom() | String.t()) :: Color.t()
  def named_color(name), do: Color.named(name)

  @spec indexed_color(non_neg_integer()) :: Color.t()
  def indexed_color(index), do: Color.indexed(index)

  @spec rgb_color(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: Color.t()
  def rgb_color(red, green, blue), do: Color.rgb(red, green, blue)

  @spec token_ref(Token.path_segment() | [Token.path_segment()]) :: Token.ref_t()
  def token_ref(path), do: Token.ref(path)

  @spec role_ref(atom() | String.t()) :: Style.role_ref_t()
  def role_ref(id), do: Style.role_ref(id)

  @spec style_value(keyword() | map() | Style.t() | nil) :: Style.t()
  def style_value(values \\ nil), do: Style.new(values)

  @spec binding_ref(atom() | String.t()) :: Binding.ref_t()
  def binding_ref(id), do: Binding.ref(id)
end
