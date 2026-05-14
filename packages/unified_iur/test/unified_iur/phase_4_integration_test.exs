defmodule UnifiedIUR.Phase4IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Container
  alias UnifiedIUR.Forms
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Layer
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Style
  alias UnifiedIUR.Style.Color
  alias UnifiedIUR.Theme
  alias UnifiedIUR.Tree
  alias UnifiedIUR.Widgets.{Advanced, Foundational, Input}

  test "phase 4 styling and theme attachments compose across nested containers and overlays" do
    save_button =
      Foundational.button("Save",
        id: "save-button",
        action: [intent: :save_profile],
        theme: :workspace,
        style_refs: [:button_surface],
        variant: :primary,
        inherit_style?: true,
        style: %{
          foreground: :button_fg_override,
          state_variants: %{
            focused: %{foreground: :button_focus_override}
          }
        }
      )

    dialog =
      Layer.dialog(
        save_button,
        id: "settings-dialog",
        title: "Settings",
        theme: :workspace,
        style_refs: [:dialog_surface],
        state: :focused,
        inherit_style?: true
      )

    shell =
      Container.box(
        [
          {:content, Foundational.text("Workspace", id: "workspace-title", style_refs: [:title])},
          {:content, dialog}
        ],
        id: "workspace-shell",
        theme: :workspace,
        style_refs: [:shell_surface],
        inherit_style?: true,
        style: %{background: :shell_local}
      )

    assert %{
             style: %Style{background: %{mode: :named, name: :shell_local}},
             theme: %{
               id: :workspace,
               component: :box,
               inherit?: true,
               token_refs: [%{kind: :token_ref, path: [:shell_surface]}]
             }
           } = Tree.find_by_id(shell, "workspace-shell").attributes

    assert %{
             theme: %{
               id: :workspace,
               component: :dialog,
               inherit?: true,
               state: :focused,
               token_refs: [%{kind: :token_ref, path: [:dialog_surface]}]
             }
           } = Tree.find_by_id(shell, "settings-dialog").attributes

    assert %{
             style: %Style{
               foreground: %{mode: :named, name: :button_fg_override},
               state_variants: %{
                 focused: %Style{foreground: %{mode: :named, name: :button_focus_override}}
               }
             },
             theme: %{
               id: :workspace,
               component: :button,
               inherit?: true,
               variant: :primary,
               token_refs: [%{kind: :token_ref, path: [:button_surface]}]
             },
             interactions: [%Interaction{family: :click, intent: :save_profile}]
           } = Tree.find_by_id(shell, "save-button").attributes
  end

  test "phase 4 theme resolution yields deterministic defaults, token merges, and state variants" do
    theme = workspace_theme()

    button =
      Foundational.button("Save",
        id: "save-button",
        theme: :workspace,
        style_refs: [:button_surface],
        variant: :primary,
        style: %{
          foreground: :button_fg_override,
          state_variants: %{
            focused: %{foreground: :button_focus_override}
          }
        }
      )

    resolved_default =
      Theme.resolve_style(theme, :button,
        variant: button.attributes.theme.variant,
        token_refs: button.attributes.theme.token_refs,
        local_style: button.attributes.style
      )

    resolved_focused =
      Theme.resolve_style(theme, :button,
        variant: button.attributes.theme.variant,
        state: :focused,
        token_refs: button.attributes.theme.token_refs,
        local_style: button.attributes.style
      )

    assert resolved_default.background == Color.named(:button_surface_bg)
    assert resolved_default.border_color == Color.named(:button_primary_border)
    assert resolved_default.foreground == Color.named(:button_fg_override)

    assert resolved_focused.background == Color.named(:button_surface_bg)
    assert resolved_focused.border_color == Color.named(:button_focus_border)
    assert resolved_focused.foreground == Color.named(:button_focus_override)
    assert %Style{} = resolved_focused
  end

  test "phase 4 bindings, interactions, and nested scopes remain canonical and deterministic" do
    email_input =
      Input.text_input(
        id: "email-input",
        name: :email,
        path: [:profile, :email],
        value: "user@example.com"
      )

    group =
      Forms.field_group(
        [
          {:fields, Forms.field(email_input, id: "email-field", label: "Email")}
        ],
        id: "identity-group",
        bindings: [
          %{name: :profile, path: [:profile]},
          %{name: :session_selection, path: [:selection], scope: [:session]}
        ],
        interaction_scope: [mode: :capture, namespace: :identity]
      )

    form =
      Forms.form_builder(
        [
          {:content, group}
        ],
        id: "profile-form",
        name: :profile,
        path: [:profile],
        submit_intent: :save_profile
      )

    command_palette =
      Advanced.command_palette(
        [
          [id: :open_file, label: "Open File", value: :open_file]
        ],
        id: "workspace-command-palette",
        bindings: [
          %{name: :command_query, path: [:workspace, :command_query]},
          %{name: :active_command, path: [:workspace, :active_command]}
        ],
        interactions: [
          Interaction.command(
            intent: :open_file,
            element_id: "workspace-command-palette",
            command: :open_file
          )
        ]
      )

    screen =
      Layout.column(
        [
          {:content, form},
          {:content, command_palette}
        ],
        id: "workspace-screen"
      )

    assert %{
             interactions: [
               %Interaction{
                 family: :submit,
                 intent: :save_profile,
                 target: %{binding: [:profile]}
               }
             ]
           } = Tree.find_by_id(screen, "profile-form").attributes

    assert %{
             bindings: [
               %Binding{name: :profile, path: [:profile]},
               %Binding{name: :session_selection, path: [:selection], scope: [:session]}
             ],
             interaction_scope: %{mode: :capture, namespace: :identity}
           } = Tree.find_by_id(screen, "identity-group").attributes

    assert %{
             bindings: [
               %Binding{name: :command_query, path: [:workspace, :command_query]},
               %Binding{name: :active_command, path: [:workspace, :active_command]}
             ],
             interactions: [
               %Interaction{family: :command, intent: :open_file, payload: %{command: :open_file}}
             ]
           } = Tree.find_by_id(screen, "workspace-command-palette").attributes

    [form_interaction] = Tree.find_by_id(screen, "profile-form").attributes.interactions

    [command_interaction] =
      Tree.find_by_id(screen, "workspace-command-palette").attributes.interactions

    refute Map.has_key?(form_interaction.metadata, :callback)
    refute Map.has_key?(form_interaction.payload, :event_name)
    refute Map.has_key?(command_interaction.metadata, :channel)
    refute Map.has_key?(command_interaction.payload, :transport)
  end

  defp workspace_theme do
    Theme.new(
      id: :workspace,
      defaults: %{
        foreground: :default_fg,
        background: :default_bg
      },
      components: %{
        button: %{
          default: %{foreground: :button_default_fg},
          variants: %{
            primary: %{border_color: :button_primary_border}
          },
          states: %{
            focused: %{border_color: :button_focus_border}
          }
        }
      }
    )
    |> Theme.put_token([:button_surface], %{background: :button_surface_bg})
  end
end
