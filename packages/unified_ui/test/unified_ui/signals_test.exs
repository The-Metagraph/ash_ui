defmodule UnifiedUi.SignalsTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Info
  alias UnifiedUi.Signals

  defmodule SignalWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:signal_workspace)
      title("Signal Workspace")
      authored_ref([:examples, :signal_workspace])
    end

    composition do
      root(:signal_workspace_root)
      mode(:screen)

      form_builder :profile_form do
        binding_refs([:profile_form_data])
        interaction_refs([:profile_change, :profile_submit])
      end

      button :save_button do
        label("Save")

        interaction_refs([
          :profile_submit,
          :open_commands,
          :open_settings_screen,
          :open_settings_modal
        ])
      end

      tabs :dashboard_tabs do
        items(profile: "Profile", activity: "Activity")
        active_item(:profile)
        interaction_refs([:navigate_activity])
      end
    end

    signals do
      namespace(:workspace)
      default_target(:session)

      data_binding do
        id(:profile_form_data)
        path([:profile])
        scope([:screen])
        default(%{display_name: "", role: :member})
        derived(%{source: :form_builder})
      end

      data_binding do
        id(:active_tab)
        path([:navigation, :active_tab])
        scope([:screen])
        default(:profile)
      end

      interaction do
        id(:profile_change)
        family(:change)
        intent(:update_profile)
        source_context(element_id: :profile_form, scope: :screen)
        target_intent(binding: :profile_form_data, entity: :profile)
        payload_mapping(profile: binding_ref(:profile_form_data), phase: :draft)
      end

      interaction do
        id(:profile_submit)
        family(:submit)
        intent(:save_profile)
        source_context(element_id: :save_button, scope: :screen)
        target_intent(binding: :profile_form_data, entity: :profile)
        payload_mapping(profile: binding_ref(:profile_form_data), action: :save)
        binding_refs([:profile_form_data])
      end

      interaction do
        id(:open_commands)
        family(:command)
        intent(:open_command_palette)
        source_context(element_id: :save_button)
        target_intent(command: :workspace_palette)
        payload_mapping(source: :keyboard_shortcut)
      end

      interaction do
        id(:navigate_activity)
        family(:navigation)
        intent(:navigate_profile_workspace)
        source_context(element_id: :dashboard_tabs, scope: :screen)
        target_intent(binding: :active_tab, destination: :activity)
        payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
      end

      interaction do
        id(:open_settings_screen)
        family(:navigation)
        intent(:open_settings_screen)
        source_context(element_id: :save_button, scope: :screen)

        target_intent(
          action: :navigate_to,
          screen: :settings,
          params: [tab: :profile],
          metadata: [source: :save_button]
        )

        payload_mapping(tab: :profile)
      end

      interaction do
        id(:open_settings_modal)
        family(:navigation)
        intent(:open_settings_modal)
        source_context(element_id: :save_button, scope: :screen)

        target_intent(
          action: :open_modal,
          modal: :settings_dialog,
          params: [tab: :profile],
          metadata: [source: :save_button]
        )

        payload_mapping(tab: :profile)
      end
    end
  end

  test "authors canonical bindings and interactions through the signals section" do
    assert Enum.map(Signals.bindings(SignalWorkspace), & &1.id) == [
             :profile_form_data,
             :active_tab
           ]

    assert Enum.map(Signals.interactions(SignalWorkspace), & &1.id) == [
             :profile_change,
             :profile_submit,
             :open_commands,
             :navigate_activity,
             :open_settings_screen,
             :open_settings_modal
           ]
  end

  test "summarizes module signal configuration and supported families" do
    assert Signals.families() == [
             :click,
             :change,
             :submit,
             :open,
             :close,
             :focus,
             :selection,
             :navigation,
             :command
           ]

    assert Signals.navigation_actions() == [
             :navigate_to,
             :replace_with,
             :go_back,
             :go_forward,
             :open_modal,
             :close_modal
           ]

    assert Signals.navigation_transition_fields() == [
             :action,
             :screen,
             :modal,
             :params,
             :metadata
           ]

    assert Signals.local_navigation_fields() == [:binding, :destination]

    assert Signals.navigation_modal_stack_semantics() == %{
             open_modal: %{
               operation: :push,
               target: :symbolic_modal,
               target_required?: true,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :push_modal
             },
             close_modal: %{
               operation: :close,
               target: :topmost_modal,
               target_required?: false,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :close_topmost_or_named_modal
             }
           }

    assert Signals.navigation_action_contracts() == %{
             navigate_to: %{
               kind: :screen_transition,
               required_fields: [:screen],
               optional_fields: [:params, :metadata]
             },
             replace_with: %{
               kind: :replace_transition,
               required_fields: [:screen],
               optional_fields: [:params, :metadata]
             },
             go_back: %{
               kind: :history_transition,
               required_fields: [],
               optional_fields: [:metadata]
             },
             go_forward: %{
               kind: :history_transition,
               required_fields: [],
               optional_fields: [:metadata]
             },
             open_modal: %{
               kind: :modal_transition,
               required_fields: [:modal],
               optional_fields: [:params, :metadata]
             },
             close_modal: %{
               kind: :modal_transition,
               required_fields: [],
               optional_fields: [:modal, :metadata]
             }
           }

    assert Signals.module_summary(SignalWorkspace) == %{
             namespace: :workspace,
             default_target: :session,
             mode: :canonical,
             families: [
               :click,
               :change,
               :submit,
               :open,
               :close,
               :focus,
               :selection,
               :navigation,
               :command
             ],
             bindings: [
               %{
                 id: :profile_form_data,
                 path: [:profile],
                 scope: [:screen],
                 default: %{display_name: "", role: :member},
                 collection?: false,
                 derived: %{source: :form_builder}
               },
               %{
                 id: :active_tab,
                 path: [:navigation, :active_tab],
                 scope: [:screen],
                 default: :profile,
                 collection?: false
               }
             ],
             interactions: [
               %{
                 id: :profile_change,
                 family: :change,
                 intent: :update_profile,
                 source_context: %{element_id: :profile_form, scope: :screen},
                 target_intent: %{binding: :profile_form_data, entity: :profile},
                 payload_mapping: %{
                   profile: %{kind: :binding_ref, id: :profile_form_data},
                   phase: :draft
                 }
               },
               %{
                 id: :profile_submit,
                 family: :submit,
                 intent: :save_profile,
                 source_context: %{element_id: :save_button, scope: :screen},
                 target_intent: %{binding: :profile_form_data, entity: :profile},
                 payload_mapping: %{
                   profile: %{kind: :binding_ref, id: :profile_form_data},
                   action: :save
                 },
                 binding_refs: [%{kind: :binding_ref, id: :profile_form_data}]
               },
               %{
                 id: :open_commands,
                 family: :command,
                 intent: :open_command_palette,
                 source_context: %{element_id: :save_button},
                 target_intent: %{command: :workspace_palette},
                 payload_mapping: %{source: :keyboard_shortcut}
               },
               %{
                 id: :navigate_activity,
                 family: :navigation,
                 intent: :navigate_profile_workspace,
                 source_context: %{element_id: :dashboard_tabs, scope: :screen},
                 target_intent: %{binding: :active_tab, destination: :activity},
                 payload_mapping: %{
                   tab: %{kind: :binding_ref, id: :active_tab},
                   destination: :activity
                 }
               },
               %{
                 id: :open_settings_screen,
                 family: :navigation,
                 intent: :open_settings_screen,
                 source_context: %{element_id: :save_button, scope: :screen},
                 target_intent: %{
                   action: :navigate_to,
                   screen: :settings,
                   params: %{tab: :profile},
                   metadata: %{source: :save_button}
                 },
                 payload_mapping: %{tab: :profile}
               },
               %{
                 id: :open_settings_modal,
                 family: :navigation,
                 intent: :open_settings_modal,
                 source_context: %{element_id: :save_button, scope: :screen},
                 target_intent: %{
                   action: :open_modal,
                   modal: :settings_dialog,
                   params: %{tab: :profile},
                   metadata: %{source: :save_button}
                 },
                 payload_mapping: %{tab: :profile}
               }
             ],
             navigation_descriptors: [
               %{
                 id: :navigate_activity,
                 kind: :local_destination,
                 binding: :active_tab,
                 destination: :activity
               },
               %{
                 id: :open_settings_modal,
                 kind: :modal_transition,
                 action: :open_modal,
                 modal: :settings_dialog,
                 params: %{tab: :profile},
                 metadata: %{source: :save_button},
                 modal_stack: %{
                   operation: :push,
                   target: :symbolic_modal,
                   target_required?: true,
                   named_target_allowed?: true,
                   containment_required?: false,
                   stack_effect: :push_modal
                 }
               },
               %{
                 id: :open_settings_screen,
                 kind: :screen_transition,
                 action: :navigate_to,
                 screen: :settings,
                 params: %{tab: :profile},
                 metadata: %{source: :save_button}
               }
             ]
           }
  end

  test "distinguishes local destinations from top-level screen transitions" do
    [
      profile_change,
      profile_submit,
      open_commands,
      navigate_activity,
      open_settings_screen,
      open_settings_modal
    ] =
      Signals.interactions(SignalWorkspace)

    assert Signals.navigation_target_kind(profile_change) == :generic
    assert Signals.navigation_target_kind(profile_submit) == :generic
    assert Signals.navigation_target_kind(open_commands) == :generic
    assert Signals.navigation_target_kind(navigate_activity) == :local_destination
    assert Signals.navigation_target_kind(open_settings_screen) == :screen_transition
    assert Signals.navigation_target_kind(open_settings_modal) == :modal_transition

    assert Signals.navigation_target_kind(%{
             target_intent: %{action: :replace_with, screen: :login}
           }) ==
             :replace_transition

    assert Signals.navigation_target_kind(%{target_intent: %{action: :go_back}}) ==
             :history_transition

    assert Signals.navigation_descriptor(target_intent: [action: :close_modal]) == %{
             id: nil,
             kind: :modal_transition,
             action: :close_modal,
             modal_stack: %{
               operation: :close,
               target: :topmost_modal,
               target_required?: false,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :close_topmost_or_named_modal
             }
           }
  end

  test "attaches authored signal and binding references to composition nodes" do
    [profile_form, save_button, dashboard_tabs] = Info.composition_nodes(SignalWorkspace)

    assert profile_form.binding_refs == [:profile_form_data]
    assert profile_form.interaction_refs == [:profile_change, :profile_submit]

    assert save_button.interaction_refs == [
             :profile_submit,
             :open_commands,
             :open_settings_screen,
             :open_settings_modal
           ]

    assert dashboard_tabs.interaction_refs == [:navigate_activity]
  end

  test "exposes canonical signal families through the reference surface" do
    assert UnifiedUi.Reference.signal_families() == Signals.families()
  end
end
