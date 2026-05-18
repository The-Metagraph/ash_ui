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
             :thread_card
           ]

    assert Components.form_control_kinds() == [
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer,
             :mode_nav
           ]

    assert Components.row_artifact_kinds() == [:list_item_multi_column, :artifact_row]

    assert Components.workflow_kinds() == [
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin,
             :unread_badge
           ]

    assert Components.layer_callout_kinds() == [
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout,
             :top_strip,
             :sidebar_shell,
             :sidebar_section,
             :sidebar_item,
             :command_palette,
             :composer_inline_ask,
             :ask_sidebar
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

  describe "thread_card constructor" do
    test "builds a thread_card element with required fields" do
      card =
        Components.thread_card(
          thread_id: "thread-abc-123",
          title: "Design review: wave 3.7",
          reply_count: 7,
          seed_quote: "What should the progress bar show when there's no active task?"
        )

      assert %Element{kind: :thread_card} = card

      assert card.attributes.component == %{
               family: :content_identity_and_disclosure,
               kind: :thread_card
             }

      assert card.attributes.thread == %{
               thread_id: "thread-abc-123",
               title: "Design review: wave 3.7",
               reply_count: 7,
               seed_quote: "What should the progress bar show when there's no active task?",
               open_intent: "open_thread"
             }

      # empty participants list is dropped by merge_attribute/3 (value in [[], nil] guard)
      refute Map.has_key?(card.attributes, :participants)
    end

    test "includes participants in element attributes" do
      participants = [
        %{actor_name: "Pascal", avatar: %{initials: "PC"}},
        %{actor_name: "Matt", avatar: %{initials: "MD"}}
      ]

      card =
        Components.thread_card(
          thread_id: "t-1",
          title: "API review",
          reply_count: 2,
          seed_quote: "LGTM",
          participants: participants
        )

      assert card.attributes.participants == participants
    end

    test "includes optional progress_pct in thread attrs" do
      card =
        Components.thread_card(
          thread_id: "t-2",
          title: "In-flight task",
          reply_count: 0,
          seed_quote: "Running analysis...",
          progress_pct: 0.65
        )

      assert card.attributes.thread.progress_pct == 0.65
    end

    test "includes last_activity_at in thread attrs" do
      ts = ~U[2026-05-18 10:00:00Z]

      card =
        Components.thread_card(
          thread_id: "t-3",
          title: "Old thread",
          reply_count: 3,
          seed_quote: "Quote",
          last_activity_at: ts
        )

      assert card.attributes.thread.last_activity_at == ts
    end

    test "accepts custom open_intent" do
      card =
        Components.thread_card(
          thread_id: "t-4",
          title: "Custom intent",
          reply_count: 0,
          seed_quote: "",
          open_intent: "navigate_thread"
        )

      assert card.attributes.thread.open_intent == "navigate_thread"
    end

    test "defaults reply_count to 0 and seed_quote to empty string" do
      card = Components.thread_card(thread_id: "t-5", title: "Minimal")

      assert card.attributes.thread.reply_count == 0
      assert card.attributes.thread.seed_quote == ""
      assert card.attributes.thread.title == "Minimal"
    end

    test "omits nil optional fields from thread attrs" do
      card =
        Components.thread_card(
          thread_id: "t-6",
          title: "No progress",
          reply_count: 1,
          seed_quote: "Quote"
        )

      refute Map.has_key?(card.attributes.thread, :progress_pct)
      refute Map.has_key?(card.attributes.thread, :last_activity_at)
    end
  end

  describe "ask_sidebar constructor" do
    test "builds an ask_sidebar element with required fields" do
      sidebar =
        Components.ask_sidebar(
          sidebar_id: "ask-sb-main",
          on_map_jump_event: "switch_to_map"
        )

      assert %Element{kind: :ask_sidebar} = sidebar

      assert sidebar.attributes.component == %{
               family: :layer_shell_and_callout,
               kind: :ask_sidebar
             }

      assert sidebar.attributes.ask_sidebar.sidebar_id == "ask-sb-main"
      assert sidebar.attributes.ask_sidebar.on_map_jump_event == "switch_to_map"
      assert sidebar.attributes.ask_sidebar.recent_items == []
      assert sidebar.attributes.ask_sidebar.saved_items == []
      assert sidebar.attributes.ask_sidebar.blocker_count == 0
      assert sidebar.attributes.ask_sidebar.empty_recent_label == "No recent queries"
      assert sidebar.attributes.ask_sidebar.empty_saved_label == "No saved queries yet"
    end

    test "accepts recent_items and saved_items lists" do
      now = DateTime.utc_now()

      recent = [
        %{
          id: "r-1",
          query: "show blockers",
          last_run_at: now,
          status: :done,
          on_open_event: "open_recent"
        }
      ]

      saved = [
        %{
          id: "s-1",
          title: "Weekly blockers",
          query: "show blockers",
          cadence: "weekly",
          last_run_at: now,
          on_open_event: "open_saved"
        }
      ]

      sidebar =
        Components.ask_sidebar(
          sidebar_id: "ask-sb-2",
          on_map_jump_event: "switch_to_map",
          recent_items: recent,
          saved_items: saved
        )

      assert sidebar.attributes.ask_sidebar.recent_items == recent
      assert sidebar.attributes.ask_sidebar.saved_items == saved
    end

    test "accepts all optional fields" do
      sidebar =
        Components.ask_sidebar(
          sidebar_id: "ask-sb-3",
          on_map_jump_event: "switch_to_map",
          active_item_id: "r-1",
          on_new_saved_event: "new_saved_query",
          on_see_all_event: "see_all_recent",
          empty_recent_label: "Nothing here yet",
          empty_saved_label: "No saves",
          blocker_count: 3
        )

      attrs = sidebar.attributes.ask_sidebar
      assert attrs.active_item_id == "r-1"
      assert attrs.on_new_saved_event == "new_saved_query"
      assert attrs.on_see_all_event == "see_all_recent"
      assert attrs.empty_recent_label == "Nothing here yet"
      assert attrs.empty_saved_label == "No saves"
      assert attrs.blocker_count == 3
    end

    test "omits nil optional fields from ask_sidebar attrs" do
      sidebar =
        Components.ask_sidebar(
          sidebar_id: "ask-sb-4",
          on_map_jump_event: "switch_to_map"
        )

      refute Map.has_key?(sidebar.attributes.ask_sidebar, :active_item_id)
      refute Map.has_key?(sidebar.attributes.ask_sidebar, :on_new_saved_event)
      refute Map.has_key?(sidebar.attributes.ask_sidebar, :on_see_all_event)
    end

    test "raises when sidebar_id is missing" do
      assert_raise ArgumentError, ~r/:sidebar_id/, fn ->
        Components.ask_sidebar(on_map_jump_event: "switch_to_map")
      end
    end

    test "raises when sidebar_id is empty string" do
      assert_raise ArgumentError, ~r/:sidebar_id/, fn ->
        Components.ask_sidebar(sidebar_id: "", on_map_jump_event: "switch_to_map")
      end
    end

    test "raises when on_map_jump_event is missing" do
      assert_raise ArgumentError, ~r/:on_map_jump_event/, fn ->
        Components.ask_sidebar(sidebar_id: "ask-sb-5")
      end
    end

    test "raises when on_map_jump_event is empty string" do
      assert_raise ArgumentError, ~r/:on_map_jump_event/, fn ->
        Components.ask_sidebar(sidebar_id: "ask-sb-6", on_map_jump_event: "")
      end
    end

    test "raises when recent_items is not a list" do
      assert_raise ArgumentError, ~r/:recent_items/, fn ->
        Components.ask_sidebar(
          sidebar_id: "ask-sb-7",
          on_map_jump_event: "switch_to_map",
          recent_items: "not-a-list"
        )
      end
    end

    test "raises when saved_items is not a list" do
      assert_raise ArgumentError, ~r/:saved_items/, fn ->
        Components.ask_sidebar(
          sidebar_id: "ask-sb-8",
          on_map_jump_event: "switch_to_map",
          saved_items: "not-a-list"
        )
      end
    end

    test "raises when blocker_count is negative" do
      assert_raise ArgumentError, ~r/:blocker_count/, fn ->
        Components.ask_sidebar(
          sidebar_id: "ask-sb-9",
          on_map_jump_event: "switch_to_map",
          blocker_count: -1
        )
      end
    end
  end
end
