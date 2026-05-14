defmodule UnifiedUi.ThemesTest do
  use ExUnit.Case, async: true

  defmodule ThemedWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:themed_workspace)
      title("Themed Workspace")
      authored_ref([:examples, :themed_workspace])
    end

    composition do
      root(:themed_workspace_root)
      mode(:screen)
    end

    themes do
      default_theme(:workspace)
      summary("Workspace theming contract")

      theme do
        id(:workspace)
        description("Primary workspace theme")
        authored_ref([:themes, :workspace])
        summary("Default authored theme")

        palette_color do
          id(:surface)
          color(rgb_color(15, 23, 42))
        end

        palette_color do
          id(:accent)
          color(named_color(:cyan))
        end

        semantic_role do
          id(:primary_text)
          value(named_color(:white))
        end

        token do
          id(:panel_style)

          value(
            style_value(
              background: token_ref(:surface),
              spacing: %{padding: 2},
              emphasis: %{weight: :strong}
            )
          )
        end

        component_style do
          id(:primary_button)
          component(:button)
          variant(:primary)

          style(
            style_value(
              foreground: role_ref(:primary_text),
              background: token_ref(:surface),
              emphasis: %{weight: :strong}
            )
          )

          token_refs([token_ref(:panel_style)])
        end
      end
    end
  end

  test "authors canonical theme declarations through the themes section" do
    [workspace_theme] = UnifiedUi.Theme.themes(ThemedWorkspace)

    assert workspace_theme.id == :workspace
    assert workspace_theme.summary == "Default authored theme"

    assert Enum.map(UnifiedUi.Theme.palette_colors(workspace_theme), & &1.id) == [
             :surface,
             :accent
           ]

    assert Enum.map(UnifiedUi.Theme.semantic_roles(workspace_theme), & &1.id) == [:primary_text]
    assert Enum.map(UnifiedUi.Theme.tokens(workspace_theme), & &1.id) == [:panel_style]

    assert Enum.map(UnifiedUi.Theme.component_styles(workspace_theme), & &1.id) == [
             :primary_button
           ]
  end

  test "summarizes authored theme declarations without runtime packages" do
    assert UnifiedUi.Theme.module_summary(ThemedWorkspace) == %{
             default_theme: :workspace,
             inherit?: true,
             summary: "Workspace theming contract",
             themes: [
               %{
                 id: :workspace,
                 description: "Primary workspace theme",
                 authored_ref: [:themes, :workspace],
                 summary: "Default authored theme",
                 inherit?: true,
                 palette_colors: [
                   %{id: :surface, color: %{mode: :rgb, red: 15, green: 23, blue: 42}},
                   %{id: :accent, color: %{mode: :named, name: :cyan}}
                 ],
                 semantic_roles: [
                   %{id: :primary_text, value: %{mode: :named, name: :white}}
                 ],
                 tokens: [
                   %{
                     id: :panel_style,
                     value: %{
                       background: %{kind: :token_ref, path: [:surface]},
                       spacing: %{padding: 2},
                       emphasis: %{weight: :strong},
                       inherit?: true
                     }
                   }
                 ],
                 component_styles: [
                   %{
                     id: :primary_button,
                     component: :button,
                     variant: :primary,
                     style: %{
                       foreground: %{kind: :role_ref, id: :primary_text},
                       background: %{kind: :token_ref, path: [:surface]},
                       emphasis: %{weight: :strong},
                       inherit?: true
                     },
                     token_refs: [%{kind: :token_ref, path: [:panel_style]}],
                     inherit?: true
                   }
                 ]
               }
             ]
           }
  end
end
