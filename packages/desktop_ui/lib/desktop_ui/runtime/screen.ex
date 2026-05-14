defmodule DesktopUi.Runtime.Screen do
  @moduledoc """
  Foundational screen composition model shared by native and canonical runtime
  paths.
  """

  alias DesktopUi.Runtime.State
  alias DesktopUi.Widget

  @enforce_keys [:id, :source_kind, :platform_target, :root]
  defstruct [
    :id,
    :title,
    :source_kind,
    :platform_target,
    :root,
    metadata: %{},
    composition: %{},
    bindings: %{},
    focus: %{},
    realization: %{}
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          source_kind: State.source_kind(),
          platform_target: atom(),
          root: Widget.t(),
          metadata: map(),
          composition: map(),
          bindings: map(),
          focus: map(),
          realization: map()
        }

  @spec new(map(), State.source_kind(), keyword()) :: t()
  def new(screen, source_kind, opts \\ []) do
    root = Map.fetch!(screen, :root)
    theme = Keyword.get(opts, :theme, Map.get(screen, :theme, infer_theme(root)))

    %__MODULE__{
      id: screen |> Map.fetch!(:id) |> to_string(),
      title: Map.get(screen, :title, "Screen"),
      source_kind: source_kind,
      platform_target: Keyword.get(opts, :platform_target, :linux),
      root: root,
      metadata: %{
        shared_runtime: true,
        direct_native: source_kind == :native,
        canonical_input: source_kind == :canonical,
        runtime_foundation: :sdl3,
        theme: theme
      },
      composition: %{
        root_kind: root.kind,
        layout_kinds: collect_layout_kinds(root),
        layer_kinds: collect_layer_kinds(root),
        window_count: count_windows(root),
        widget_count: count_widgets(root),
        shared_realization: true
      },
      bindings: %{
        names: collect_bindings(root),
        shared_runtime_surface: true
      },
      focus: %{
        focusable_ids: collect_focusable_ids(root),
        traversal_model: :preorder
      },
      realization: %{
        root_kind: root.kind,
        uses_window_registry: true,
        redraw_model: :shared_sdl_runtime,
        foundational_layout_realization: true,
        theme: theme
      }
    }
  end

  defp infer_theme(%Widget{styles: styles}) when is_map(styles) do
    Map.get(styles, :theme, DesktopUi.Theme.default_theme().id)
  end

  defp collect_layout_kinds(root) do
    root
    |> flatten_widgets([])
    |> Enum.map(& &1.kind)
    |> Enum.filter(
      &(&1 in ([:window, :dialog, :content, :column, :row, :stack] ++ DesktopUi.Layout.kinds()))
    )
    |> Enum.uniq()
  end

  defp collect_layer_kinds(root) do
    root
    |> flatten_widgets([])
    |> Enum.map(& &1.kind)
    |> Enum.filter(&(&1 in DesktopUi.Layer.kinds()))
    |> Enum.uniq()
  end

  defp collect_bindings(root) do
    root
    |> flatten_widgets([])
    |> Enum.flat_map(fn widget ->
      widget.bindings
      |> Map.values()
      |> Enum.reject(&is_nil/1)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp collect_focusable_ids(root) do
    root
    |> flatten_widgets([])
    |> Enum.filter(fn widget ->
      Map.get(widget.metadata, :focusable, false) and !Map.get(widget.state, :disabled, false)
    end)
    |> Enum.map(&to_string(&1.id))
  end

  defp count_widgets(root) do
    root |> flatten_widgets([]) |> length()
  end

  defp count_windows(root) do
    root
    |> flatten_widgets([])
    |> Enum.count(&(&1.kind == :window))
  end

  defp flatten_widgets(widget, acc) do
    Enum.reduce(widget.children, acc ++ [widget], &flatten_widgets(&1, &2))
  end
end
