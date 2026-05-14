defmodule UnifiedUi.StylesTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Info
  alias UnifiedUi.Style

  defmodule StyledWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:styled_workspace)
      title("Styled Workspace")
      authored_ref([:examples, :styled_workspace])
    end

    themes do
      default_theme(:workspace)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end

        semantic_role do
          id(:primary_text)
          value(named_color(:white))
        end

        component_style do
          id(:primary_shell)
          component(:box)
          style(style_value(border: %{width: 1}))
        end
      end
    end

    composition do
      root(:styled_workspace_root)
      mode(:screen)

      box :workspace_shell do
        theme_ref(:workspace)
        style_refs([:primary_shell])

        style(
          style_value(
            background: token_ref(:surface),
            spacing: %{padding: 2, gap: 1},
            sizing: %{width: :fill},
            border: %{width: 1, style: :solid},
            visibility: %{opacity: 0.95}
          )
        )

        text :headline do
          value("Styled workspace")
          variant(:headline)
          tone(:info)

          style(
            style_value(
              foreground: role_ref(:primary_text),
              typography: %{font_weight: :bold, underline?: true},
              emphasis: %{weight: :strong},
              state_variants: %{
                focused: style_value(border_color: named_color(:cyan))
              }
            )
          )
        end
      end
    end
  end

  test "reports canonical style families, roles, and states" do
    assert Style.attribute_families() == %{
             typography: [
               :font_family,
               :font_size,
               :font_weight,
               :italic?,
               :underline?,
               :blink?,
               :reverse?,
               :hidden?,
               :strikethrough?
             ],
             color: [:foreground, :background, :border_color, :role],
             spacing: [:padding, :padding_x, :padding_y, :margin, :margin_x, :margin_y, :gap],
             sizing: [:width, :height, :min_width, :min_height, :max_width, :max_height],
             alignment: [:align, :justify, :text_align, :anchor],
             border: [:width, :radius, :style, :color],
             visibility: [:hidden?, :collapsed?, :opacity],
             emphasis: [:weight, :intent, :elevation, :tone]
           }

    assert Style.semantic_roles() == [
             :success,
             :warning,
             :error,
             :info,
             :muted,
             :help,
             :placeholder
           ]

    assert Style.component_states() == [:default, :focused, :selected, :disabled, :active]
  end

  test "attaches canonical style and theme metadata to authored nodes" do
    [workspace_shell] = Info.composition_nodes(StyledWorkspace)
    [headline] = workspace_shell.children

    assert workspace_shell.theme_ref == :workspace
    assert workspace_shell.style_refs == [:primary_shell]

    assert Style.summary(workspace_shell.style) == %{
             background: %{kind: :token_ref, path: [:surface]},
             spacing: %{gap: 1, padding: 2},
             sizing: %{width: :fill},
             border: %{style: :solid, width: 1},
             visibility: %{opacity: 0.95},
             inherit?: true
           }

    assert headline.variant == :headline
    assert headline.tone == :info

    assert Style.summary(headline.style) == %{
             foreground: %{kind: :role_ref, id: :primary_text},
             typography: %{font_weight: :bold, underline?: true},
             emphasis: %{weight: :strong},
             state_variants: %{
               focused: %{border_color: %{mode: :named, name: :cyan}, inherit?: true}
             },
             inherit?: true
           }
  end

  test "surfaces canonical style metadata through package reference helpers" do
    assert Info.style_attribute_families() == UnifiedUi.Reference.style_attribute_families()
    assert UnifiedUi.Reference.semantic_style_roles() == Style.semantic_roles()
    assert UnifiedUi.Reference.style_component_states() == Style.component_states()
  end
end
