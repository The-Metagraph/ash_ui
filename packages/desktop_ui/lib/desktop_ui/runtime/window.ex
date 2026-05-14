defmodule DesktopUi.Runtime.Window do
  @moduledoc """
  Window registration scaffold for `desktop_ui`.
  """

  alias DesktopUi.Runtime.Screen
  alias DesktopUi.Widget

  @spec register_all(Screen.t(), keyword()) :: map()
  def register_all(%Screen{} = screen, opts \\ []) do
    entries =
      case collect_windows(screen.root) do
        [] ->
          [{default_window_id(screen, opts), default_window(screen, opts)}]

        [%Widget{} = widget]
        when widget.id == screen.root.id and widget.kind == :window ->
          [{default_window_id(screen, opts), default_window(screen, opts)}]

        windows ->
          Enum.map(windows, fn widget ->
            window = register_widget(widget, screen)
            {window.id, window}
          end)
      end

    registry = Map.new(entries)
    ids = Enum.map(entries, &elem(&1, 0))

    %{
      primary: List.first(ids),
      secondary_ids: Enum.drop(ids, 1),
      registry: registry,
      continuity: if(length(ids) > 1, do: :multi_window, else: :single_window)
    }
  end

  @spec primary_focus_target(map()) :: String.t() | nil
  def primary_focus_target(window) when is_map(window) do
    window
    |> focus_order()
    |> List.first()
  end

  @spec focus_order(map()) :: [String.t()]
  def focus_order(%{focus_order: focus_order}) when is_list(focus_order), do: focus_order

  def focus_order(%DesktopUi.Widget{} = root) do
    root
    |> collect_focus_order([])
    |> Enum.uniq()
  end

  defp default_window_id(screen, opts) do
    Keyword.get(opts, :window_id, "window:#{screen.id}")
  end

  defp default_window(screen, opts) do
    %{
      id: default_window_id(screen, opts),
      title: screen.title,
      role: screen.root.kind,
      focus_order: focus_order(screen.root),
      platform_target: screen.platform_target,
      lifecycle: :registered,
      window_identity: screen.id
    }
  end

  defp register_widget(%Widget{} = widget, %Screen{} = screen) do
    %{
      id: "window:#{widget.id}",
      title: widget.attributes[:window_title] || screen.title,
      role: widget.kind,
      focus_order: focus_order(widget),
      platform_target: screen.platform_target,
      lifecycle: :registered,
      window_identity: Map.get(widget.metadata, :window_identity, widget.id)
    }
  end

  defp collect_windows(%Widget{kind: :multi_window, children: children}) do
    Enum.filter(children, &(&1.kind == :window))
  end

  defp collect_windows(%Widget{} = root) do
    root
    |> flatten_widgets([])
    |> Enum.filter(&(&1.kind == :window))
  end

  defp flatten_widgets(%Widget{} = widget, acc) do
    Enum.reduce(widget.children, acc ++ [widget], &flatten_widgets(&1, &2))
  end

  defp collect_focus_order(%DesktopUi.Widget{} = widget, acc) do
    acc =
      if Map.get(widget.metadata, :focusable, false) do
        acc ++ [to_string(widget.id)]
      else
        acc
      end

    Enum.reduce(widget.children, acc, &collect_focus_order/2)
  end
end
