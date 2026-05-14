defmodule ElmUi.Theme do
  @moduledoc """
  Native theme catalog and token resolution helpers for `elm_ui`.
  """

  @default_theme :default

  @themes %{
    default: %{
      id: :default,
      palette: %{
        canvas: "#F7F4EC",
        panel: "#FFFDFC",
        elevated: "#FFFFFF",
        accent: "#0F6C5B",
        accent_tint: "#D7F0EA",
        content: "#1E1B16",
        muted: "#6F665C",
        border: "#D8CFC2",
        success: "#2E7D32",
        warning: "#B26A00",
        danger: "#B2402F",
        info: "#2F6FA8"
      },
      semantic_roles: %{
        success: :success,
        warning: :warning,
        error: :danger,
        info: :info,
        muted: :muted,
        help: :accent,
        placeholder: :muted
      },
      component_defaults: %{
        text: %{typography: :body, tone: :content},
        button: %{variant: :secondary, tone: :accent, size: :md, surface: :panel},
        text_input: %{variant: :field, border: :subtle, surface: :panel},
        dialog: %{surface: :elevated, background: :panel, border: :strong},
        overlay: %{background: :scrim},
        status: %{tone: :info, emphasis: :strong}
      },
      component_variants: %{
        button: %{
          primary: %{variant: :primary, background: :accent_tint, emphasis: :strong},
          secondary: %{variant: :secondary, border: :subtle},
          quiet: %{variant: :quiet, background: :transparent}
        },
        text_input: %{
          field: %{variant: :field, border: :subtle},
          dense: %{variant: :dense, spacing: :sm}
        },
        overlay: %{
          modal: %{background: :scrim, emphasis: :intense}
        }
      },
      tokens: %{
        surface: %{default: %{surface: :panel, background: :panel}},
        text: %{
          hero: %{typography: :display, emphasis: :strong},
          label: %{typography: :label, emphasis: :strong}
        },
        button: %{
          primary: %{variant: :primary, tone: :accent},
          subtle: %{variant: :quiet, tone: :muted}
        }
      }
    },
    midnight: %{
      id: :midnight,
      palette: %{
        canvas: "#0C1321",
        panel: "#111A2C",
        elevated: "#172238",
        accent: "#6CC5A1",
        accent_tint: "#19352C",
        content: "#F3F7FB",
        muted: "#A8B3C4",
        border: "#2B3A53",
        success: "#5AC16E",
        warning: "#F1B449",
        danger: "#EF7E73",
        info: "#79B8FF"
      },
      semantic_roles: %{
        success: :success,
        warning: :warning,
        error: :danger,
        info: :info,
        muted: :muted,
        help: :accent,
        placeholder: :muted
      },
      component_defaults: %{
        text: %{typography: :body, tone: :content},
        button: %{variant: :secondary, tone: :accent, size: :md, surface: :panel},
        text_input: %{variant: :field, border: :subtle, surface: :panel},
        dialog: %{surface: :elevated, background: :panel, border: :strong},
        overlay: %{background: :scrim},
        status: %{tone: :info, emphasis: :strong}
      },
      component_variants: %{
        button: %{
          primary: %{variant: :primary, background: :accent_tint, emphasis: :strong},
          secondary: %{variant: :secondary, border: :subtle}
        }
      },
      tokens: %{
        surface: %{default: %{surface: :panel, background: :panel}},
        text: %{hero: %{typography: :display, emphasis: :strong}},
        button: %{primary: %{variant: :primary, tone: :accent}}
      }
    }
  }

  @spec default_theme() :: map()
  def default_theme, do: theme(@default_theme)

  @spec theme(atom()) :: map()
  def theme(name) when is_atom(name) do
    Map.get(@themes, name, Map.fetch!(@themes, @default_theme))
  end

  @spec catalog() :: map()
  def catalog, do: @themes

  @spec catalog_ids() :: [atom()]
  def catalog_ids, do: Map.keys(@themes)

  @spec palette_roles() :: [atom()]
  def palette_roles do
    @default_theme
    |> theme()
    |> Map.fetch!(:palette)
    |> Map.keys()
  end

  @spec continuity_rules() :: map()
  def continuity_rules do
    %{
      inheritance_order: [:theme_defaults, :component_defaults, :variant_defaults, :local_styles],
      unresolved_tokens: :fallback_to_component_defaults,
      token_resolution: :server_authoritative,
      frontend_realization: :deterministic
    }
  end

  @spec runtime_contract() :: map()
  def runtime_contract do
    %{
      authoritative_server_theme: true,
      frontend_realizes_tokens: true,
      browser_state_redefines_theme: false
    }
  end

  @spec resolve_token(atom(), [atom()]) :: {:ok, map()} | {:error, :unknown_token}
  def resolve_token(theme_name, token_path) when is_atom(theme_name) and is_list(token_path) do
    token_path =
      token_path
      |> Enum.map(fn
        value when is_binary(value) -> String.to_atom(value)
        value -> value
      end)

    case get_in(theme(theme_name), [:tokens | token_path]) do
      nil -> {:error, :unknown_token}
      token -> {:ok, token}
    end
  end
end
