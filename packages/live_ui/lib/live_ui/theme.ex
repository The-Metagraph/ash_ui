defmodule LiveUi.Theme do
  @moduledoc """
  Native theme surface for `live_ui`, backed by canonical `UnifiedIUR` theme
  semantics and enriched with native component classes and marker attributes.
  """

  alias UnifiedIUR.Style, as: CanonicalStyle
  alias UnifiedIUR.Theme, as: CanonicalTheme
  alias UnifiedIUR.Token

  @type component_key :: atom() | String.t()
  @type variant_key :: atom() | String.t()
  @type state_key :: atom() | String.t()

  @type native_component_profile :: %{
          optional(:tone) => atom() | String.t(),
          optional(:variant) => variant_key(),
          optional(:state) => state_key(),
          optional(:class) => String.t(),
          optional(:attrs) => map(),
          optional(:variant_classes) => %{optional(variant_key()) => String.t()},
          optional(:state_classes) => %{optional(state_key()) => String.t()}
        }

  @type native_profile_map :: %{
          optional(component_key()) => native_component_profile()
        }

  @type t :: %__MODULE__{
          id: atom() | String.t() | nil,
          canonical: CanonicalTheme.t(),
          native: %{components: native_profile_map()}
        }

  @enforce_keys [:canonical, :native]
  defstruct id: nil, canonical: %CanonicalTheme{}, native: %{components: %{}}

  @spec default() :: t()
  def default do
    new(%{
      id: :live_ui,
      palette: %{
        surface: "#111827",
        accent: "#2563eb",
        success: "#059669",
        warning: "#d97706",
        critical: "#dc2626",
        muted: "#6b7280"
      },
      roles: %{
        surface: Token.ref([:palette, :surface]),
        accent: Token.ref([:palette, :accent]),
        success: Token.ref([:palette, :success]),
        warning: Token.ref([:palette, :warning]),
        critical: Token.ref([:palette, :critical]),
        muted: Token.ref([:palette, :muted])
      },
      tokens: %{
        "surface.base" => %{background: "#111827", foreground: "#f9fafb"},
        "surface.panel" => %{background: "#1f2937", foreground: "#f9fafb"},
        "accent.default" => %{foreground: "#2563eb"},
        "accent.strong" => %{foreground: "#1d4ed8"},
        "feedback.success" => %{foreground: "#059669"},
        "feedback.critical" => %{foreground: "#dc2626"}
      },
      defaults: %{
        emphasis: %{tone: :surface},
        spacing: %{gap: :md},
        border: %{radius: :md}
      },
      components: %{
        screen_shell: %{
          default: %{emphasis: %{tone: :surface}},
          variants: %{
            workspace: %{spacing: %{padding: :xl}}
          }
        },
        box: %{
          default: %{emphasis: %{tone: :surface}},
          variants: %{
            panel: %{border: %{weight: :thin}}
          }
        },
        form_builder: %{
          default: %{emphasis: %{tone: :surface}}
        },
        button: %{
          default: %{emphasis: %{tone: :accent}},
          variants: %{
            solid: %{foreground: "#ffffff", background: "#2563eb"},
            quiet: %{foreground: "#2563eb"}
          },
          states: %{
            active: %{emphasis: %{tone: :accent}},
            disabled: %{visibility: %{disabled?: true}}
          }
        },
        text_input: %{
          default: %{emphasis: %{tone: :surface}},
          variants: %{
            filled: %{background: "#1f2937"},
            subtle: %{background: "#111827"}
          },
          states: %{
            focused: %{border_color: "#2563eb"}
          }
        },
        text: %{
          default: %{emphasis: %{tone: :surface}}
        },
        overlay_surface: %{
          default: %{emphasis: %{tone: :surface}},
          variants: %{
            modal: %{background: "#111827"}
          }
        },
        dialog: %{
          default: %{emphasis: %{tone: :surface}},
          variants: %{
            modal: %{background: "#1f2937"}
          }
        },
        alert_dialog: %{
          default: %{emphasis: %{tone: :warning}},
          variants: %{
            critical: %{border_color: "#dc2626"},
            warning: %{border_color: "#d97706"}
          }
        },
        toast: %{
          default: %{emphasis: %{tone: :success}},
          states: %{
            active: %{emphasis: %{tone: :success}}
          }
        },
        viewport: %{
          default: %{emphasis: %{tone: :surface}}
        },
        canvas: %{
          default: %{emphasis: %{tone: :muted}},
          variants: %{
            analysis: %{background: "#111827"}
          }
        },
        stream_widget: %{
          default: %{emphasis: %{tone: :surface}}
        },
        cluster_dashboard: %{
          default: %{emphasis: %{tone: :surface}}
        }
      },
      native: %{
        components: %{
          screen_shell: %{
            tone: :surface,
            variant: :workspace,
            class: "live-ui-screen-shell",
            attrs: %{"data-live-ui-surface" => "screen"},
            variant_classes: %{workspace: "live-ui-screen-shell-workspace"}
          },
          box: %{
            tone: :surface,
            variant: :panel,
            class: "live-ui-box",
            variant_classes: %{panel: "live-ui-box-panel"}
          },
          form_builder: %{
            tone: :surface,
            class: "live-ui-form-builder"
          },
          button: %{
            tone: :accent,
            variant: :solid,
            class: "live-ui-button",
            attrs: %{"data-live-ui-role" => "action"},
            variant_classes: %{
              solid: "live-ui-button-solid",
              quiet: "live-ui-button-quiet"
            },
            state_classes: %{
              active: "is-active",
              disabled: "is-disabled"
            }
          },
          text_input: %{
            tone: :surface,
            variant: :filled,
            class: "live-ui-text-input",
            variant_classes: %{
              filled: "live-ui-text-input-filled",
              subtle: "live-ui-text-input-subtle"
            },
            state_classes: %{focused: "is-focused"}
          },
          text: %{
            tone: :surface,
            class: "live-ui-text"
          },
          overlay_surface: %{
            tone: :surface,
            variant: :modal,
            class: "live-ui-overlay-surface",
            attrs: %{"data-live-ui-layered" => "true"},
            variant_classes: %{modal: "live-ui-overlay-modal"}
          },
          dialog: %{
            tone: :surface,
            variant: :modal,
            class: "live-ui-dialog"
          },
          alert_dialog: %{
            tone: :warning,
            variant: :warning,
            class: "live-ui-alert-dialog",
            variant_classes: %{
              critical: "live-ui-alert-dialog-critical",
              warning: "live-ui-alert-dialog-warning"
            }
          },
          toast: %{
            tone: :success,
            class: "live-ui-toast",
            state_classes: %{active: "is-active"}
          },
          viewport: %{
            tone: :surface,
            class: "live-ui-viewport"
          },
          canvas: %{
            tone: :muted,
            variant: :analysis,
            class: "live-ui-canvas",
            attrs: %{"data-live-ui-render-mode" => "native-canvas"},
            variant_classes: %{analysis: "live-ui-canvas-analysis"}
          },
          stream_widget: %{
            tone: :surface,
            class: "live-ui-stream-widget"
          },
          cluster_dashboard: %{
            tone: :surface,
            class: "live-ui-cluster-dashboard"
          }
        }
      }
    })
  end

  @spec new(keyword() | map() | t() | nil) :: t()
  def new(nil), do: default()

  def new(%__MODULE__{} = theme) do
    %__MODULE__{
      id: theme.id || theme.canonical.id,
      canonical: CanonicalTheme.new(theme.canonical),
      native: normalize_native(theme.native)
    }
  end

  def new(theme) when is_list(theme), do: theme |> Enum.into(%{}) |> new()

  def new(theme) when is_map(theme) do
    canonical_input =
      theme
      |> Map.new()
      |> Map.take([
        :id,
        "id",
        :palette,
        "palette",
        :roles,
        "roles",
        :tokens,
        "tokens",
        :defaults,
        "defaults",
        :components,
        "components",
        :extra,
        "extra"
      ])

    canonical = CanonicalTheme.new(canonical_input)

    %__MODULE__{
      id: canonical.id || fetch(theme, :id, :live_ui),
      canonical: canonical,
      native: normalize_native(fetch(theme, :native, %{}))
    }
  end

  @spec canonical(t() | keyword() | map() | nil) :: CanonicalTheme.t()
  def canonical(theme) do
    theme
    |> new()
    |> Map.fetch!(:canonical)
  end

  @spec resolve_style(t() | keyword() | map() | nil, component_key() | nil, keyword() | map()) ::
          CanonicalStyle.t()
  def resolve_style(theme, component, opts \\ []) do
    theme
    |> canonical()
    |> CanonicalTheme.resolve_style(component, opts)
  end

  @spec component_profile(t() | keyword() | map() | nil, component_key()) ::
          native_component_profile()
  def component_profile(theme, component) do
    component = normalize_component_key(component)

    theme
    |> new()
    |> get_in([Access.key(:native), Access.key(:components), component])
    |> normalize_component_profile()
  end

  @spec token(
          t() | keyword() | map() | nil,
          [UnifiedIUR.Token.path_segment()] | UnifiedIUR.Token.path_segment()
        ) ::
          term() | nil
  def token(theme, path) do
    theme
    |> canonical()
    |> CanonicalTheme.token(path)
  end

  defp normalize_native(native) when is_map(native) do
    %{
      components:
        native
        |> fetch(:components, %{})
        |> normalize_components()
    }
  end

  defp normalize_native(_other), do: %{components: %{}}

  defp normalize_components(components) when is_map(components) do
    Map.new(components, fn {component, profile} ->
      {normalize_component_key(component), normalize_component_profile(profile)}
    end)
  end

  defp normalize_component_key(component) when is_binary(component), do: String.to_atom(component)
  defp normalize_component_key(component), do: component

  defp normalize_component_profile(nil), do: %{}

  defp normalize_component_profile(profile) when is_map(profile) do
    profile = Map.new(profile)

    %{}
    |> maybe_put(:tone, fetch(profile, :tone))
    |> maybe_put(:variant, fetch(profile, :variant))
    |> maybe_put(:state, fetch(profile, :state))
    |> maybe_put(:class, normalize_class(fetch(profile, :class)))
    |> maybe_put(:attrs, normalize_attrs(fetch(profile, :attrs, %{})))
    |> maybe_put(:variant_classes, normalize_class_map(fetch(profile, :variant_classes, %{})))
    |> maybe_put(:state_classes, normalize_class_map(fetch(profile, :state_classes, %{})))
  end

  defp normalize_class_map(class_map) when is_map(class_map) do
    Map.new(class_map, fn {key, value} -> {key, normalize_class(value)} end)
  end

  defp normalize_attrs(attrs) when is_map(attrs),
    do: Map.new(attrs, fn {k, v} -> {to_string(k), to_string(v)} end)

  defp normalize_attrs(_other), do: %{}

  defp normalize_class(nil), do: nil
  defp normalize_class(value), do: value |> to_string() |> String.trim()

  defp fetch(source, key, default \\ nil) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, %{} = value) when map_size(value) == 0, do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
