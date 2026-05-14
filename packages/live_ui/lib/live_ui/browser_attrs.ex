defmodule LiveUi.BrowserAttrs do
  @moduledoc """
  Small helpers for merging browser-facing widget attrs and CSS variable output.
  """

  @spec merge(map() | keyword() | nil, map() | keyword() | nil) :: map()
  def merge(left, right) do
    normalize_attrs(left)
    |> Map.merge(normalize_attrs(right), fn
      "style", left_value, right_value -> merge_styles(left_value, right_value)
      _key, _left_value, right_value -> right_value
    end)
  end

  @spec from_css_vars(map()) :: map()
  def from_css_vars(css_vars) when css_vars == %{}, do: %{}

  def from_css_vars(css_vars) when is_map(css_vars) do
    case style_string(css_vars) do
      nil -> %{}
      style -> %{"style" => style}
    end
  end

  @spec put_css_vars(map() | keyword() | nil, map()) :: map()
  def put_css_vars(attrs, css_vars) do
    merge(from_css_vars(css_vars), attrs)
  end

  @spec style_string(map()) :: String.t() | nil
  def style_string(css_vars) when css_vars == %{}, do: nil

  def style_string(css_vars) when is_map(css_vars) do
    css_vars
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map_join("; ", fn {key, value} -> "#{key}: #{value}" end)
    |> case do
      "" -> nil
      style -> style
    end
  end

  defp normalize_attrs(nil), do: %{}
  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &stringify_pair/1)
  defp normalize_attrs(attrs) when is_list(attrs), do: Enum.into(attrs, %{}, &stringify_pair/1)
  defp normalize_attrs(_other), do: %{}

  defp stringify_pair({key, value}), do: {to_string(key), to_string(value)}

  defp merge_styles(left, right) do
    [left, right]
    |> Enum.map(&normalize_style/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("; ")
    |> normalize_style()
  end

  defp normalize_style(nil), do: nil
  defp normalize_style(""), do: nil

  defp normalize_style(value) do
    value
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      style -> style
    end
  end
end
