defmodule UnifiedUi.CompilerResolutionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Reference, Theme}
  alias UnifiedUi.Compiler

  defmodule ThemedWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:themed_workspace)
      title("Themed Workspace")
      authored_ref([:tests, :themed_workspace])
    end

    themes do
      default_theme(:workspace_dark)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
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
          id(:panel_shell)

          value(
            style_value(
              background: token_ref(:surface),
              spacing: %{padding: 2, gap: 1},
              border: %{width: 1, style: :solid}
            )
          )
        end

        component_style do
          id(:panel_shell)
          component(:box)

          style(
            style_value(
              token_refs: [token_ref(:panel_shell)],
              foreground: role_ref(:primary_text)
            )
          )
        end
      end

      theme do
        id(:workspace_dark)
        extends(:workspace)

        component_style do
          id(:primary_button)
          component(:button)
          variant(:primary)
          state(:focused)

          style(
            style_value(
              border_color: token_ref(:accent),
              emphasis: %{tone: :info}
            )
          )
        end
      end
    end

    composition do
      root(:themed_workspace_root)
      mode(:screen)

      box :shell do
        theme_ref(:workspace_dark)
        style_refs([:panel_shell])

        style(
          style_value(
            sizing: %{width: :fill},
            state_variants: %{
              focused: style_value(border_color: token_ref(:accent))
            }
          )
        )

        text :headline do
          value("Resolved styles")

          style(
            style_value(
              foreground: role_ref(:primary_text),
              typography: %{font_weight: :bold}
            )
          )
        end

        button :primary_action do
          label("Continue")
          theme_ref(:workspace_dark)
          style_refs([:primary_button])
        end
      end
    end
  end

  test "resolves inherited themes, style refs, semantic roles, and token references deterministically" do
    {:ok, result} = Compiler.compile(ThemedWorkspace)
    {:ok, result_again} = Compiler.compile(ThemedWorkspace)

    assert result.default_theme == :workspace_dark
    assert Enum.map(result.themes, & &1.id) == [:workspace, :workspace_dark]

    workspace_theme = Enum.find(result.themes, &(&1.id == :workspace))
    dark_theme = Enum.find(result.themes, &(&1.id == :workspace_dark))

    assert workspace_theme.palette == %{
             accent: %{mode: :named, name: :cyan},
             surface: %{mode: :named, name: :black}
           }

    assert workspace_theme.roles == %{
             primary_text: %{mode: :named, name: :white}
           }

    assert Theme.token(workspace_theme, [:panel_shell]) == %UnifiedIUR.Style{
             background: %{mode: :named, name: :black},
             spacing: %{gap: 1, padding: 2},
             border: %{style: :solid, width: 1}
           }

    assert dark_theme.palette == workspace_theme.palette
    assert dark_theme.roles == workspace_theme.roles

    [shell_child] = result.iur.children
    shell = shell_child.element
    [headline_child, button_child] = shell.children

    assert shell.attributes.theme == %{
             id: :workspace_dark,
             component: :box
           }

    assert shell.attributes.style == %UnifiedIUR.Style{
             foreground: %{mode: :named, name: :white},
             background: %{mode: :named, name: :black},
             spacing: %{gap: 1, padding: 2},
             sizing: %{width: :fill},
             border: %{style: :solid, width: 1},
             state_variants: %{
               focused: %UnifiedIUR.Style{
                 border_color: %{mode: :named, name: :cyan}
               }
             }
           }

    assert headline_child.element.attributes.style == %UnifiedIUR.Style{
             foreground: %{mode: :named, name: :white},
             text: %UnifiedIUR.Style.TextAttributes{bold?: true}
           }

    assert button_child.element.attributes.style == %UnifiedIUR.Style{
             border_color: %{mode: :named, name: :cyan},
             emphasis: %{tone: :info}
           }

    assert Reference.snapshot(result.iur) == Reference.snapshot(result_again.iur)
  end
end
