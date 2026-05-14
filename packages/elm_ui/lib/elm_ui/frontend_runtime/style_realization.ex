defmodule ElmUi.FrontendRuntime.StyleRealization do
  @moduledoc """
  Frontend-side realization of resolved style meaning into browser-facing style
  data.
  """

  @responsive_kinds [:row, :column, :stack, :viewport, :split_pane, :overlay, :dialog]

  @spec realize(map(), map()) :: map()
  def realize(render_tree, local_state \\ %{}) when is_map(render_tree) and is_map(local_state) do
    resolved = Map.get(render_tree, :resolved_styles, %{})
    focused? = Map.get(local_state, :focused_id) == render_tree.id
    editing? = render_tree.id in List.wrap(Map.get(local_state, :editing_ids, []))

    %{
      class_tokens:
        []
        |> maybe_add_token("family", render_tree.family)
        |> maybe_add_token("kind", render_tree.kind)
        |> maybe_add_token("theme", get_in(render_tree, [:theme, :id]))
        |> maybe_add_token("tone", Map.get(resolved, :tone))
        |> maybe_add_token("variant", Map.get(resolved, :variant))
        |> Kernel.++(
          Enum.map(List.wrap(Map.get(resolved, :style_refs, [])), &("ref-" <> to_string(&1)))
        )
        |> maybe_add("is-focused", focused?)
        |> maybe_add("is-editing", editing?),
      css_vars:
        %{}
        |> maybe_put_var("--ui-tone", Map.get(resolved, :tone))
        |> maybe_put_var("--ui-surface", Map.get(resolved, :surface))
        |> maybe_put_var("--ui-background", Map.get(resolved, :background))
        |> maybe_put_var("--ui-border", Map.get(resolved, :border))
        |> maybe_put_var("--ui-emphasis", Map.get(resolved, :emphasis))
        |> maybe_put_var("--ui-typography", Map.get(resolved, :typography)),
      transitions: %{
        focus_ring?: focused? and render_tree.interactions.focusable?,
        responsive_layout?: render_tree.kind in @responsive_kinds,
        feedback?: editing? or render_tree.interactions.interactive?
      },
      responsive: %{
        fill?: Map.get(resolved, :size) == :fill,
        align: Map.get(resolved, :align, :start),
        visibility: Map.get(resolved, :visibility, :visible)
      }
    }
  end

  defp maybe_add(list, _value, false), do: list
  defp maybe_add(list, value, true), do: list ++ [value]

  defp maybe_add_token(list, _prefix, nil), do: list
  defp maybe_add_token(list, prefix, value), do: list ++ ["#{prefix}-#{value}"]

  defp maybe_put_var(map, _key, nil), do: map
  defp maybe_put_var(map, key, value), do: Map.put(map, key, to_string(value))
end
