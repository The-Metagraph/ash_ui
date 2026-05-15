defmodule UnifiedIUR.Widgets.ComponentsTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Widgets.{Components, Foundational}

  test "exposes expanded widget component constructor families" do
    assert %{components: Components} = Widgets.modules()

    assert Components.content_identity_kinds() == [
             :inline_rich_text_heading,
             :disclosure,
             :kicker,
             :avatar,
             :presence_dot,
             :unread_badge
           ]

    assert Components.form_control_kinds() == [
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer
           ]

    assert Components.navigation_kinds() == [:mode_nav]

    assert Components.row_artifact_kinds() == [
             :list_item_multi_column,
             :artifact_row,
             :sidebar_item
           ]

    assert Components.workflow_kinds() == [
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin
           ]

    assert Components.layer_callout_kinds() == [
             :sidebar_shell,
             :sidebar_section,
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout
           ]

    assert Components.redline_code_kinds() == [
             :redline_inline,
             :code_block_syntax_highlighted
           ]

    assert Components.composition_behavior_kinds() == [:list_repeat]
    assert Widgets.component_kinds() == Components.kinds()
  end

  test "represents content, identity, and disclosure components" do
    heading =
      Components.inline_rich_text_heading(:h2, [
        %{type: :text, value: "Canonical "},
        %{type: :emphasis, value: "widgets"}
      ])

    disclosure =
      Components.disclosure("Advanced", [Foundational.text("Body")],
        id: "details",
        open?: true
      )

    kicker = Components.kicker(["Spec", "ADR"], separator: "/")
    avatar = Components.avatar(initials: "PC", size: :small, accessibility_label: "Pascal")
    presence = Components.presence_dot(:active, size: :small)
    unread_badge = Components.unread_badge(12, tone: :critical)

    assert %Element{
             kind: :inline_rich_text_heading,
             attributes: %{
               component: %{family: :content_identity_and_disclosure},
               heading: %{level: :h2, segments: [%{type: :text}, %{type: :emphasis}]}
             }
           } = heading

    assert %Element{
             id: "details",
             kind: :disclosure,
             attributes: %{disclosure: %{summary: "Advanced", open?: true}},
             children: [%{slot: :default, element: %Element{kind: :text}}]
           } = disclosure

    assert kicker.attributes.kicker == %{items: ["Spec", "ADR"], separator: "/"}
    assert avatar.attributes.identity == %{initials: "PC", size: :small, shape: :round}
    assert avatar.attributes.accessibility == %{label: "Pascal"}
    assert presence.attributes.presence == %{state: :active, size: :small}
    assert unread_badge.attributes.badge == %{count: 12, tone: :critical}
  end

  test "represents form controls, rows, artifacts, and composer children" do
    segmented =
      Components.segmented_button_group(
        [
          %{value: :all, label: "All"},
          %{value: :active, label: "Active", disabled?: true}
        ],
        active_value: :all,
        selection_intent: :select_status,
        disabled?: false
      )

    form =
      Components.runtime_form_shell(
        [%{name: :email, type: :email, attributes: [required: true]}],
        submit_label: "Save",
        submit_intent: :save,
        change_intent: :validate,
        validation_state: :invalid,
        host_adapter_hints: %{live_ui: %{adapter: :phoenix_form}}
      )

    composer =
      Components.chat_composer([Foundational.button("Attach")],
        value: "Draft",
        send_intent: :send_message
      )

    row =
      Components.list_item_multi_column([Foundational.text("Title")],
        row_identity: "row-1",
        active?: true,
        column_template: [%{id: :title, label: "Title"}],
        action_intent: :open_row
      )

    artifact =
      Components.artifact_row("ADR", [Foundational.button("Open")],
        row_identity: :adr,
        meta: %{status: :accepted}
      )

    sidebar_item =
      Components.sidebar_item("build/phase-31.2",
        glyph: "◇",
        meta: "phase 31.2",
        state: :blocked,
        item_kind: :build,
        item_id: "phase-31.2",
        action_intent: :open_build,
        unread_count: 12
      )

    mode_nav =
      Components.mode_nav(
        [
          %{key: :chat, label: "Chat", glyph: "◉", badge_count: 3, panel_id: "mode-chat"},
          %{key: :map, label: "Map", glyph: "◎"}
        ],
        active_key: :chat,
        keyboard_shortcut_prefix: "⌘",
        selection_intent: :select_mode
      )

    assert segmented.attributes.selection == %{
             presentation: :segmented_button_group,
             multiple?: false,
             options: [
               %{value: :all, label: "All"},
               %{value: :active, label: "Active", disabled?: true}
             ],
             active_value: :all,
             selection_intent: :select_status
           }

    assert segmented.attributes.state == %{disabled?: false}

    assert form.attributes.form == %{
             fields: [%{name: :email, type: :email, attributes: [required: true]}],
             submit_label: "Save",
             submit_intent: :save,
             change_intent: :validate,
             validation_state: :invalid,
             host_adapter_hints: %{live_ui: %{adapter: :phoenix_form}}
           }

    assert composer.attributes.composer == %{
             value: "Draft",
             rows: 3,
             send_label: "Send",
             send_intent: :send_message
           }

    assert [%{element: %Element{kind: :button}}] = composer.children

    assert row.attributes.row == %{
             row_identity: "row-1",
             active?: true,
             action_intent: :open_row,
             column_template: [%{id: :title, label: "Title"}]
           }

    assert artifact.attributes.artifact == %{
             row_identity: :adr,
             title: "ADR",
             meta: %{status: :accepted}
           }

    assert sidebar_item.attributes.sidebar_item == %{
             label: "build/phase-31.2",
             glyph: "◇",
             meta: "phase 31.2",
             state: :blocked,
             item_kind: :build,
             item_id: "phase-31.2",
             action_intent: :open_build,
             unread_count: 12
           }

    assert [%{slot: :trailing, element: %Element{kind: :unread_badge}}] = sidebar_item.children

    assert mode_nav.attributes.mode_nav == %{
             modes: [
               %{key: :chat, label: "Chat", glyph: "◉", badge_count: 3, panel_id: "mode-chat"},
               %{key: :map, label: "Map", glyph: "◎"}
             ],
             active_key: :chat,
             keyboard_shortcut_prefix: "⌘",
             aria_label: "mode navigation",
             selection_intent: :select_mode
           }
  end

  test "represents workflow, layer, callout, redline, and code components" do
    stepper =
      Components.pipeline_stepper_horizontal(
        [
          %{id: :draft, label: "Draft", state: :done},
          %{id: :review, label: "Review", state: :active}
        ],
        active_index: 1,
        completed_indices: [0],
        navigation_intent: :select_step
      )

    progress =
      Components.segmented_progress_bar(
        [%{label: "Passing", weight: 8, state: :success}],
        aggregate_progress: %{current: 8, maximum: 9},
        label: "Scenario health"
      )

    stages =
      Components.workflow_stage_list_vertical(
        [%{id: :authored, label: "Authored", state: :done}],
        active_index: 0
      )

    meter = Components.meter_thin(82.5, label: "Coverage", state: :success)

    section =
      Components.sidebar_section(
        "Channels",
        [
          Components.sidebar_item("metagraph-team",
            glyph: "#",
            item_kind: :channel,
            item_id: "metagraph-team",
            action_intent: :open_channel
          )
        ],
        action_glyph: "+",
        action_label: "New channel",
        action_intent: :new_channel
      )

    shell =
      Components.sidebar_shell(
        [section],
        width: :wide,
        aria_label: "primary navigation"
      )

    header = Components.sticky_frosted_header([], title: "Workspace", leading: [:back])

    panel =
      Components.slide_over_panel([Foundational.text("Panel")],
        accessibility_label: "Details",
        open?: true,
        size: :wide,
        dismiss_intent: :close_panel
      )

    callout =
      Components.event_callout("Paused", [Foundational.button("Inspect")],
        tone: :warning,
        action_intent: :inspect_event
      )

    redline = Components.redline_inline([%{state: :insert, text: "new"}])

    code =
      Components.code_block_syntax_highlighted(:elixir, [
        %{type: :keyword, text: "defmodule"}
      ])

    assert stepper.attributes.workflow == %{
             presentation: :pipeline_stepper_horizontal,
             steps: [
               %{id: :draft, label: "Draft", state: :done},
               %{id: :review, label: "Review", state: :active}
             ],
             active_index: 1,
             completed_indices: [0],
             navigation_intent: :select_step
           }

    assert progress.attributes.progress == %{
             presentation: :segmented_progress_bar,
             segments: [%{label: "Passing", weight: 8, state: :success}],
             aggregate: %{current: 8, maximum: 9},
             label: "Scenario health"
           }

    assert stages.attributes.workflow == %{
             presentation: :workflow_stage_list_vertical,
             stages: [%{id: :authored, label: "Authored", state: :done}],
             active_index: 0
           }

    assert meter.attributes.meter == %{
             current: 82.5,
             minimum: 0,
             maximum: 100,
             label: "Coverage",
             state: :success
           }

    assert shell.attributes.sidebar_shell == %{
             width: :wide,
             aria_label: "primary navigation"
           }

    assert shell.attributes.accessibility == %{label: "primary navigation"}
    assert [%{element: %Element{kind: :sidebar_section}}] = shell.children

    assert section.attributes.sidebar_section == %{
             title: "Channels",
             action_glyph: "+",
             action_label: "New channel",
             action_intent: :new_channel
           }

    assert [%{element: %Element{kind: :sidebar_item}}] = section.children

    assert header.attributes.shell == %{
             position: :sticky,
             visual_effect: :frosted,
             title: "Workspace",
             leading: [:back],
             trailing: []
           }

    assert panel.attributes.panel == %{
             modal?: false,
             open?: true,
             size: :wide,
             label: "Details",
             dismiss_intent: :close_panel
           }

    assert panel.attributes.accessibility == %{label: "Details"}

    assert callout.attributes.callout == %{
             message: "Paused",
             tone: :warning,
             action_intent: :inspect_event
           }

    assert [%{element: %Element{kind: :button}}] = callout.children
    assert redline.attributes.redline == %{segments: [%{state: :insert, text: "new"}]}
    assert redline.attributes.text_safety == %{content: :plain_text}

    assert code.attributes.code == %{
             language: :elixir,
             tokens: [%{type: :keyword, text: "defmodule"}]
           }

    assert code.attributes.text_safety == %{content: :plain_text}
  end

  test "represents list repeat metadata and hydrated row children" do
    template = Components.artifact_row("Template", [], row_identity: :id)

    repeat =
      Components.list_repeat(template,
        repeat_binding: :artifact_rows,
        binding_ref: %{kind: :binding_ref, id: :artifact_rows, path: [:artifacts]},
        row_scope: :artifact,
        row_fields: [:id, :title],
        template_identity: :artifact_template,
        identity_strategy: :row_identity,
        hydrated?: true,
        row_count: 1,
        template: %{id: :artifact_template, kind: :artifact_row},
        children: [Components.artifact_row("Hydrated", [], id: "artifact_repeat:a1:artifact")]
      )

    assert repeat.kind == :list_repeat
    assert repeat.attributes.component == %{family: :composition_behavior, kind: :list_repeat}

    assert repeat.attributes.repeat == %{
             binding_id: :artifact_rows,
             binding_ref: %{kind: :binding_ref, id: :artifact_rows, path: [:artifacts]},
             row_scope: :artifact,
             row_fields: [:id, :title],
             template_identity: :artifact_template,
             identity_strategy: :row_identity,
             child_slot: :default,
             hydrated?: true,
             row_count: 1,
             template: %{id: :artifact_template, kind: :artifact_row}
           }

    assert [%{slot: :default, element: %Element{id: "artifact_repeat:a1:artifact"}}] =
             repeat.children
  end
end
