defmodule UnifiedIUR.ThemeTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Style
  alias UnifiedIUR.Theme
  alias UnifiedIUR.Token

  test "builds theme identity, palette, semantic roles, and component variants" do
    theme =
      Theme.new(
        id: :default,
        palette: %{
          primary: {:rgb, 10, 20, 30},
          muted: {:indexed, 7}
        },
        roles: %{
          success: :green,
          warning: Token.ref([:palette, :muted])
        },
        defaults: %{foreground: :primary},
        components: %{
          button: %{
            default: %{background: :primary},
            variants: %{primary: %{text: %{bold?: true}}},
            states: %{focused: %{border_color: :focus}}
          }
        }
      )

    assert %Theme{
             id: :default,
             palette: %{
               primary: %{mode: :rgb, red: 10, green: 20, blue: 30},
               muted: %{mode: :indexed, index: 7}
             },
             roles: %{
               success: %{mode: :named, name: :green},
               warning: %{kind: :token_ref, path: [:palette, :muted]}
             },
             components: %{
               button: %{
                 default: %Style{background: %{mode: :named, name: :primary}},
                 variants: %{primary: %Style{text: %{bold?: true}}},
                 states: %{focused: %Style{border_color: %{mode: :named, name: :focus}}}
               }
             }
           } = theme
  end

  test "stores and resolves reusable token-backed styles" do
    theme =
      Theme.new(id: :default)
      |> Theme.put_token([:styles, :card], %{background: :surface, border: %{style: :solid}})
      |> Theme.put_token([:styles, :accent], %{foreground: :accent, emphasis: %{tone: :strong}})

    assert %Style{background: %{mode: :named, name: :surface}, border: %{style: :solid}} =
             Theme.token(theme, [:styles, :card])

    assert %Style{foreground: %{mode: :named, name: :accent}} =
             Theme.token(theme, [:styles, :accent])
  end

  test "resolves styles through theme defaults, component variants, state overrides, token refs, and local overrides" do
    theme =
      Theme.new(
        defaults: %{foreground: :base_fg, spacing: %{padding: 1}},
        tokens: %{
          "styles.card" => %{background: :surface, border: %{style: :solid}},
          "styles.focus" => %{border_color: :focus}
        },
        components: %{
          button: %{
            default: %{background: :primary},
            variants: %{primary: %{text: %{bold?: true}}},
            states: %{focused: %{border_color: :focus_default}}
          }
        }
      )

    resolved =
      Theme.resolve_style(theme, :button,
        variant: :primary,
        state: :focused,
        token_refs: [Token.ref([:styles, :card]), Token.ref([:styles, :focus])],
        local_style: %{foreground: :override_fg, emphasis: %{tone: :accent}}
      )

    assert %Style{
             foreground: %{mode: :named, name: :override_fg},
             background: %{mode: :named, name: :primary},
             spacing: %{padding: 1},
             border: %{style: :solid},
             border_color: %{mode: :named, name: :focus_default},
             emphasis: %{tone: :accent},
             text: %{bold?: true}
           } = resolved
  end
end
