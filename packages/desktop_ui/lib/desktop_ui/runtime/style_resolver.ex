defmodule DesktopUi.Runtime.StyleResolver do
  @moduledoc """
  Shared style and theme resolution for native and canonical `desktop_ui`
  realization trees.
  """

  alias DesktopUi.{Style, Theme}
  alias DesktopUi.Runtime.Screen

  @inheritable_keys [:theme, :fg, :bg, :attrs, :tone, :weight, :intent]

  @spec resolve_screen(Screen.t(), map(), keyword()) :: map()
  def resolve_screen(%Screen{} = screen, realization, opts \\ []) when is_map(realization) do
    theme_name = Keyword.get(opts, :theme, screen.metadata.theme)
    {tree, style_index, diagnostics} = resolve_node(realization.tree, theme_name, %{})

    style_diagnostics = Enum.sort_by(diagnostics, &{&1.widget_id, &1.reason})

    realization
    |> Map.put(:tree, tree)
    |> Map.put(:theme, theme_name)
    |> Map.put(:style_index, style_index)
    |> Map.put(:style_contract, %{
      shared_model: true,
      theme_catalog: Theme.catalog_ids(),
      continuity_rules: Theme.continuity_rules(),
      responsibilities: responsibilities()
    })
    |> Map.update!(:cell_surface, fn cells ->
      Enum.map(cells, fn cell ->
        Map.put(cell, :styles, Map.get(style_index, cell.widget_id, %{}))
      end)
    end)
    |> Map.update!(:diagnostics, fn diagnostics_map ->
      diagnostics_map
      |> Map.put(:style_theme, theme_name)
      |> Map.put(:style_warnings, style_diagnostics)
      |> Map.put(:style_resolution, :ready)
    end)
  end

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :theme_defaults,
      :component_variants,
      :semantic_role_resolution,
      :style_inheritance,
      :state_variant_resolution
    ]
  end

  defp resolve_node(node, fallback_theme, parent_resolved) do
    authored = Style.normalize(Map.get(node, :styles, %{}))
    theme_name = Map.get(authored, :theme, Map.get(parent_resolved, :theme, fallback_theme))
    theme = Theme.theme(theme_name)
    variant = Map.get(authored, :variant, Map.get(node.metadata, :variant))
    component_defaults = Theme.resolve_component_style(theme.id, node.kind, variant)
    semantic_role = Map.get(authored, :semantic_role, Map.get(component_defaults, :semantic_role))
    semantic_defaults = Map.get(theme.semantic_roles, semantic_role, %{})

    {token_styles, token_diagnostics} =
      resolve_theme_tokens(theme.id, Map.get(authored, :theme_tokens, %{}), node.id)

    {state_styles, state_diagnostics} = resolve_state_variants(node, authored)

    inherited =
      parent_resolved
      |> inherited_styles()
      |> maybe_reset_for_local_theme(authored, theme.id)

    resolved =
      inherited
      |> Theme.merge_styles(component_defaults)
      |> Theme.merge_styles(semantic_defaults)
      |> Theme.merge_styles(token_styles)
      |> Theme.merge_styles(drop_meta_styles(authored))
      |> Theme.merge_styles(state_styles)
      |> Map.put(:theme, theme.id)

    {children, index, child_diagnostics} =
      Enum.reduce(node.children, {[], %{}, []}, fn child, {children_acc, index_acc, diag_acc} ->
        {resolved_child, child_index, child_diags} = resolve_node(child, theme.id, resolved)

        {
          children_acc ++ [resolved_child],
          Map.merge(index_acc, child_index),
          diag_acc ++ child_diags
        }
      end)

    resolved_node =
      node
      |> Map.put(:children, children)
      |> Map.put(:resolved_styles, resolved)
      |> Map.put(:style_diagnostics, token_diagnostics ++ state_diagnostics)
      |> Map.put(:active_style_states, active_states(node.state))

    {
      resolved_node,
      Map.put(index, node.id, resolved),
      token_diagnostics ++ state_diagnostics ++ child_diagnostics
    }
  end

  defp resolve_theme_tokens(_theme_name, token_map, _widget_id) when map_size(token_map) == 0,
    do: {%{}, []}

  defp resolve_theme_tokens(theme_name, token_map, widget_id) do
    Enum.reduce(token_map, {%{}, []}, fn {token_name, path}, {styles_acc, diag_acc} ->
      case normalize_token_path(path) do
        [] ->
          {styles_acc, diag_acc ++ [invalid_token_diagnostic(widget_id, token_name, path)]}

        token_path ->
          case Theme.resolve_token(theme_name, token_path) do
            {:ok, styles} ->
              {Theme.merge_styles(styles_acc, styles), diag_acc}

            {:error, :unknown_token} ->
              {styles_acc,
               diag_acc ++ [unresolved_token_diagnostic(widget_id, token_name, token_path)]}
          end
      end
    end)
  end

  defp resolve_state_variants(node, authored_styles) do
    active = active_states(node.state)
    variant_styles = Map.get(authored_styles, :state_variants, %{})

    resolved =
      active
      |> Enum.reduce(%{}, fn state, acc ->
        Theme.merge_styles(acc, Map.get(variant_styles, state, %{}))
      end)

    missing = Enum.reject(active, &Map.has_key?(variant_styles, &1))

    diagnostics =
      if missing == [] do
        []
      else
        [
          %{
            widget_id: node.id,
            level: :warning,
            reason: :missing_state_variant_styles,
            states: missing
          }
        ]
      end

    {resolved, diagnostics}
  end

  defp active_states(state) do
    state
    |> Map.new()
    |> Enum.filter(fn {_state, value} -> value in [true, :active, :current] end)
    |> Enum.map(fn {state, _value} -> state end)
    |> Enum.filter(&(&1 in Style.state_variant_keys()))
  end

  defp inherited_styles(parent_resolved) do
    Map.take(parent_resolved, @inheritable_keys)
  end

  defp maybe_reset_for_local_theme(_inherited, authored, theme_id)
       when is_map_key(authored, :theme) do
    %{theme: theme_id}
  end

  defp maybe_reset_for_local_theme(inherited, _authored, _theme_id), do: inherited

  defp normalize_token_path(path) when is_list(path) do
    Enum.map(path, fn
      value when is_binary(value) -> String.to_atom(value)
      value -> value
    end)
  end

  defp normalize_token_path(_path), do: []

  defp invalid_token_diagnostic(widget_id, token_name, path) do
    %{
      widget_id: widget_id,
      level: :warning,
      reason: :invalid_theme_token_reference,
      token: token_name,
      path: path
    }
  end

  defp unresolved_token_diagnostic(widget_id, token_name, token_path) do
    %{
      widget_id: widget_id,
      level: :warning,
      reason: :unresolved_theme_token,
      token: token_name,
      path: token_path
    }
  end

  defp drop_meta_styles(styles) do
    Map.drop(styles, [:theme, :style_refs, :theme_tokens, :state_variants])
  end
end
