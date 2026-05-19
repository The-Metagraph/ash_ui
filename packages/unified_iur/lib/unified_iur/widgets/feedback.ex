defmodule UnifiedIUR.Widgets.Feedback do
  @moduledoc """
  Canonical constructors for baseline feedback, status, and progress widgets in
  `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [:status, :progress, :gauge, :inline_feedback, :diff_banner, :confidence_indicator]
  @diff_filters [:all, :new, :changed, :removed]
  @diff_sizes [:default, :compact]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec status(String.t(), keyword() | map()) :: Element.t()
  def status(text, opts \\ []) when is_binary(text) do
    opts = normalize_opts(opts)

    Element.new(:widget, :status,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          feedback:
            %{}
            |> maybe_put(:text, text)
            |> maybe_put(:severity, option(opts, :severity, :info))
            |> maybe_put(:status, option(opts, :status, :idle))
        }
        |> Attachment.merge(opts, component: :status),
      children: []
    )
  end

  @spec progress(keyword() | map()) :: Element.t()
  def progress(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :progress,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          progress:
            %{}
            |> maybe_put(:current, option(opts, :current))
            |> maybe_put(:total, option(opts, :total))
            |> maybe_put(:indeterminate?, option(opts, :indeterminate?, false))
            |> maybe_put(:label, option(opts, :label)),
          feedback:
            %{}
            |> maybe_put(:severity, option(opts, :severity))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :progress),
      children: []
    )
  end

  @spec gauge(keyword() | map()) :: Element.t()
  def gauge(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :gauge,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          gauge:
            %{}
            |> maybe_put(:value, option(opts, :value))
            |> maybe_put(:min, option(opts, :min, 0))
            |> maybe_put(:max, option(opts, :max, 100))
            |> maybe_put(:label, option(opts, :label)),
          feedback:
            %{}
            |> maybe_put(:severity, option(opts, :severity))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :gauge),
      children: []
    )
  end

  @spec inline_feedback(String.t(), keyword() | map()) :: Element.t()
  def inline_feedback(message, opts \\ []) when is_binary(message) do
    opts = normalize_opts(opts)

    Element.new(:widget, :inline_feedback,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          feedback:
            %{}
            |> maybe_put(:title, option(opts, :title))
            |> maybe_put(:message, message)
            |> maybe_put(:severity, option(opts, :severity, :info))
            |> maybe_put(:status, option(opts, :status))
        }
        |> Attachment.merge(opts, component: :inline_feedback),
      children: []
    )
  end

  @spec diff_banner(keyword() | map()) :: Element.t()
  def diff_banner(opts \\ []) do
    opts = normalize_opts(opts)

    Element.new(:widget, :diff_banner,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          diff:
            %{}
            |> Map.put(
              :new_count,
              normalize_non_negative_count!(option(opts, :new_count, 0), :new_count)
            )
            |> Map.put(
              :changed_count,
              normalize_non_negative_count!(option(opts, :changed_count, 0), :changed_count)
            )
            |> Map.put(
              :removed_count,
              normalize_non_negative_count!(option(opts, :removed_count, 0), :removed_count)
            )
            |> Map.put(:active_filter, normalize_diff_filter!(option(opts, :active_filter, :all)))
            |> Map.put(:show_filter_chips?, option(opts, :show_filter_chips?, true))
            |> Map.put(:size, normalize_diff_size!(option(opts, :size, :default)))
            |> maybe_put(:base_label, option(opts, :base_label))
            |> maybe_put(
              :filter_intent,
              option(opts, :filter_intent, option(opts, :selection_intent))
            )
        }
        |> Attachment.merge(opts, component: :diff_banner),
      children: []
    )
  end

  @spec confidence_indicator(number(), keyword() | map()) :: Element.t()
  def confidence_indicator(value, opts \\ []) when is_number(value) do
    opts = normalize_opts(opts)
    value = value / 1
    thresholds = normalize_thresholds!(option(opts, :thresholds, %{warn: 0.5, pass: 0.8}))
    size = normalize_size!(option(opts, :size, :medium))

    unless value >= 0.0 and value <= 1.0 do
      raise ArgumentError, "confidence_indicator :value must be in 0.0..1.0, got: #{value}"
    end

    Element.new(:widget, :confidence_indicator,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          confidence:
            %{}
            |> Map.put(:value, value)
            |> Map.put(:thresholds, thresholds)
            |> maybe_put(:label, option(opts, :label))
            |> Map.put(:show_numeric?, option(opts, :show_numeric?, true))
            |> Map.put(:show_glyph?, option(opts, :show_glyph?, true))
            |> Map.put(:size, size)
        }
        |> Attachment.merge(opts, component: :confidence_indicator),
      children: []
    )
  end

  defp normalize_metadata(opts) do
    opts
    |> option(:metadata)
    |> Metadata.merge(%{
      description: option(opts, :description),
      annotations: option(opts, :annotations, %{}),
      tags: option(opts, :tags, [])
    })
  end

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp normalize_non_negative_count!(value, _field) when is_integer(value) and value >= 0,
    do: value

  defp normalize_non_negative_count!(value, field) do
    raise ArgumentError,
          "diff_banner :#{field} must be a non-negative integer, got: #{inspect(value)}"
  end

  defp normalize_diff_filter!(value) when value in @diff_filters, do: value

  defp normalize_diff_filter!(value) when is_binary(value) do
    value
    |> String.to_existing_atom()
    |> normalize_diff_filter!()
  rescue
    ArgumentError ->
      raise ArgumentError,
            "diff_banner :active_filter must be one of #{inspect(@diff_filters)}, got: #{inspect(value)}"
  end

  defp normalize_diff_filter!(value) do
    raise ArgumentError,
          "diff_banner :active_filter must be one of #{inspect(@diff_filters)}, got: #{inspect(value)}"
  end

  defp normalize_diff_size!(value) when value in @diff_sizes, do: value

  defp normalize_diff_size!(value) when is_binary(value) do
    value
    |> String.to_existing_atom()
    |> normalize_diff_size!()
  rescue
    ArgumentError ->
      raise ArgumentError,
            "diff_banner :size must be one of #{inspect(@diff_sizes)}, got: #{inspect(value)}"
  end

  defp normalize_diff_size!(value) do
    raise ArgumentError,
          "diff_banner :size must be one of #{inspect(@diff_sizes)}, got: #{inspect(value)}"
  end

  defp normalize_thresholds!(thresholds) when is_list(thresholds) do
    thresholds
    |> Enum.into(%{})
    |> normalize_thresholds!()
  end

  defp normalize_thresholds!(thresholds) when is_map(thresholds) do
    warn = option(thresholds, :warn)
    pass = option(thresholds, :pass)

    unless is_number(warn) and is_number(pass) do
      raise ArgumentError,
            "confidence_indicator :thresholds must have numeric :warn and :pass keys"
    end

    warn = warn / 1
    pass = pass / 1

    unless warn >= 0.0 and warn <= 1.0 and pass >= 0.0 and pass <= 1.0 do
      raise ArgumentError, "confidence_indicator :thresholds values must be in 0.0..1.0"
    end

    unless warn < pass do
      raise ArgumentError,
            "confidence_indicator :thresholds.warn must be less than :thresholds.pass"
    end

    %{warn: warn, pass: pass}
  end

  defp normalize_thresholds!(_thresholds) do
    raise ArgumentError, "confidence_indicator :thresholds must be a map"
  end

  defp normalize_size!(size) when size in [:small, :medium, :large], do: size

  defp normalize_size!(size) when size in ["small", "medium", "large"] do
    String.to_existing_atom(size)
  end

  defp normalize_size!(size) do
    raise ArgumentError,
          "confidence_indicator :size must be one of :small, :medium, :large, got: #{inspect(size)}"
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
