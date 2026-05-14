defmodule UnifiedIUR.InteractionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Interactions

  test "exposes canonical interaction and binding modules" do
    assert %{
             interaction: Interaction,
             binding: Binding,
             transport: UnifiedIUR.Interactions.Transport
           } =
             Interactions.modules()

    assert [:click, :change, :submit, :open, :close, :selection, :focus, :navigation, :command] ==
             Interaction.families()

    assert [:navigate_to, :replace_with, :go_back, :go_forward, :open_modal, :close_modal] ==
             Interaction.navigation_actions()

    assert [:screen_transition, :replace_transition, :history_transition, :modal_transition] ==
             Interaction.navigation_kinds()
  end

  test "builds standard interaction descriptor families with canonical source, target, and payload metadata" do
    click =
      Interaction.click(
        intent: :open_settings,
        element_id: "settings-button",
        path: [:settings],
        mapping: %{label: :label}
      )

    submit =
      Interaction.submit(
        intent: :save_profile,
        element_id: "profile-form",
        binding: [:profile],
        propagation: :bubble
      )

    command =
      Interaction.command(
        intent: :open_file,
        element_id: "command-palette",
        command: :open_file,
        transient?: true
      )

    assert %Interaction{
             family: :click,
             intent: :open_settings,
             source: %{element_id: "settings-button"},
             target: %{path: [:settings]},
             payload: %{mapping: %{label: :label}}
           } = click

    assert %Interaction{
             family: :submit,
             target: %{binding: [:profile]},
             metadata: %{propagation: :bubble}
           } = submit

    assert %Interaction{
             family: :command,
             payload: %{command: :open_file},
             metadata: %{transient?: true}
           } = command
  end

  test "normalizes canonical navigation transition descriptors without fake screen ids" do
    screen_transition =
      Interaction.navigation_transition(
        intent: :open_settings_screen,
        element_id: "settings-link",
        scope: :screen,
        action: :navigate_to,
        screen: :settings,
        params: %{tab: :profile}
      )

    history_transition =
      Interaction.navigation_transition(
        intent: :go_back_history,
        element_id: "back-button",
        scope: :screen,
        action: :go_back,
        metadata: %{source: :header}
      )

    replacement =
      Interaction.new(%{
        family: :navigation,
        intent: :replace_home_screen,
        target: %{
          "navigation" => %{
            "action" => "replace_with",
            "screen" => :home,
            "params" => %{"source" => :launcher}
          }
        }
      })

    assert %Interaction{
             family: :navigation,
             intent: :open_settings_screen,
             source: %{element_id: "settings-link", scope: :screen},
             target: %{
               navigation: %{
                 action: :navigate_to,
                 kind: :screen_transition,
                 params: %{tab: :profile},
                 screen: :settings
               }
             }
           } = screen_transition

    assert Interaction.navigation_descriptor(screen_transition) == %{
             action: :navigate_to,
             kind: :screen_transition,
             params: %{tab: :profile},
             screen: :settings
           }

    assert %Interaction{
             intent: :go_back_history,
             target: %{
               navigation: %{
                 action: :go_back,
                 kind: :history_transition,
                 metadata: %{source: :header}
               }
             }
           } = history_transition

    refute Map.has_key?(Interaction.navigation_descriptor(history_transition), :screen)
    refute Map.has_key?(Interaction.navigation_descriptor(history_transition), :modal)

    assert Interaction.navigation_descriptor(replacement) == %{
             action: "replace_with",
             kind: :replace_transition,
             params: %{"source" => :launcher},
             screen: :home
           }

    modal_push =
      Interaction.navigation_transition(
        intent: :open_confirm_modal,
        action: :open_modal,
        modal: :settings_confirm_dialog,
        modal_stack: [
          operation: :push,
          target: :symbolic_modal,
          target_required?: true,
          named_target_allowed?: true,
          containment_required?: false,
          stack_effect: :push_modal
        ]
      )

    assert Interaction.navigation_descriptor(modal_push) == %{
             action: :open_modal,
             kind: :modal_transition,
             modal: :settings_confirm_dialog,
             modal_stack: %{
               operation: :push,
               target: :symbolic_modal,
               target_required?: true,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :push_modal
             }
           }
  end

  test "builds bindings with source paths, dependencies, and derived-value metadata" do
    binding =
      Binding.new(
        name: :email,
        path: [:profile, :email],
        value: "user@example.com",
        format: :string,
        source: :form
      )
      |> Binding.put_dependency([:profile, :account_id], source: :session)
      |> Binding.put_derived(:normalized, %{trim?: true, lowercase?: true})

    assert %Binding{
             name: :email,
             path: [:profile, :email],
             value: "user@example.com",
             format: :string,
             source: :form,
             depends_on: [%{path: [:profile, :account_id], source: :session}],
             derived: %{normalized: %{trim?: true, lowercase?: true}}
           } = binding
  end
end
