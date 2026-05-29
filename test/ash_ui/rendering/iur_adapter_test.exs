defmodule AshUI.Rendering.IURAdapterTest do
  use AshUI.DataCase, async: false

  @moduletag :conformance

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ResourceAuthorityScreen, UIStorageFixtures}

  describe "to_canonical/1" do
    test "converts simple screen to canonical format" do
      ash_iur =
        IUR.new(:screen,
          id: "test-screen-1",
          name: "test_screen",
          attributes: %{
            "layout" => :row,
            "route" => "/test"
          },
          children: [
            IUR.new(:text,
              id: "text-1",
              props: %{"content" => "Hello World"}
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      assert canonical.type == :composite
      assert canonical.kind == :screen
      assert canonical.id == "test-screen-1"
      assert canonical.attributes.screen.name == "test_screen"
      assert canonical.attributes.screen.layout == :row
      assert is_list(canonical.children)
      assert length(canonical.children) == 1
      assert_valid_canonical(canonical)
    end

    test "converts element to canonical widget type" do
      element = IUR.new(:button, props: %{"label" => "Click me"})

      ash_iur =
        IUR.new(:screen,
          children: [element]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical.children
      assert child.element.type == :widget
      assert child.element.kind == :button
      assert child.element.attributes.content.text == "Click me"
    end

    test "converts layout to canonical layout type" do
      layouts = [:row, :column, :grid, :stack]

      Enum.each(layouts, fn layout ->
        ash_iur =
          IUR.new(:screen,
            attributes: %{"layout" => layout}
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        assert canonical.attributes.screen.layout == layout
      end)
    end

    test "converts nested elements" do
      ash_iur =
        IUR.new(:screen,
          attributes: %{"layout" => :column},
          children: [
            IUR.new(:row,
              children: [
                IUR.new(:text, props: %{"content" => "Nested"}),
                IUR.new(:button, props: %{"label" => "Button"})
              ]
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [row] = canonical.children
      assert row.element.kind == :row

      assert length(row.element.children) == 2
    end
  end

  describe "compatible?/2" do
    test "returns true for screen with valid renderers" do
      screen_iur = IUR.new(:screen)

      assert IURAdapter.compatible?(screen_iur, :live_ui)
      assert IURAdapter.compatible?(screen_iur, :elm)
      assert IURAdapter.compatible?(screen_iur, :desktop_ui)
    end

    test "returns false for non-screen types" do
      text_iur = IUR.new(:text)

      refute IURAdapter.compatible?(text_iur, :live_ui)
    end
  end

  describe "element type mapping" do
    test "maps known element types correctly" do
      type_mappings = [
        {:text, :text},
        {:button, :button},
        {:textinput, :text_input},
        {:textarea, :text_input},
        {:select, :select},
        {:row, :row},
        {:column, :column}
      ]

      Enum.each(type_mappings, fn {ash_type, expected_canonical} ->
        ash_iur =
          IUR.new(:screen,
            children: [IUR.new(ash_type)]
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        [child] = canonical.children
        assert child.element.kind == expected_canonical
      end)
    end
  end

  describe "props mapping" do
    test "converts props map correctly" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:button,
              props: %{
                "label" => "Submit",
                "disabled" => false
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical.children
      assert child.element.attributes.content.text == "Submit"
      assert child.element.attributes.button.disabled == false
    end

    test "preserves empty binding paths on authored form widgets" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:form_field,
              props: %{
                "bindings" => [
                  %{
                    "name" => :display_name,
                    "path" => [],
                    "scope" => [],
                    "depends_on" => [],
                    "metadata" => [],
                    "derived" => []
                  }
                ]
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert_valid_canonical(canonical)
    end

    test "converts resource-authority semantic widgets without leaking renderer assumptions" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Authority.create(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 route: "/phase-13/resource-authority",
                 layout: :column,
                 metadata: %{"seed" => "phase13"}
               )

      assert {:ok, ash_iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)
      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert_valid_canonical(canonical)

      kinds = collect_kinds(canonical)

      assert :hero in kinds
      assert :stat in kinds
      assert :key_value in kinds
      assert :info_list in kinds
      assert :form_field in kinds

      assert get_in(canonical.metadata.extra, ["ash_ui", "ash_ui", "compiler_boundary"]) ==
               "AshUI resource graph -> AshUI runtime normalization"

      refute Enum.any?(canonical.children, fn child ->
               Map.has_key?(child.element.metadata.annotations, :ash_ui)
             end)
    end
  end

  describe "ask_sidebar IUR routing" do
    test "routes ask_sidebar kind through layer_shell_and_callout family" do
      ash_iur =
        IUR.new(:screen,
          id: "ask-sidebar-screen",
          name: "ask_sidebar_screen",
          attributes: %{},
          children: [
            IUR.new(:ask_sidebar,
              id: "ask-sb-1",
              props: %{
                "sidebar_id" => "main-ask-sidebar",
                "on_map_jump_event" => "switch_to_map"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :ask_sidebar
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :layer_shell_and_callout
    end

    test "preserves sidebar_id in canonical ask_sidebar attributes" do
      ash_iur =
        IUR.new(:screen,
          id: "ask-sidebar-screen-2",
          name: "ask_sidebar_screen",
          attributes: %{},
          children: [
            IUR.new(:ask_sidebar,
              id: "ask-sb-2",
              props: %{
                "sidebar_id" => "workspace-ask-sidebar",
                "on_map_jump_event" => "goto_map"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.attributes.ask_sidebar.sidebar_id == "workspace-ask-sidebar"
      assert child.element.attributes.ask_sidebar.on_map_jump_event == "goto_map"
    end
  end

  describe "canonical artifact and workflow IUR routing" do
    test "routes thread_card kind through row_and_artifact family with canonical open interaction" do
      ash_iur =
        IUR.new(:screen,
          id: "thread-card-screen",
          name: "thread_card_screen",
          attributes: %{},
          children: [
            IUR.new(:thread_card,
              id: "thread-card-1",
              props: %{
                "thread_id" => "thread:api",
                "title" => "API design discussion",
                "reply_count" => 5,
                "seed_quote" => "Should the runtime own this transition?",
                "participants" => [
                  %{"actor_name" => "Pascal", "avatar" => %{"initials" => "PC"}}
                ],
                "progress_pct" => 0.5
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :thread_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :row_and_artifact
      assert child.element.attributes.thread.thread_id == "thread:api"
      assert child.element.attributes.thread.title == "API design discussion"

      assert [%UnifiedIUR.Interaction{family: :open, intent: :open_thread}] =
               child.element.attributes.interactions

      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "returns structured conversion errors for invalid thread cards" do
      ash_iur =
        IUR.new(:screen,
          id: "thread-card-screen-invalid",
          name: "thread_card_screen",
          attributes: %{},
          children: [
            IUR.new(:thread_card,
              id: "thread-card-invalid",
              props: %{"title" => "Missing thread id", "seed_quote" => "Quote"}
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "thread_card requires a non-empty :thread_id"
    end

    test "routes propose_new_doc_card kind through layer_shell_and_callout family with canonical actions" do
      ash_iur =
        IUR.new(:screen,
          id: "propose-doc-screen",
          name: "propose_doc_screen",
          attributes: %{},
          children: [
            IUR.new(:propose_new_doc_card,
              id: "proposal-1",
              props: %{
                "target_path" => "docs/proposed.md",
                "title" => "Proposed brief",
                "body_md_preview" => "Short draft preview.",
                "status" => "pending",
                "conversation_seed_md" => "Operator requested a brief.",
                "actor_handle" => "@pascal",
                "proposed_at" => "2026-05-27T10:00:00Z"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :propose_new_doc_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :layer_shell_and_callout

      assert child.element.attributes.propose_new_doc == %{
               target_path: "docs/proposed.md",
               title: "Proposed brief",
               body_md_preview: "Short draft preview.",
               conversation_seed_md: "Operator requested a brief.",
               actor_handle: "@pascal",
               proposed_at: "2026-05-27T10:00:00Z",
               status: :pending,
               type: :document_creation,
               action_class: :document_creation,
               actions: [:accept, :reject, :preview]
             }

      assert [
               %UnifiedIUR.Interaction{family: :command, intent: :accept_proposed_doc},
               %UnifiedIUR.Interaction{family: :command, intent: :reject_proposed_doc},
               %UnifiedIUR.Interaction{family: :command, intent: :preview_proposed_doc}
             ] = child.element.attributes.interactions

      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "routes tool_call_card kind through row_and_artifact family with canonical expand interaction" do
      ash_iur =
        IUR.new(:screen,
          id: "tool-call-card-screen",
          name: "tool_call_card_screen",
          attributes: %{},
          children: [
            IUR.new(:tool_call_card,
              id: "tool-call-1",
              props: %{
                "tool_name" => "Bash",
                "tool_kind" => "bash",
                "target" => "mix test",
                "summary" => "Run the focused suite.",
                "status" => "pending",
                "args" => %{"cmd" => "mix test"},
                "expanded?" => false
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :tool_call_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :row_and_artifact

      assert child.element.attributes.tool_call == %{
               tool_name: "Bash",
               tool_kind: :bash,
               target: "mix test",
               summary: "Run the focused suite.",
               status: :pending,
               args: %{cmd: "mix test"},
               expanded?: false
             }

      assert [%UnifiedIUR.Interaction{family: :command, intent: :expand_toggled}] =
               child.element.attributes.interactions

      assert :ok = UnifiedIUR.Validate.element(child.element)
    end


    test "returns structured conversion errors for invalid propose_new_doc_card payloads" do
      ash_iur =
        IUR.new(:screen,
          id: "propose-doc-screen-invalid",
          name: "propose_doc_screen",
          attributes: %{},
          children: [
            IUR.new(:propose_new_doc_card,
              id: "proposal-invalid",
              props: %{
                "target_path" => "docs/proposed.md",
                "title" => "Proposed brief",
                "body_md_preview" => "Short draft preview.",
                "status" => "open"
              }
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "propose_new_doc_card :status must be one of"
    end

    test "returns structured conversion errors for invalid tool_call_card payloads" do
      ash_iur =
        IUR.new(:screen,
          id: "tool-call-card-screen-invalid",
          name: "tool_call_card_screen",
          attributes: %{},
          children: [
            IUR.new(:tool_call_card,
              id: "tool-call-invalid",
              props: %{
                "tool_name" => "Bash",
                "tool_kind" => "bash",
                "target" => "mix test",
                "summary" => "Run tests",
                "status" => "pending",
                "args" => ["cmd", "mix test"]
              }
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "tool_call_card :args must be a map"
    end

    test "routes escalation_card kind through layer_shell_and_callout family with canonical actions" do
      ash_iur =
        IUR.new(:screen,
          id: "escalation-screen",
          name: "escalation_screen",
          attributes: %{},
          children: [
            IUR.new(:escalation_card,
              id: "esc-1",
              props: %{
                "target_project_id" => "ariston-ui",
                "severity" => "p2",
                "text" => "Coverage gap detected.",
                "actor_handle" => "@codex",
                "proposed_action" => "Add aria-live region"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :escalation_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :layer_shell_and_callout

      esc = child.element.attributes.escalation

      assert esc.target_project_id == "ariston-ui"
      assert esc.severity == :p2
      assert esc.text == "Coverage gap detected."
      assert esc.actor_handle == "@codex"
      assert esc.proposed_action == "Add aria-live region"

      assert [
               %UnifiedIUR.Interaction{family: :command, intent: :acknowledge_escalation},
               %UnifiedIUR.Interaction{family: :command, intent: :route_escalation_to_rail}
             ] = child.element.attributes.interactions

      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "returns structured conversion errors for invalid escalation_card payloads" do
      ash_iur =
        IUR.new(:screen,
          id: "escalation-screen-invalid",
          name: "escalation_screen",
          attributes: %{},
          children: [
            IUR.new(:escalation_card,
              id: "esc-invalid",
              props: %{
                "target_project_id" => "ariston-ui",
                "severity" => "critical",
                "text" => "Test."
              }
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "severity must be one of"
    end


    test "routes workflow_progress_status_card kind through workflow_progress_and_status family" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-1",
              props: %{
                "name" => "metagraph",
                "progress_pct" => 0.5,
                "active_count" => 2,
                "blocked_count" => 0
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :workflow_progress_status_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :workflow_progress_and_status
      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "maps subject props into canonical attributes without namespace overwrite" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen-2",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-2",
              props: %{
                "name" => "ash_ui",
                "subject_id" => "subject:ash_ui",
                "path" => "workspaces/ash_ui",
                "progress_pct" => 0.72,
                "active_count" => 4,
                "blocked_count" => 1,
                "last_activity_at" => ~U[2026-05-19 10:00:00Z],
                "depends_on" => ["unified_iur"],
                "depended_by" => [%{"id" => "ariston-ui", "label" => "Ariston UI"}],
                "selected?" => true,
                "open_action" => %{"label" => "Open", "intent" => "open_subject"},
                "component" => %{"family" => "bad_family"},
                "subject" => %{"name" => "bad_subject"}
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children

      assert child.element.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :workflow_progress_status_card
             }

      assert child.element.attributes.subject.id == "subject:ash_ui"
      assert child.element.attributes.subject.name == "ash_ui"
      assert child.element.attributes.subject.path == "workspaces/ash_ui"
      assert child.element.attributes.subject.progress == 72.0
      assert child.element.attributes.subject.status_counts == %{active: 4, blocked: 1}

      assert child.element.attributes.subject.activity == %{
               last_activity_at: ~U[2026-05-19 10:00:00Z]
             }

      assert child.element.attributes.subject.dependencies == %{
               depends_on: [%{id: "unified_iur", label: "unified_iur", direction: :depends_on}],
               depended_by: [
                 %{id: "ariston-ui", label: "Ariston UI", direction: :depended_by}
               ]
             }

      assert child.element.attributes.subject.state == %{selected?: true}

      assert child.element.attributes.subject.actions.open == %{
               label: "Open",
               intent: "open_subject"
             }

      assert child.element.attributes.subject.interactions.focus.intent == "focus_subject"
      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "returns structured conversion errors for invalid subject cards" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen-3",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-3",
              props: %{"name" => "ash_ui", "progress" => 150}
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "progress must be in 0.0..100.0"
    end

    test "routes live_session_card kind through workflow_progress_and_status family with synthetic id" do
      session_id = "550e8400-e29b-41d4-a716-446655440000"

      ash_iur =
        IUR.new(:screen,
          id: "live-session-screen",
          name: "live_session_screen",
          attributes: %{},
          children: [
            IUR.new(:live_session_card,
              id: "ignored-source-id",
              props: %{
                "session_id" => session_id,
                "actor_handle" => "@opus",
                "status" => :running,
                "status_version" => 3,
                "tools_count" => 4,
                "edits_count" => 2,
                "tokens_consumed" => 9_000,
                "started_at" => ~U[2026-05-27 15:00:00Z],
                "now_streaming" => "Writing tests.",
                "recent_events" => [
                  %{"kind" => "assistant_text", "body" => "Working."}
                ],
                "pinned?" => true
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children

      assert child.element.id == "live_session:#{session_id}:3"
      assert child.element.kind == :live_session_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :workflow_progress_and_status
      assert child.element.attributes.live_session.session_id == session_id
      assert child.element.attributes.live_session.status == :running
      assert child.element.attributes.live_session.tools_count == 4
      assert child.element.attributes.live_session.edits_count == 2
      assert child.element.attributes.live_session.tokens_consumed == 9_000
      assert child.element.attributes.live_session.pinned? == true
      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "returns structured conversion errors for invalid live_session_card payloads" do
      ash_iur =
        IUR.new(:screen,
          id: "live-session-screen-invalid",
          name: "live_session_screen",
          attributes: %{},
          children: [
            IUR.new(:live_session_card,
              props: %{
                "session_id" => "not-a-uuid",
                "actor_handle" => "@opus",
                "status" => :running,
                "status_version" => 1,
                "tools_count" => 0,
                "edits_count" => 0,
                "tokens_consumed" => 0,
                "started_at" => ~U[2026-05-27 15:00:00Z]
              }
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "session_id must be a uuid"
    end
  end

  describe "error handling" do
    test "returns error for invalid IUR" do
      invalid_iur = %IUR{type: nil}

      assert {:error, _reason} = IURAdapter.to_canonical(invalid_iur)
    end
  end

  defp assert_valid_canonical(canonical) do
    assert {:ok, %UnifiedIUR.Element{} = normalized} = UnifiedIUR.Normalize.element(canonical)
    assert :ok = UnifiedIUR.Validate.element(normalized)
  end

  defp collect_kinds(%UnifiedIUR.Element{kind: kind, children: children}) do
    [kind | Enum.flat_map(children || [], &collect_kinds/1)]
  end

  defp collect_kinds(%UnifiedIUR.Element.Child{element: nil}), do: []

  defp collect_kinds(%UnifiedIUR.Element.Child{element: element}) do
    collect_kinds(element)
  end

  defp collect_kinds(_other), do: []
end
