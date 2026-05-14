defmodule UnifiedUi.CompilerTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Reference
  alias UnifiedUi.Compiler

  defmodule CompiledScreen do
    use UnifiedUi.Dsl

    identity do
      id(:compiled_screen)
      title("Compiled Screen")
      authored_ref([:tests, :compiled_screen])
      tags([:compiler, :phase_5])
    end

    composition do
      root(:compiled_screen_root)
      mode(:screen)
      summary("Compiler baseline screen")

      box :shell do
        text :headline do
          value("Compiler baseline")
        end

        button :primary_action do
          label("Continue")
          action_intent(:continue)
        end
      end

      row :shortcut_bar do
        menu :main_menu do
          items(home: "Home", docs: "Docs")
          active_item(:home)
        end

        link :docs_link do
          label("Open docs")
          target("https://specled.dev/home")
        end
      end
    end
  end

  defmodule SignalWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:signal_workspace)
      title("Signal Workspace")
      authored_ref([:tests, :signal_workspace])
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
        interaction_refs([:profile_submit])
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
    end
  end

  defmodule NavigationWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:navigation_workspace)
      title("Navigation Workspace")
      authored_ref([:tests, :navigation_workspace])
    end

    composition do
      root(:navigation_workspace_root)
      mode(:screen)

      tabs :dashboard_tabs do
        items(overview: "Overview", activity: "Activity")
        active_item(:overview)
        interaction_refs([:navigate_activity])
      end

      button :settings_link do
        label("Settings")
        interaction_refs([:open_settings_screen])
      end

      button :replace_home do
        label("Home")
        interaction_refs([:replace_home_screen])
      end

      button :back_button do
        label("Back")
        interaction_refs([:go_back_history])
      end

      button :forward_button do
        label("Forward")
        interaction_refs([:go_forward_history])
      end

      button :open_settings_modal_button do
        label("Open settings modal")
        interaction_refs([:open_settings_modal])
      end

      button :open_confirm_modal_button do
        label("Open confirm modal")
        interaction_refs([:open_confirm_modal])
      end

      button :close_top_modal_button do
        label("Close top modal")
        interaction_refs([:close_top_modal])
      end

      button :close_settings_modal_button do
        label("Close settings modal")
        interaction_refs([:close_settings_modal])
      end
    end

    signals do
      namespace(:workspace)

      data_binding do
        id(:active_tab)
        path([:navigation, :active_tab])
        scope([:screen])
        default(:overview)
      end

      interaction do
        id(:navigate_activity)
        family(:navigation)
        intent(:navigate_activity)
        source_context(element_id: :dashboard_tabs)
        target_intent(binding: :active_tab, destination: :activity)
        payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
      end

      interaction do
        id(:open_settings_screen)
        family(:navigation)
        intent(:open_settings_screen)
        source_context(element_id: :settings_link, scope: :screen)
        target_intent(action: :navigate_to, screen: :settings, params: %{tab: :profile})
        payload_mapping(tab: :profile)
      end

      interaction do
        id(:replace_home_screen)
        family(:navigation)
        intent(:replace_home_screen)
        source_context(element_id: :replace_home, scope: :screen)
        target_intent(action: :replace_with, screen: :home, params: %{source: :launcher})
        payload_mapping(source: :launcher)
      end

      interaction do
        id(:go_back_history)
        family(:navigation)
        intent(:go_back_history)
        source_context(element_id: :back_button, scope: :screen)
        target_intent(action: :go_back, metadata: %{source: :header})
        payload_mapping(source: :header)
      end

      interaction do
        id(:go_forward_history)
        family(:navigation)
        intent(:go_forward_history)
        source_context(element_id: :forward_button, scope: :screen)
        target_intent(action: :go_forward, metadata: %{source: :header})
        payload_mapping(source: :header)
      end

      interaction do
        id(:open_settings_modal)
        family(:navigation)
        intent(:open_settings_modal)
        source_context(element_id: :open_settings_modal_button, scope: :screen)
        target_intent(action: :open_modal, modal: :settings_dialog, params: %{source: :button})
        payload_mapping(source: :button)
      end

      interaction do
        id(:open_confirm_modal)
        family(:navigation)
        intent(:open_confirm_modal)
        source_context(element_id: :open_confirm_modal_button, scope: :modal)

        target_intent(
          action: :open_modal,
          modal: :confirm_dialog,
          params: %{from: :settings_dialog}
        )

        payload_mapping(source: :settings_dialog)
      end

      interaction do
        id(:close_top_modal)
        family(:navigation)
        intent(:close_top_modal)
        source_context(element_id: :close_top_modal_button, scope: :modal)
        target_intent(action: :close_modal, metadata: %{reason: :dismiss})
        payload_mapping(reason: :dismiss)
      end

      interaction do
        id(:close_settings_modal)
        family(:navigation)
        intent(:close_settings_modal)
        source_context(element_id: :close_settings_modal_button, scope: :modal)
        target_intent(action: :close_modal, modal: :settings_dialog, metadata: %{reason: :done})
        payload_mapping(reason: :done)
      end
    end
  end

  test "compiles authored modules into canonical result structs and root IUR output" do
    {:ok, result} = Compiler.compile(CompiledScreen)

    assert result.module == CompiledScreen
    assert result.identity.id == :compiled_screen
    assert result.composition.root == :compiled_screen_root
    assert result.iur.id == :compiled_screen_root
    assert result.iur.type == :composite
    assert result.iur.kind == :screen

    assert Enum.map(result.iur.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [
             {:default, :shell, :box},
             {:default, :shortcut_bar, :row}
           ]

    assert Compiler.iur!(CompiledScreen).id == :compiled_screen_root

    assert Compiler.summary(CompiledScreen) == %{
             module: CompiledScreen,
             identity_id: :compiled_screen,
             authored_ref: [:tests, :compiled_screen],
             root_id: :compiled_screen_root,
             mode: :screen,
             default_theme: nil,
             top_level_children: [
               %{slot: :default, id: :shell, type: :layout, kind: :box},
               %{slot: :default, id: :shortcut_bar, type: :layout, kind: :row}
             ],
             theme_ids: [],
             binding_names: [],
             interaction_families: [],
             interaction_intents: [],
             trace: %{
               authored_ids: [
                 :docs_link,
                 :headline,
                 :main_menu,
                 :primary_action,
                 :shell,
                 :shortcut_bar
               ],
               binding_ids: [],
               interaction_ids: [],
               theme_ids: []
             }
           }

    assert Reference.summarize_tree(result.iur) == %{
             total_elements: 7,
             element_ids: [
               :compiled_screen_root,
               :shell,
               :headline,
               :primary_action,
               :shortcut_bar,
               :main_menu,
               :docs_link
             ],
             type_histogram: %{composite: 1, layout: 2, widget: 4},
             shape_signature: %{
               type: :composite,
               kind: :screen,
               child_shape: :multi,
               slots: [
                 %{
                   slot: :default,
                   present?: true,
                   child: %{
                     type: :layout,
                     kind: :box,
                     child_shape: :multi,
                     slots: [
                       %{
                         slot: :default,
                         present?: true,
                         child: %{type: :widget, kind: :text, child_shape: :leaf, slots: []}
                       },
                       %{
                         slot: :default,
                         present?: true,
                         child: %{type: :widget, kind: :button, child_shape: :leaf, slots: []}
                       }
                     ]
                   }
                 },
                 %{
                   slot: :default,
                   present?: true,
                   child: %{
                     type: :layout,
                     kind: :row,
                     child_shape: :multi,
                     slots: [
                       %{
                         slot: :default,
                         present?: true,
                         child: %{type: :widget, kind: :menu, child_shape: :leaf, slots: []}
                       },
                       %{
                         slot: :default,
                         present?: true,
                         child: %{type: :widget, kind: :link, child_shape: :leaf, slots: []}
                       }
                     ]
                   }
                 }
               ]
             }
           }
  end

  test "compiles authored bindings and interactions into canonical descriptors" do
    {:ok, result} = Compiler.compile(SignalWorkspace)

    assert result.bindings == [
             %UnifiedIUR.Binding{
               name: :profile_form_data,
               path: [:profile],
               scope: [:screen],
               default: %{display_name: "", role: :member},
               metadata: %{authored_id: :profile_form_data, summary: nil}
             }
           ]

    assert Enum.map(result.interactions, &{&1.family, &1.intent}) == [
             {:change, :update_profile},
             {:submit, :save_profile}
           ]

    assert Enum.map(result.iur.attributes.bindings, &{&1.name, &1.path}) == [
             {:profile_form_data, [:profile]}
           ]

    assert Enum.map(result.iur.attributes.interactions, &{&1.family, &1.intent}) == [
             {:change, :update_profile},
             {:submit, :save_profile}
           ]

    assert result.trace.binding_by_id[:profile_form_data].path == [:profile]

    assert result.trace.interaction_by_id[:profile_submit] == %UnifiedIUR.Interaction{
             family: :submit,
             intent: :save_profile,
             source: %{element_id: :save_button, scope: :screen},
             target: %{
               binding: %{
                 id: :profile_form_data,
                 kind: :binding_ref,
                 name: :profile_form_data,
                 path: [:profile],
                 scope: [:screen]
               },
               entity: :profile
             },
             payload: %{
               action: :save,
               profile: %{
                 id: :profile_form_data,
                 kind: :binding_ref,
                 name: :profile_form_data,
                 path: [:profile],
                 scope: [:screen]
               }
             },
             metadata: %{
               summary: nil,
               authored_id: :profile_submit,
               binding_refs: [
                 %{
                   id: :profile_form_data,
                   kind: :binding_ref,
                   name: :profile_form_data,
                   path: [:profile],
                   scope: [:screen]
                 }
               ]
             }
           }
  end

  test "lowers canonical navigation transitions into stable interaction target descriptors" do
    {:ok, result} = Compiler.compile(NavigationWorkspace)
    {:ok, result_again} = Compiler.compile(NavigationWorkspace)

    assert result.interactions == result_again.interactions
    assert Reference.snapshot(result.iur) == Reference.snapshot(result_again.iur)

    assert result.trace.interaction_by_id[:navigate_activity] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :navigate_activity,
             source: %{element_id: :dashboard_tabs},
             target: %{
               binding: %{
                 id: :active_tab,
                 kind: :binding_ref,
                 name: :active_tab,
                 path: [:navigation, :active_tab],
                 scope: [:screen]
               },
               destination: :activity
             },
             payload: %{
               destination: :activity,
               tab: %{
                 id: :active_tab,
                 kind: :binding_ref,
                 name: :active_tab,
                 path: [:navigation, :active_tab],
                 scope: [:screen]
               }
             },
             metadata: %{authored_id: :navigate_activity, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:open_settings_screen] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :open_settings_screen,
             source: %{element_id: :settings_link, scope: :screen},
             target: %{
               navigation: %{
                 action: :navigate_to,
                 kind: :screen_transition,
                 params: %{tab: :profile},
                 screen: :settings
               }
             },
             payload: %{tab: :profile},
             metadata: %{authored_id: :open_settings_screen, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:replace_home_screen] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :replace_home_screen,
             source: %{element_id: :replace_home, scope: :screen},
             target: %{
               navigation: %{
                 action: :replace_with,
                 kind: :replace_transition,
                 params: %{source: :launcher},
                 screen: :home
               }
             },
             payload: %{source: :launcher},
             metadata: %{authored_id: :replace_home_screen, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:go_back_history] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :go_back_history,
             source: %{element_id: :back_button, scope: :screen},
             target: %{
               navigation: %{
                 action: :go_back,
                 kind: :history_transition,
                 metadata: %{source: :header}
               }
             },
             payload: %{source: :header},
             metadata: %{authored_id: :go_back_history, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:go_forward_history] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :go_forward_history,
             source: %{element_id: :forward_button, scope: :screen},
             target: %{
               navigation: %{
                 action: :go_forward,
                 kind: :history_transition,
                 metadata: %{source: :header}
               }
             },
             payload: %{source: :header},
             metadata: %{authored_id: :go_forward_history, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:open_settings_modal] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :open_settings_modal,
             source: %{element_id: :open_settings_modal_button, scope: :screen},
             target: %{
               navigation: %{
                 action: :open_modal,
                 kind: :modal_transition,
                 modal_stack: modal_stack_push(),
                 modal: :settings_dialog,
                 params: %{source: :button}
               }
             },
             payload: %{source: :button},
             metadata: %{authored_id: :open_settings_modal, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:open_confirm_modal] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :open_confirm_modal,
             source: %{element_id: :open_confirm_modal_button, scope: :modal},
             target: %{
               navigation: %{
                 action: :open_modal,
                 kind: :modal_transition,
                 modal_stack: modal_stack_push(),
                 modal: :confirm_dialog,
                 params: %{from: :settings_dialog}
               }
             },
             payload: %{source: :settings_dialog},
             metadata: %{authored_id: :open_confirm_modal, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:close_top_modal] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :close_top_modal,
             source: %{element_id: :close_top_modal_button, scope: :modal},
             target: %{
               navigation: %{
                 action: :close_modal,
                 kind: :modal_transition,
                 modal_stack: modal_stack_close(),
                 metadata: %{reason: :dismiss}
               }
             },
             payload: %{reason: :dismiss},
             metadata: %{authored_id: :close_top_modal, binding_refs: [], summary: nil}
           }

    assert result.trace.interaction_by_id[:close_settings_modal] == %UnifiedIUR.Interaction{
             family: :navigation,
             intent: :close_settings_modal,
             source: %{element_id: :close_settings_modal_button, scope: :modal},
             target: %{
               navigation: %{
                 action: :close_modal,
                 kind: :modal_transition,
                 modal_stack: modal_stack_close(),
                 metadata: %{reason: :done},
                 modal: :settings_dialog
               }
             },
             payload: %{reason: :done},
             metadata: %{authored_id: :close_settings_modal, binding_refs: [], summary: nil}
           }

    assert Enum.map(result.iur.attributes.interactions, &{&1.intent, &1.target}) == [
             {:navigate_activity,
              %{
                binding: %{
                  id: :active_tab,
                  kind: :binding_ref,
                  name: :active_tab,
                  path: [:navigation, :active_tab],
                  scope: [:screen]
                },
                destination: :activity
              }},
             {:open_settings_screen,
              %{
                navigation: %{
                  action: :navigate_to,
                  kind: :screen_transition,
                  params: %{tab: :profile},
                  screen: :settings
                }
              }},
             {:replace_home_screen,
              %{
                navigation: %{
                  action: :replace_with,
                  kind: :replace_transition,
                  params: %{source: :launcher},
                  screen: :home
                }
              }},
             {:go_back_history,
              %{
                navigation: %{
                  action: :go_back,
                  kind: :history_transition,
                  metadata: %{source: :header}
                }
              }},
             {:go_forward_history,
              %{
                navigation: %{
                  action: :go_forward,
                  kind: :history_transition,
                  metadata: %{source: :header}
                }
              }},
             {:open_settings_modal,
              %{
                navigation: %{
                  action: :open_modal,
                  kind: :modal_transition,
                  modal_stack: modal_stack_push(),
                  modal: :settings_dialog,
                  params: %{source: :button}
                }
              }},
             {:open_confirm_modal,
              %{
                navigation: %{
                  action: :open_modal,
                  kind: :modal_transition,
                  modal_stack: modal_stack_push(),
                  modal: :confirm_dialog,
                  params: %{from: :settings_dialog}
                }
              }},
             {:close_top_modal,
              %{
                navigation: %{
                  action: :close_modal,
                  kind: :modal_transition,
                  modal_stack: modal_stack_close(),
                  metadata: %{reason: :dismiss}
                }
              }},
             {:close_settings_modal,
              %{
                navigation: %{
                  action: :close_modal,
                  kind: :modal_transition,
                  modal_stack: modal_stack_close(),
                  metadata: %{reason: :done},
                  modal: :settings_dialog
                }
              }}
           ]
  end

  defp modal_stack_push do
    %{
      operation: :push,
      target: :symbolic_modal,
      target_required?: true,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :push_modal
    }
  end

  defp modal_stack_close do
    %{
      operation: :close,
      target: :topmost_modal,
      target_required?: false,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :close_topmost_or_named_modal
    }
  end
end
