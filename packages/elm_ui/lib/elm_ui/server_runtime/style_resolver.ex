defmodule ElmUi.ServerRuntime.StyleResolver do
  @moduledoc """
  Server-authoritative style and theme resolution for `elm_ui` widgets.
  """

  alias ElmUi.{Style, Theme, Widget}

  @layer_kinds [:overlay, :dialog, :toast, :alert_dialog, :context_menu]

  @spec resolve(Widget.t(), keyword()) :: map()
  def resolve(%Widget{} = widget, opts \\ []) do
    theme_name = Keyword.get(opts, :theme, :default)
    theme = Theme.theme(theme_name)
    authored_styles = Style.normalize(widget.styles)
    component_defaults = get_in(theme, [:component_defaults, widget.kind]) || %{}
    variant_defaults = resolve_variant(theme, widget.kind, Map.get(authored_styles, :variant))

    {token_styles, token_diagnostics} =
      resolve_theme_tokens(theme_name, Map.get(authored_styles, :theme_tokens, %{}))

    {state_variant_styles, state_variant_diagnostics} =
      resolve_state_variants(widget.state, authored_styles)

    resolved =
      component_defaults
      |> deep_merge(token_styles)
      |> deep_merge(variant_defaults)
      |> deep_merge(drop_meta_styles(authored_styles))
      |> deep_merge(state_variant_styles)
      |> Map.put(:theme, theme.id)
      |> maybe_put(:hooks, Map.get(authored_styles, :hooks))
      |> maybe_put(:style_refs, Map.get(authored_styles, :style_refs))

    diagnostics =
      token_diagnostics ++
        state_variant_diagnostics ++ incompatible_combination_diagnostics(widget, resolved)

    %{
      theme: theme.id,
      resolved: resolved,
      diagnostics: diagnostics,
      token_refs: Map.get(authored_styles, :theme_tokens, %{}),
      active_states: active_states(widget.state)
    }
  end

  defp resolve_variant(theme, kind, nil),
    do: get_in(theme, [:component_variants, kind, :secondary]) || %{}

  defp resolve_variant(theme, kind, variant) do
    get_in(theme, [:component_variants, kind, variant]) || %{}
  end

  defp resolve_theme_tokens(_theme_name, token_map) when map_size(token_map) == 0, do: {%{}, []}

  defp resolve_theme_tokens(theme_name, token_map) do
    Enum.reduce(token_map, {%{}, []}, fn {token_name, path}, {styles_acc, diag_acc} ->
      case normalize_token_path(path) do
        [] ->
          {styles_acc, diag_acc ++ [invalid_token_diagnostic(token_name, path)]}

        token_path ->
          case Theme.resolve_token(theme_name, token_path) do
            {:ok, styles} ->
              {deep_merge(styles_acc, styles), diag_acc}

            {:error, :unknown_token} ->
              {styles_acc,
               diag_acc ++ [unresolved_token_diagnostic(token_name, token_path, theme_name)]}
          end
      end
    end)
  end

  defp resolve_state_variants(widget_state, authored_styles) do
    active = active_states(widget_state)
    variant_styles = Map.get(authored_styles, :state_variants, %{})
    hooks = Map.get(authored_styles, :hooks, [])

    diagnostics =
      if :state_variants in hooks do
        missing =
          Enum.reject(active, fn state ->
            variant_styles
            |> Map.get(state)
            |> is_map()
          end)

        if missing == [] do
          []
        else
          [
            %{
              level: :error,
              reason: :invalid_state_variant_wiring,
              states: missing
            }
          ]
        end
      else
        []
      end

    resolved =
      active
      |> Enum.reduce(%{}, fn state, acc ->
        variant = Map.get(variant_styles, state, %{})
        deep_merge(acc, variant)
      end)

    {resolved, diagnostics}
  end

  defp incompatible_combination_diagnostics(widget, resolved) do
    []
    |> maybe_add_incompatible_visibility(resolved)
    |> maybe_add_layer_background_diagnostic(widget, resolved)
  end

  defp maybe_add_incompatible_visibility(diagnostics, %{visibility: :hidden, emphasis: emphasis})
       when emphasis in [:strong, :intense] do
    diagnostics ++
      [
        %{
          level: :error,
          reason: :incompatible_style_combination,
          detail: :visibility_conflicts_with_emphasis
        }
      ]
  end

  defp maybe_add_incompatible_visibility(diagnostics, _resolved), do: diagnostics

  defp maybe_add_layer_background_diagnostic(diagnostics, %Widget{kind: kind}, %{
         background: :scrim
       })
       when kind not in @layer_kinds do
    diagnostics ++
      [
        %{
          level: :error,
          reason: :incompatible_style_combination,
          detail: :scrim_background_requires_layer_widget
        }
      ]
  end

  defp maybe_add_layer_background_diagnostic(diagnostics, _widget, _resolved), do: diagnostics

  defp active_states(state) do
    state
    |> Map.new()
    |> Enum.filter(fn {_state, value} -> value in [true, :active, :current] end)
    |> Enum.map(fn {state, _value} -> state end)
    |> Enum.filter(&(&1 in Style.state_variant_keys()))
  end

  defp unresolved_token_diagnostic(token_name, token_path, theme_name) do
    %{
      level: :error,
      reason: :unresolved_theme_token,
      token: token_name,
      path: token_path,
      theme: theme_name
    }
  end

  defp invalid_token_diagnostic(token_name, path) do
    %{
      level: :error,
      reason: :invalid_theme_token_reference,
      token: token_name,
      path: path
    }
  end

  defp normalize_token_path(path) when is_list(path) do
    Enum.map(path, fn
      value when is_binary(value) -> String.to_atom(value)
      value -> value
    end)
  end

  defp normalize_token_path(_path), do: []

  defp drop_meta_styles(styles) do
    Map.drop(styles, [:hooks, :style_refs, :theme_tokens, :state_variants, :composition])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp deep_merge(left, right) when left == %{}, do: right
  defp deep_merge(left, right) when right == %{}, do: left

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      if is_map(left_value) and is_map(right_value) do
        deep_merge(left_value, right_value)
      else
        right_value
      end
    end)
  end
end
