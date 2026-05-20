defmodule UnifiedIUR.Widgets.ComponentsTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Interaction}
  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Widgets.{Components, Foundational}

  test "exposes expanded widget component constructor families" do
    assert %{components: Components} = Widgets.modules()

    assert Components.content_identity_kinds() == [
             :inline_rich_text_heading,
             :disclosure,
             :kicker,
             :avatar,
             :presence_dot
           ]

    assert Components.form_control_kinds() == [
             :segmented_button_group,
             :runtime_form_shell,
             :chat_composer,
             :collection_picker,
             :mode_nav
           ]

    assert Components.row_artifact_kinds() == [
             :list_item_multi_column,
             :artifact_row,
             :thread_card
           ]

    assert Components.artifact_kinds() == [:pr, :doc, :spec, :file, :grain, :generic]

    assert Components.workflow_kinds() == [
             :pipeline_stepper_horizontal,
             :segmented_progress_bar,
             :workflow_stage_list_vertical,
             :meter_thin,
             :unread_badge,
             :workflow_progress_status_card
           ]

    assert Components.layer_callout_kinds() == [
             :sticky_frosted_header,
             :slide_over_panel,
             :event_callout,
             :top_strip,
             :sidebar_shell,
             :sidebar_section,
             :sidebar_item,
             :right_rail,
             :command_palette,
             :composer_query_preview
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
    presence = Components.presence_dot(:do_not_disturb, size: :small, decorative?: true)

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
    assert presence.attributes.presence == %{state: :do_not_disturb, size: :small}
    assert presence.attributes.accessibility == %{decorative?: true}
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

    picker =
      Components.collection_picker(
        id: "source-picker",
        picker_id: "sources",
        title: "Sources",
        query: "adr",
        filters: [%{id: :all, label: "All", selected?: true, count: 2}],
        items: [%{id: :adr_1, label: "ADR 1", description: "Architecture decision"}],
        suggestions: [
          %{id: :suggestion_1, label: "Add ADR 2", source: "system", confidence: 0.82}
        ]
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
        meta: %{status: :accepted},
        artifact_kind: :doc,
        status_badges: [%{label: "Accepted", tone: :positive}],
        counts: %{comments: 2, references: 5},
        timestamp_at: ~U[2026-05-18 10:00:00Z]
      )

    thread =
      Components.thread_card(
        id: "thread-api",
        thread_id: "thread:api",
        title: "API design discussion",
        reply_count: 5,
        seed_quote: "Should the runtime own this transition?",
        participants: [
          %{actor_name: "Pascal", avatar: %{initials: "PC"}},
          %{actor_name: "Ash"}
        ],
        progress_pct: 0.4
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

    assert picker.attributes.component == %{
             family: :form_control_and_composer,
             kind: :collection_picker
           }

    assert picker.attributes.collection_picker == %{
             picker_id: "sources",
             title: "Sources",
             query: "adr",
             placeholder: "Search collection",
             filters: [%{id: "all", label: "All", selected?: true, count: 2}],
             items: [
               %{id: "adr_1", label: "ADR 1", description: "Architecture decision"}
             ],
             suggestions: [
               %{id: "suggestion_1", label: "Add ADR 2", source: "system", confidence: 0.82}
             ],
             empty_label: "No matching items."
           }

    assert Enum.map(picker.attributes.interactions, &{&1.family, &1.intent}) == [
             {:change, :change_collection_query},
             {:selection, :select_collection_item},
             {:command, :toggle_collection_filter},
             {:command, :accept_collection_suggestion},
             {:command, :dismiss_collection_suggestion}
           ]

    assert row.attributes.row == %{
             row_identity: "row-1",
             active?: true,
             action_intent: :open_row,
             column_template: [%{id: :title, label: "Title"}]
           }

    assert artifact.attributes.artifact == %{
             row_identity: :adr,
             title: "ADR",
             meta: %{status: :accepted},
             kind: :doc,
             status_badges: [%{label: "Accepted", tone: :positive}],
             counts: [%{key: :comments, value: 2}, %{key: :references, value: 5}],
             timestamp_at: ~U[2026-05-18 10:00:00Z]
           }

    assert thread.attributes.component == %{family: :row_and_artifact, kind: :thread_card}

    assert thread.attributes.thread == %{
             thread_id: "thread:api",
             title: "API design discussion",
             reply_count: 5,
             seed_quote: "Should the runtime own this transition?",
             progress_pct: 0.4
           }

    assert thread.attributes.participants == [
             %{actor_name: "Pascal", avatar: %{initials: "PC"}},
             %{actor_name: "Ash"}
           ]

    assert [%Interaction{family: :open, intent: :open_thread}] = thread.attributes.interactions
  end

  test "validates canonical thread card identity and progress" do
    assert_raise ArgumentError, ~r/non-empty :thread_id/, fn ->
      Components.thread_card(title: "Thread", seed_quote: "Quote")
    end

    assert_raise ArgumentError, ~r/non-empty :title/, fn ->
      Components.thread_card(thread_id: "thread:1", seed_quote: "Quote")
    end

    assert_raise ArgumentError, ~r/non-empty :seed_quote/, fn ->
      Components.thread_card(thread_id: "thread:1", title: "Thread")
    end

    assert_raise ArgumentError, ~r/reply_count must be a non-negative integer/, fn ->
      Components.thread_card(
        thread_id: "thread:1",
        title: "Thread",
        seed_quote: "Quote",
        reply_count: -1
      )
    end

    assert_raise ArgumentError, ~r/progress_pct must be in 0\.0\.\.1\.0/, fn ->
      Components.thread_card(
        thread_id: "thread:1",
        title: "Thread",
        seed_quote: "Quote",
        progress_pct: 1.5
      )
    end
  end

  test "validates canonical collection picker shape" do
    assert_raise ArgumentError, ~r/non-empty :picker_id/, fn ->
      Components.collection_picker(items: [])
    end

    assert_raise ArgumentError, ~r/filter :count must be a non-negative integer/, fn ->
      Components.collection_picker(
        picker_id: "sources",
        filters: [%{id: "all", label: "All", count: -1}]
      )
    end

    assert_raise ArgumentError, ~r/suggestion :confidence must be in 0\.0\.\.1\.0/, fn ->
      Components.collection_picker(
        picker_id: "sources",
        suggestions: [%{id: "s1", label: "Suggestion", confidence: 1.2}]
      )
    end
  end

  test "validates canonical composer query preview shape" do
    assert_raise ArgumentError, ~r/non-empty :composer_id/, fn ->
      Components.composer_query_preview(query: "status")
    end

    assert_raise ArgumentError, ~r/non-empty :query/, fn ->
      Components.composer_query_preview(composer_id: "composer-main")
    end

    assert_raise ArgumentError, ~r/preview_state must be one of/, fn ->
      Components.composer_query_preview(
        composer_id: "composer-main",
        query: "status",
        preview_state: :stale
      )
    end

    assert_raise ArgumentError, ~r/explanation.*ready/, fn ->
      Components.composer_query_preview(
        composer_id: "composer-main",
        query: "status",
        preview_state: :ready
      )
    end

    assert_raise ArgumentError, ~r/confidence must be in 0\.0\.\.1\.0/, fn ->
      Components.composer_query_preview(
        composer_id: "composer-main",
        query: "status",
        findings: [%{id: "finding-1", n: 1, snippet: "bad", confidence: 1.2}]
      )
    end
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

    query_preview =
      Components.composer_query_preview(
        id: "preview-search",
        composer_id: "composer-main",
        query: "release blockers",
        preview_state: :ready,
        explanation: "Three likely blockers found.",
        metrics: %{results_count: 3, duration_ms: 42, sources_visited: 8},
        findings: [
          %{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}
        ]
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

    assert query_preview.attributes.component == %{
             family: :layer_shell_and_callout,
             kind: :composer_query_preview
           }

    assert query_preview.attributes.query_preview == %{
             composer_id: "composer-main",
             query: "release blockers",
             preview_state: :ready,
             max_findings_shown: 2,
             findings: [
               %{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}
             ],
             explanation: "Three likely blockers found.",
             metrics: %{results_count: 3, duration_ms: 42, sources_visited: 8},
             loading_label: "Searching",
             empty_label: "No results for this query.",
             open_label: "Open query",
             save_label: "Save query"
           }

    assert [
             %Interaction{family: :close, intent: :dismiss_query_preview},
             %Interaction{family: :open, intent: :open_query_preview},
             %Interaction{family: :command, intent: :save_query}
           ] = query_preview.attributes.interactions

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

  test "represents canonical right rail panels and children" do
    rail =
      Components.right_rail(
        id: :workspace_rail,
        panels: [
          %{id: :agents, label: "Agents", badge: %{label: "2"}, content_slot: :agents_body},
          %{id: :sources, label: "Sources", content_slot: :sources_body}
        ],
        active_panel: :sources,
        collapsed?: false,
        collapsible?: true,
        density: :compact,
        width: :wide,
        children: [Foundational.text("Sources", id: :sources_body)]
      )

    assert rail.kind == :right_rail
    assert rail.attributes.component == %{family: :layer_shell_and_callout, kind: :right_rail}

    assert rail.attributes.rail == %{
             id: :workspace_rail,
             side: :right,
             panels: [
               %{id: :agents, label: "Agents", badge: %{label: "2"}, content_slot: :agents_body},
               %{id: :sources, label: "Sources", content_slot: :sources_body}
             ],
             active_panel: :sources,
             collapsed?: false,
             collapsible?: true,
             density: :compact,
             width: :wide
           }

    assert [%{slot: :default, element: %Element{id: :sources_body, kind: :text}}] = rail.children
  end
end
