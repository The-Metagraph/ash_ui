defmodule UnifiedUi.ReferenceTest do
  use ExUnit.Case, async: true

  test "reports baseline DSL sections and extension points" do
    assert UnifiedUi.Reference.supported_sections() == [
             :identity,
             :composition,
             :themes,
             :signals
           ]

    assert UnifiedUi.Reference.dsl_sections().identity == %{
             fields: [:id, :title, :description, :authored_ref, :annotations, :tags],
             purpose:
               "Declare the authored module identity, metadata, and traceability baseline.",
             top_level?: false
           }

    assert UnifiedUi.Reference.extension_points() == %{
             identity: [:metadata_fields, :traceability_fields],
             composition: [:widget_entities, :layout_entities, :layer_entities],
             themes: [:theme_entities, :style_entities, :token_entities],
             signals: [:signal_entities, :binding_entities, :payload_entities]
           }
  end

  test "reports construct families and baseline identity and placement rules" do
    assert UnifiedUi.Reference.construct_families().widgets == [
             :foundational_visual,
             :input,
             :navigation,
             :feedback,
             :data,
             :operational,
             :content_identity_and_disclosure,
             :form_control_and_composer,
             :row_and_artifact,
             :workflow_progress_and_status,
             :layer_shell_and_callout,
             :redline_and_code,
             :composition_behavior
           ]

    assert UnifiedUi.Reference.construct_families().signals == [
             :interaction,
             :binding,
             :payload_mapping,
             :target_intent
           ]

    assert UnifiedUi.Reference.identity_rules() == %{
             required_sections: [:identity, :composition],
             reserved_ids: [:identity, :composition, :themes, :signals, :root],
             traceability_fields: [:authored_ref, :annotations, :tags],
             identifier_fields: %{
               identity: :id,
               composition: :root,
               themes: :default_theme,
               signals: :namespace
             }
           }

    assert UnifiedUi.Reference.placement_rules().boundaries.composition == [
             :root,
             :mode,
             :summary,
             :default_slot
           ]

    assert UnifiedUi.Reference.style_attribute_families().color == [
             :foreground,
             :background,
             :border_color,
             :role
           ]

    assert UnifiedUi.Reference.semantic_style_roles() == [
             :success,
             :warning,
             :error,
             :info,
             :muted,
             :help,
             :placeholder
           ]

    assert UnifiedUi.Reference.style_component_states() == [
             :default,
             :focused,
             :selected,
             :disabled,
             :active
           ]

    assert UnifiedUi.Reference.navigation_actions() == [
             :navigate_to,
             :replace_with,
             :go_back,
             :go_forward,
             :open_modal,
             :close_modal
           ]

    assert UnifiedUi.Reference.navigation_contract() == %{
             transition_fields: [:action, :screen, :modal, :params, :metadata],
             local_navigation_fields: [:binding, :destination],
             modal_stack: %{
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
             },
             actions: %{
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
           }
  end
end
