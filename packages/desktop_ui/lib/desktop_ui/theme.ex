defmodule DesktopUi.Theme do
  @moduledoc """
  Theme catalog and style inheritance rules for `desktop_ui`.
  """

  @default_theme :desktop_default

  @themes %{
    desktop_default: %{
      id: :desktop_default,
      palette: %{
        canvas_fg: :content,
        canvas_bg: :canvas,
        surface_fg: :content,
        surface_bg: :surface,
        accent_fg: :accent,
        muted_fg: :muted,
        selection_fg: :selection,
        focus_ring: :focus_ring
      },
      semantic_roles: %{
        title: %{fg: :content, attrs: [:bold]},
        body: %{fg: :content},
        label: %{fg: :muted, attrs: [:bold]},
        caption: %{fg: :muted},
        window_chrome: %{fg: :content, attrs: [:bold]},
        primary_action: %{fg: :accent, attrs: [:bold]},
        secondary_action: %{fg: :muted},
        status_info: %{fg: :info, attrs: [:bold]},
        status_warning: %{fg: :warning, attrs: [:bold]},
        status_danger: %{fg: :danger, attrs: [:bold]},
        selection: %{fg: :selection, attrs: [:bold]}
      },
      component_defaults: %{
        window: %{variant: :panel, semantic_role: :window_chrome, padding: :md},
        dialog: %{variant: :elevated, semantic_role: :window_chrome, padding: :md},
        content: %{variant: :panel, padding: :sm},
        column: %{padding: :sm},
        row: %{padding: :sm},
        stack: %{padding: :sm},
        text: %{semantic_role: :body},
        label: %{semantic_role: :label},
        button: %{variant: :default, semantic_role: :primary_action, padding: :xs},
        toggle: %{variant: :outlined, semantic_role: :secondary_action, padding: :xs},
        link: %{variant: :quiet, semantic_role: :primary_action},
        command: %{variant: :quiet, semantic_role: :primary_action},
        text_input: %{variant: :outlined, padding: :xs, border: :single},
        checkbox: %{variant: :default, semantic_role: :body},
        radio_group: %{variant: :default, semantic_role: :body},
        select: %{variant: :outlined, padding: :xs, border: :single},
        menu: %{variant: :panel, padding: :xs},
        tabs: %{variant: :quiet},
        breadcrumbs: %{variant: :quiet, semantic_role: :caption},
        list: %{variant: :panel, padding: :xs},
        status: %{variant: :quiet, semantic_role: :status_info},
        table: %{variant: :outlined, padding: :xs, border: :hairline},
        tree_view: %{variant: :outlined, padding: :xs, border: :hairline},
        inspector: %{variant: :panel, padding: :sm},
        markdown_viewer: %{variant: :panel, padding: :sm},
        toast: %{variant: :filled, semantic_role: :status_info, padding: :sm},
        alert_dialog: %{variant: :elevated, semantic_role: :status_warning, padding: :md},
        progress: %{variant: :filled, semantic_role: :status_info},
        gauge: %{variant: :panel, semantic_role: :status_info},
        bar_chart: %{variant: :panel},
        line_chart: %{variant: :panel},
        timeline: %{variant: :panel},
        canvas: %{variant: :panel},
        log_viewer: %{variant: :panel, semantic_role: :caption},
        cluster_dashboard: %{variant: :panel},
        command_palette: %{variant: :elevated, padding: :sm},
        process_monitor: %{variant: :panel},
        viewport: %{variant: :panel},
        scroll_region: %{variant: :panel},
        split_pane: %{variant: :panel},
        canvas_surface: %{variant: :panel},
        absolute: %{variant: :panel},
        overlay: %{variant: :panel},
        context_menu: %{variant: :elevated, padding: :xs},
        popover: %{variant: :elevated, padding: :xs},
        multi_window: %{variant: :panel}
      },
      component_variants: %{
        button: %{
          default: %{attrs: [:bold]},
          quiet: %{fg: :muted},
          accented: %{fg: :accent, attrs: [:bold, :underline]},
          filled: %{bg: :accent, fg: :surface, attrs: [:bold]}
        },
        text_input: %{
          outlined: %{border: :single, padding: :xs},
          dense: %{border: :hairline, padding: :none}
        },
        window: %{
          panel: %{border: :single, bg: :surface}
        },
        dialog: %{
          elevated: %{border: :double, elevation: :raised, bg: :surface}
        },
        table: %{
          outlined: %{border: :hairline}
        },
        status: %{
          quiet: %{fg: :muted},
          filled: %{bg: :info, fg: :surface}
        },
        command_palette: %{
          elevated: %{border: :double, elevation: :raised}
        }
      },
      tokens: %{
        text: %{
          hero: %{semantic_role: :title, attrs: [:bold, :uppercase]},
          subtle: %{semantic_role: :caption}
        },
        button: %{
          primary: %{variant: :accented, semantic_role: :primary_action},
          secondary: %{variant: :quiet, semantic_role: :secondary_action}
        },
        surface: %{
          panel: %{variant: :panel, border: :single, bg: :surface},
          elevated: %{variant: :elevated, border: :double, elevation: :raised}
        },
        status: %{
          warning: %{semantic_role: :status_warning},
          danger: %{semantic_role: :status_danger}
        }
      }
    },
    high_contrast: %{
      id: :high_contrast,
      palette: %{
        canvas_fg: :content,
        canvas_bg: :canvas,
        surface_fg: :content,
        surface_bg: :surface,
        accent_fg: :accent,
        muted_fg: :content,
        selection_fg: :selection,
        focus_ring: :focus_ring
      },
      semantic_roles: %{
        title: %{fg: :content, attrs: [:bold, :underline]},
        body: %{fg: :content, attrs: [:bold]},
        label: %{fg: :content, attrs: [:bold]},
        caption: %{fg: :content},
        window_chrome: %{fg: :content, attrs: [:bold, :underline]},
        primary_action: %{fg: :accent, attrs: [:bold, :underline]},
        secondary_action: %{fg: :content, attrs: [:underline]},
        status_info: %{fg: :info, attrs: [:bold, :underline]},
        status_warning: %{fg: :warning, attrs: [:bold, :underline]},
        status_danger: %{fg: :danger, attrs: [:bold, :underline]},
        selection: %{fg: :selection, attrs: [:bold, :underline]}
      },
      component_defaults: %{
        window: %{variant: :panel, semantic_role: :window_chrome, padding: :md},
        dialog: %{variant: :elevated, semantic_role: :window_chrome, padding: :md},
        button: %{variant: :filled, semantic_role: :primary_action, padding: :xs},
        text_input: %{variant: :outlined, padding: :xs, border: :double},
        table: %{variant: :outlined, padding: :xs, border: :double},
        tree_view: %{variant: :outlined, padding: :xs, border: :double},
        command_palette: %{variant: :elevated, padding: :sm},
        status: %{variant: :filled, semantic_role: :status_info}
      },
      component_variants: %{
        button: %{
          filled: %{bg: :accent, fg: :surface, attrs: [:bold, :underline]}
        },
        dialog: %{
          elevated: %{border: :double, elevation: :raised, bg: :surface}
        },
        table: %{
          outlined: %{border: :double}
        }
      },
      tokens: %{
        text: %{
          hero: %{semantic_role: :title, attrs: [:bold, :underline, :uppercase]}
        },
        button: %{
          primary: %{variant: :filled, semantic_role: :primary_action},
          secondary: %{variant: :quiet, semantic_role: :secondary_action}
        },
        surface: %{
          panel: %{variant: :panel, border: :double, bg: :surface},
          elevated: %{variant: :elevated, border: :double, elevation: :raised}
        },
        status: %{
          warning: %{semantic_role: :status_warning},
          danger: %{semantic_role: :status_danger}
        }
      }
    }
  }

  @spec default_theme() :: map()
  def default_theme, do: theme(@default_theme)

  @spec theme(atom() | String.t() | nil) :: map()
  def theme(name) when is_binary(name), do: name |> String.to_atom() |> theme()
  def theme(nil), do: theme(@default_theme)

  def theme(name) when is_atom(name) do
    Map.get(@themes, name, Map.fetch!(@themes, @default_theme))
  end

  @spec catalog() :: map()
  def catalog, do: @themes

  @spec catalog_ids() :: [atom()]
  def catalog_ids, do: Map.keys(@themes)

  @spec continuity_rules() :: map()
  def continuity_rules do
    %{
      inheritance_order: [
        :parent_context,
        :component_defaults,
        :semantic_role,
        :theme_tokens,
        :local_styles
      ],
      unresolved_tokens: :warn_and_continue,
      shared_native_and_canonical_model: true
    }
  end

  @spec validation_state() :: map()
  def validation_state do
    %{
      theme_catalog: :ready,
      inheritance_rules: :ready,
      shared_style_model: :ready
    }
  end

  @spec resolve_token(atom() | String.t() | nil, [atom() | String.t()]) ::
          {:ok, map()} | {:error, :unknown_token}
  def resolve_token(theme_name, token_path) when is_list(token_path) do
    token_path =
      Enum.map(token_path, fn
        value when is_binary(value) -> String.to_atom(value)
        value -> value
      end)

    case get_in(theme(theme_name), [:tokens | token_path]) do
      nil -> {:error, :unknown_token}
      styles -> {:ok, styles}
    end
  end

  @spec resolve_component_style(atom() | String.t() | nil, atom(), atom() | nil) :: map()
  def resolve_component_style(theme_name, kind, variant \\ nil) do
    theme = theme(theme_name)
    defaults = get_in(theme, [:component_defaults, kind]) || %{}
    variant_name = variant || Map.get(defaults, :variant)
    variant_defaults = get_in(theme, [:component_variants, kind, variant_name]) || %{}

    merge_styles(defaults, variant_defaults)
  end

  @spec merge_styles(map(), map()) :: map()
  def merge_styles(left, right) when left == %{}, do: right
  def merge_styles(left, right) when right == %{}, do: left

  def merge_styles(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      cond do
        is_map(left_value) and is_map(right_value) ->
          merge_styles(left_value, right_value)

        is_list(left_value) and is_list(right_value) ->
          Enum.uniq(left_value ++ right_value)

        true ->
          right_value
      end
    end)
  end
end
