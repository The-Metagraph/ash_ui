defmodule ElmUi.FrontendRuntime.Realization do
  @moduledoc """
  Frontend-side realization of server-authored render trees into browser-facing
  node descriptions.
  """

  alias ElmUi.FrontendRuntime.StyleRealization

  @spec realize(map(), map()) :: map()
  def realize(render_tree, local_state \\ %{}) when is_map(render_tree) and is_map(local_state) do
    browser_style = StyleRealization.realize(render_tree, local_state)

    %{
      id: render_tree.id,
      family: render_tree.family,
      kind: render_tree.kind,
      tag: render_tree.dom.tag,
      role: render_tree.dom.role,
      attrs: render_tree.dom.attributes,
      attributes: render_tree.attributes,
      state: render_tree.state,
      styles: %{
        authored: render_tree.styles,
        resolved: Map.get(render_tree, :resolved_styles, %{}),
        browser: browser_style
      },
      theme: Map.get(render_tree, :theme, %{}),
      diagnostics: Map.get(render_tree, :diagnostics, %{}),
      browser: %{
        interactive?: render_tree.interactions.interactive?,
        focusable?: render_tree.interactions.focusable?,
        editable?: render_tree.interactions.editable?,
        navigable?: render_tree.interactions.navigable?,
        focused?: Map.get(local_state, :focused_id) == render_tree.id,
        editing?: editing?(local_state, render_tree.id, render_tree.state),
        style: browser_style
      },
      slots:
        Enum.map(render_tree.slots, fn slot ->
          %{
            name: slot.name,
            children: Enum.map(slot.children, &realize(&1, local_state))
          }
        end)
    }
  end

  defp editing?(local_state, id, state) do
    editing_ids = Map.get(local_state, :editing_ids, [])
    id in List.wrap(editing_ids) or Map.get(state, :editing, false)
  end
end
