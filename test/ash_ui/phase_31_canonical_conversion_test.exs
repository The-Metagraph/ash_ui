defmodule AshUI.Phase31CanonicalConversionTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.IURAdapter

  @moduletag :conformance

  @component_samples [
    {:inline_rich_text_heading, :content_identity_and_disclosure,
     %{level: :h2, segments: [%{type: :text, value: "Heading"}]}, :heading},
    {:disclosure, :content_identity_and_disclosure, %{summary: "Details", open?: true},
     :disclosure},
    {:kicker, :content_identity_and_disclosure, %{items: ["Spec", "Runtime"]}, :kicker},
    {:avatar, :content_identity_and_disclosure, %{initials: "PC", accessibility_label: "User"},
     :identity},
    {:presence_dot, :content_identity_and_disclosure, %{state: :active}, :presence},
    {:runtime_form_shell, :form_control_and_composer,
     %{fields: [%{name: :email, label: "Email"}], submit_label: "Save"}, :form},
    {:segmented_button_group, :form_control_and_composer,
     %{options: [%{value: :all, label: "All"}], active_value: :all}, :selection},
    {:chat_composer, :form_control_and_composer, %{value: "Draft", send_intent: :send_message},
     :composer},
    {:collection_picker, :form_control_and_composer,
     %{
       picker_id: "sources",
       query: "adr",
       filters: [%{id: "all", label: "All"}],
       items: [%{id: "adr-1", label: "ADR 1"}],
       suggestions: [%{id: "suggestion-1", label: "Add ADR 2", confidence: 0.8}]
     }, :collection_picker},
    {:list_item_multi_column, :row_and_artifact,
     %{row_identity: "row-1", column_template: [%{id: :title, label: "Title"}]}, :row},
    {:artifact_row, :row_and_artifact, %{title: "Artifact", meta: %{status: :accepted}},
     :artifact},
    {:thread_card, :row_and_artifact,
     %{
       thread_id: "thread:api",
       title: "API discussion",
       reply_count: 2,
       seed_quote: "Should the runtime own this transition?"
     }, :thread},
    {:pipeline_stepper_horizontal, :workflow_progress_and_status,
     %{steps: [%{id: :draft, label: "Draft"}], active_index: 0}, :workflow},
    {:segmented_progress_bar, :workflow_progress_and_status,
     %{segments: [%{label: "Done", weight: 1}], label: "Progress"}, :progress},
    {:workflow_stage_list_vertical, :workflow_progress_and_status,
     %{stages: [%{id: :authored, label: "Authored"}]}, :workflow},
    {:meter_thin, :workflow_progress_and_status, %{current: 50, minimum: 0, maximum: 100},
     :meter},
    {:live_session_card, :workflow_progress_and_status,
     %{
       session_id: "550e8400-e29b-41d4-a716-446655440000",
       actor_handle: "@opus",
       status: :running,
       status_version: 1,
       tools_count: 1,
       edits_count: 0,
       tokens_consumed: 100,
       started_at: ~U[2026-05-27 15:00:00Z]
     }, :live_session},
    {:sticky_frosted_header, :layer_shell_and_callout, %{title: "Workspace"}, :shell},
    {:slide_over_panel, :layer_shell_and_callout, %{label: "Details", open?: true}, :panel},
    {:event_callout, :layer_shell_and_callout, %{message: "Deployment paused"}, :callout},
    {:composer_query_preview, :layer_shell_and_callout,
     %{
       composer_id: "composer-main",
       query: "release blockers",
       preview_state: :ready,
       explanation: "Three likely blockers found.",
       metrics: %{results_count: 3, duration_ms: 42, sources_visited: 8},
       findings: [
         %{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}
       ]
     }, :query_preview},
    {:propose_new_doc_card, :layer_shell_and_callout,
     %{
       target_path: "docs/proposed.md",
       title: "Proposed brief",
       body_md_preview: "Short draft preview.",
       status: :pending
     }, :propose_new_doc},
    {:redline_inline, :redline_and_code, %{segments: [%{state: :insert, text: "new"}]}, :redline},
    {:code_block_syntax_highlighted, :redline_and_code,
     %{language: :elixir, tokens: [%{type: :keyword, text: "def"}]}, :code},
    {:list_repeat, :composition_behavior, %{repeat_binding: :rows, row_fields: [:id]}, :repeat}
  ]

  describe "Section 31.3 - canonical conversion and validation" do
    test "maps every canonical component kind to Unified IUR component attributes" do
      for {kind, family, props, expected_attribute} <- @component_samples do
        assert {:ok, canonical} =
                 kind
                 |> IUR.new(id: "component-#{kind}", props: props)
                 |> IURAdapter.to_canonical()

        assert canonical.type == :widget
        assert canonical.kind == kind
        assert canonical.attributes.component == %{family: family, kind: kind}
        assert Map.has_key?(canonical.attributes, expected_attribute)
        assert_valid_canonical(canonical)
      end
    end

    test "normalizes compatibility aliases before renderer-facing canonical output" do
      aliases = [
        {:phoenix_form, :runtime_form_shell, %{fields: [%{name: :email, label: "Email"}]}},
        {:repeat, :list_repeat, %{repeat_binding: :rows, row_fields: [:id]}},
        {:ui_relationship_repeat, :list_repeat, %{repeat_binding: :rows, row_fields: [:id]}}
      ]

      for {alias_kind, canonical_kind, props} <- aliases do
        assert {:ok, canonical} =
                 alias_kind
                 |> IUR.new(props: props)
                 |> IURAdapter.to_canonical()

        assert canonical.kind == canonical_kind
        refute canonical.kind == alias_kind
        assert_valid_canonical(canonical)
      end
    end

    test "keeps Ash resource metadata under Ash-owned metadata only" do
      assert {:ok, canonical} =
               IUR.new(:avatar,
                 props: %{initials: "PC", accessibility_label: "Pascal Charbonneau"},
                 metadata: %{resource: "User.Profile"}
               )
               |> IURAdapter.to_canonical()

      assert canonical.metadata.extra["ash_ui"] == %{resource: "User.Profile"}
      assert canonical.attributes.component.kind == :avatar
      refute Map.has_key?(canonical.attributes, :ash_ui)
      assert_valid_canonical(canonical)
    end

    test "normalizes presence dot default state and decorative accessibility" do
      assert {:ok, canonical} =
               :presence_dot
               |> IUR.new(props: %{decorative?: true})
               |> IURAdapter.to_canonical()

      assert canonical.attributes.presence.state == :offline
      assert canonical.attributes.accessibility.decorative? == true
      assert_valid_canonical(canonical)
    end

    test "fails invalid required component shapes through Unified IUR validation" do
      invalid_samples = [
        {:redline_inline, %{segments: [%{state: :unknown, text: "bad"}]}, :invalid_text_segment},
        {:code_block_syntax_highlighted, %{tokens: [%{type: :unknown, text: "bad"}]},
         :invalid_code_token},
        {:slide_over_panel, %{open?: true}, :missing_accessible_name},
        {:meter_thin, %{current: 150, minimum: 0, maximum: 100}, :invalid_progress_value},
        {:segmented_button_group, %{options: [%{label: "Missing value"}]},
         :invalid_selection_option},
        {:list_repeat, %{row_fields: [:id]}, :invalid_repeat_binding}
      ]

      for {kind, props, error_code} <- invalid_samples do
        assert {:error, {:conversion_failed, errors}} =
                 kind
                 |> IUR.new(props: props)
                 |> IURAdapter.to_canonical()

        assert Enum.any?(errors, &(&1.code == error_code))
      end
    end
  end

  defp assert_valid_canonical(canonical) do
    assert {:ok, %UnifiedIUR.Element{} = normalized} = UnifiedIUR.Normalize.element(canonical)
    assert :ok = UnifiedIUR.Validate.element(normalized)
  end
end
