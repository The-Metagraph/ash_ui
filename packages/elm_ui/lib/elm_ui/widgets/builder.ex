defmodule ElmUi.Widgets.Builder do
  @moduledoc false

  alias ElmUi.{Widget, Widgets}

  @type opts :: keyword() | map()

  @spec options(opts()) :: map()
  def options(opts) when is_list(opts), do: Enum.into(opts, %{})
  def options(opts) when is_map(opts), do: Map.new(opts)

  @spec require_id!(map(), atom()) :: String.t() | atom()
  def require_id!(opts, kind) do
    case option(opts, :id) do
      nil -> raise ArgumentError, "elm_ui #{inspect(kind)} widgets require an :id"
      id -> id
    end
  end

  @spec widget(atom(), keyword() | map()) :: Widget.t()
  def widget(kind, attrs), do: Widgets.widget(kind, attrs)

  @spec child!(Widget.t() | map() | keyword()) :: Widget.t()
  def child!(%Widget{} = widget), do: widget

  def child!(input) when is_map(input) or is_list(input) do
    case Widgets.normalize(input) do
      {:ok, widget} -> widget
      {:error, reason} -> raise ArgumentError, "invalid nested elm_ui widget: #{inspect(reason)}"
    end
  end

  @spec children!(nil | [Widget.t() | map() | keyword()]) :: [Widget.t()]
  def children!(nil), do: []

  def children!(children) when is_list(children) do
    case Widgets.normalize_many(children) do
      {:ok, widgets} -> widgets
      {:error, reason} -> raise ArgumentError, "invalid nested elm_ui widgets: #{inspect(reason)}"
    end
  end

  @spec slot_map([
          {atom(), nil | Widget.t() | map() | keyword() | [Widget.t() | map() | keyword()]}
        ]) ::
          map()
  def slot_map(entries) when is_list(entries) do
    Enum.reduce(entries, %{}, fn {slot, value}, acc ->
      case normalize_slot_value(value) do
        [] -> acc
        widgets -> Map.put(acc, slot, widgets)
      end
    end)
  end

  @spec metadata(map(), map()) :: map()
  def metadata(opts, extras \\ %{}) do
    opts
    |> option(:metadata, %{})
    |> normalize_map()
    |> maybe_put(:description, option(opts, :description))
    |> maybe_put(:tags, option(opts, :tags))
    |> maybe_put(:annotations, option(opts, :annotations))
    |> maybe_put(:accessibility, accessibility(opts))
    |> Map.merge(extras)
    |> compact_map()
  end

  @spec state(map(), [atom()]) :: map()
  def state(opts, keys \\ [:disabled, :selected, :active, :pressed, :current, :focused]) do
    base =
      opts
      |> option(:state, %{})
      |> normalize_map()

    Enum.reduce(keys, base, fn key, acc ->
      maybe_put(acc, key, option(opts, key))
    end)
    |> compact_map()
  end

  @spec styles(map()) :: map()
  def styles(opts) do
    base_styles =
      opts
      |> option(:styles, %{})
      |> normalize_map()

    hooks =
      base_styles
      |> Map.get(:hooks, [])
      |> List.wrap()
      |> Kernel.++(
        opts
        |> option(:style_hooks, [])
        |> List.wrap()
        |> Enum.reject(&is_nil/1)
      )
      |> Enum.uniq()

    explicit =
      %{}
      |> maybe_put(:typography, option(opts, :typography))
      |> maybe_put(:tone, option(opts, :tone))
      |> maybe_put(:color_role, option(opts, :color_role))
      |> maybe_put(:size, option(opts, :size))
      |> maybe_put(:spacing, option(opts, :spacing))
      |> maybe_put(:align, option(opts, :align))
      |> maybe_put(:surface, option(opts, :surface))
      |> maybe_put(:background, option(opts, :background))
      |> maybe_put(:border, option(opts, :border))
      |> maybe_put(:visibility, option(opts, :visibility))
      |> maybe_put(:emphasis, option(opts, :emphasis))
      |> maybe_put(:variant, option(opts, :variant))
      |> maybe_put(:style_refs, option(opts, :style_refs))
      |> maybe_put(:theme_tokens, option(opts, :theme_tokens))
      |> maybe_put(:state_variants, option(opts, :state_variants))
      |> maybe_put(:composition, option(opts, :composition))
      |> maybe_put(:hooks, hooks)
      |> compact_map()

    base_styles
    |> Map.merge(explicit)
    |> ElmUi.Style.normalize()
    |> compact_map()
  end

  @spec events(map(), keyword(atom())) :: map()
  def events(opts, shorthand \\ []) do
    base =
      opts
      |> option(:events, %{})
      |> normalize_map()

    shorthand
    |> Enum.reduce(base, fn {opt_key, event_name}, acc ->
      maybe_put(acc, event_name, option(opts, opt_key))
    end)
    |> compact_map()
  end

  @spec option(map(), atom(), term()) :: term()
  def option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  @spec maybe_put(map(), atom(), term()) :: map()
  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, _key, []), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  defp accessibility(opts) do
    %{}
    |> maybe_put(:label, option(opts, :accessibility_label))
    |> maybe_put(:description, option(opts, :accessibility_description))
    |> maybe_put(:role, option(opts, :accessibility_role))
    |> maybe_put(:controls, option(opts, :accessibility_controls))
    |> compact_map()
  end

  defp normalize_slot_value(nil), do: []
  defp normalize_slot_value(%Widget{} = widget), do: [widget]
  defp normalize_slot_value(list) when is_list(list), do: children!(list)
  defp normalize_slot_value(input) when is_map(input), do: [child!(input)]

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end
end
