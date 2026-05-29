defmodule UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents do
  @moduledoc false

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias UnifiedUi.Binding
  alias UnifiedUi.Dsl.Node

  @heading_segment_types [:text, :emphasis]
  @redline_states [:keep, :insert, :delete, :accepted, :rejected]
  @artifact_kinds [:pr, :doc, :spec, :file, :grain, :generic]
  @artifact_badge_tones [:positive, :warning, :danger, :info, :neutral]
  @rail_sides [:right]
  @rail_forbidden_panel_keys ~w[
    event
    helper
    live_action
    module
    on_click
    path
    phx-click
    phx_click
    phx_event
    route
    runtime_module
    url
  ]
  @progress_card_forbidden_keys ~w[
    event
    helper
    live_action
    module
    on_click
    path
    phx-click
    phx_click
    phx_event
    route
    runtime_module
    url
  ]
  @collection_picker_forbidden_keys ~w[
    bundle
    bundle_id
    bundle_item
    bundle_item_card
    bundle_rail
    drag_drop_hook
    event
    event_target
    helper
    item_slot
    live_action
    module
    on_accept_event
    on_change
    on_click
    on_dismiss_event
    on_search_change
    on_toggle_event
    path
    phx-change
    phx-click
    phx_change
    phx_click
    phx_event
    route
    runtime_module
    url
  ]
  @query_preview_states [:loading, :ready, :empty, :error]
  @propose_new_doc_statuses [:pending, :accepted, :rejected, :archived]
  @propose_new_doc_actions [:accept, :reject, :preview]
  @escalation_severities [:p1, :p2, :p3]

  @spec verify(map()) :: :ok | {:error, Spark.Error.DslError.t()}
  def verify(dsl) do
    module = Verifier.get_persisted(dsl, :module)

    bindings =
      dsl
      |> Verifier.get_entities([:signals])
      |> Enum.filter(&match?(%Binding{}, &1))
      |> Map.new(&{&1.id, &1})

    dsl
    |> Verifier.get_entities([:composition])
    |> Enum.filter(&match?(%Node{}, &1))
    |> flatten_nodes()
    |> validate_nodes(module, bindings)
  end

  defp validate_nodes(nodes, module, bindings) do
    Enum.reduce_while(nodes, :ok, fn node, :ok ->
      case validate_node_with_context(node, bindings) do
        :ok ->
          {:cont, :ok}

        {:error, path, message} ->
          {:halt, {:error, %Spark.Error.DslError{module: module, path: path, message: message}}}
      end
    end)
  end

  defp validate_node_with_context(node, bindings) do
    with :ok <- validate_node(node) do
      validate_repeat_binding(node, bindings)
    end
  end

  @doc false
  @spec validate_node(Node.t()) :: :ok | {:error, [term()], String.t()}
  def validate_node(%Node{kind: :inline_rich_text_heading, id: id, segments: segments}) do
    if valid_heading_segments?(segments) do
      :ok
    else
      {:error, [:composition, :inline_rich_text_heading, id],
       "inline_rich_text_heading #{inspect(id)} segments must be a non-empty list of text or emphasis segment maps with string values"}
    end
  end

  def validate_node(%Node{kind: :kicker, id: id, items: items}) do
    if is_list(items) and Enum.all?(items, &is_binary/1) do
      :ok
    else
      {:error, [:composition, :kicker, id],
       "kicker #{inspect(id)} items must be a list of strings"}
    end
  end

  def validate_node(%Node{kind: :segmented_button_group, id: id, options: options}) do
    if valid_options?(options) do
      :ok
    else
      {:error, [:composition, :segmented_button_group, id],
       "segmented_button_group #{inspect(id)} options must be a non-empty list of {value, label} tuples or maps with value and label"}
    end
  end

  def validate_node(%Node{kind: :runtime_form_shell, id: id, fields: fields}) do
    if valid_form_fields?(fields) do
      :ok
    else
      {:error, [:composition, :runtime_form_shell, id],
       "runtime_form_shell #{inspect(id)} fields must be a non-empty list of maps with name and type"}
    end
  end

  def validate_node(%Node{kind: :chat_composer, id: id, rows: rows, send_intent: send_intent}) do
    cond do
      not is_atom(send_intent) ->
        {:error, [:composition, :chat_composer, id],
         "chat_composer #{inspect(id)} send_intent must be an atom"}

      not is_integer(rows) or rows < 1 ->
        {:error, [:composition, :chat_composer, id],
         "chat_composer #{inspect(id)} rows must be a positive integer"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :collection_picker,
        id: id,
        picker_id: picker_id,
        query: query,
        filters: filters,
        items: items,
        suggestions: suggestions
      }) do
    cond do
      not is_binary(picker_id) or picker_id == "" ->
        {:error, [:composition, :collection_picker, id],
         "collection_picker #{inspect(id)} picker_id must be a non-empty string"}

      not is_binary(query || "") ->
        {:error, [:composition, :collection_picker, id],
         "collection_picker #{inspect(id)} query must be a string when present"}

      not valid_collection_picker_filters?(filters || []) ->
        {:error, [:composition, :collection_picker, id],
         "collection_picker #{inspect(id)} filters must be generic id/label maps without host-specific event or route fields"}

      not valid_collection_picker_items?(items || []) ->
        {:error, [:composition, :collection_picker, id],
         "collection_picker #{inspect(id)} items must be generic id/label maps without bundle-specific slots or host event fields"}

      not valid_collection_picker_suggestions?(suggestions || []) ->
        {:error, [:composition, :collection_picker, id],
         "collection_picker #{inspect(id)} suggestions must be generic id/label maps with optional confidence in 0.0..1.0"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :list_item_multi_column,
        id: id,
        row_identity: row_identity,
        column_template: column_template
      }) do
    cond do
      not valid_scalar?(row_identity) ->
        {:error, [:composition, :list_item_multi_column, id],
         "list_item_multi_column #{inspect(id)} row_identity must be a non-empty scalar value"}

      not valid_column_template?(column_template) ->
        {:error, [:composition, :list_item_multi_column, id],
         "list_item_multi_column #{inspect(id)} column_template must be a non-empty list of column maps with id and label"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :artifact_row,
        id: id,
        row_identity: row_identity,
        title: title,
        artifact_kind: artifact_kind,
        status_badges: status_badges,
        counts: counts,
        timestamp_at: timestamp_at
      }) do
    cond do
      not is_binary(title) or title == "" ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} title must be a non-empty string"}

      not valid_scalar?(row_identity) ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} row_identity must be a non-empty scalar value"}

      not valid_artifact_kind?(artifact_kind) ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} artifact_kind must be one of #{inspect(@artifact_kinds)}"}

      not valid_status_badges?(status_badges) ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} status_badges must be a list of maps with label and optional supported tone"}

      not valid_artifact_counts?(counts) ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} counts must be a map or a list of maps with key and value"}

      not valid_timestamp?(timestamp_at) ->
        {:error, [:composition, :artifact_row, id],
         "artifact_row #{inspect(id)} timestamp_at must be a DateTime, NaiveDateTime, or ISO8601 string"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :pipeline_stepper_horizontal,
        id: id,
        steps: steps,
        active_index: active_index,
        completed_indices: completed_indices
      }) do
    cond do
      not valid_labeled_state_items?(steps) ->
        {:error, [:composition, :pipeline_stepper_horizontal, id],
         "pipeline_stepper_horizontal #{inspect(id)} steps must be a non-empty list of maps with id, label, and state"}

      not valid_index?(active_index, steps) ->
        {:error, [:composition, :pipeline_stepper_horizontal, id],
         "pipeline_stepper_horizontal #{inspect(id)} active_index must reference an existing step"}

      not valid_indices?(completed_indices, steps) ->
        {:error, [:composition, :pipeline_stepper_horizontal, id],
         "pipeline_stepper_horizontal #{inspect(id)} completed_indices must reference existing steps"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{kind: :segmented_progress_bar, id: id, segments: segments}) do
    if valid_progress_segments?(segments) do
      :ok
    else
      {:error, [:composition, :segmented_progress_bar, id],
       "segmented_progress_bar #{inspect(id)} segments must be a non-empty list of maps with label and positive weight or value"}
    end
  end

  def validate_node(%Node{
        kind: :workflow_stage_list_vertical,
        id: id,
        stages: stages,
        active_index: active_index
      }) do
    cond do
      not valid_labeled_state_items?(stages) ->
        {:error, [:composition, :workflow_stage_list_vertical, id],
         "workflow_stage_list_vertical #{inspect(id)} stages must be a non-empty list of maps with id, label, and state"}

      not valid_index?(active_index, stages) ->
        {:error, [:composition, :workflow_stage_list_vertical, id],
         "workflow_stage_list_vertical #{inspect(id)} active_index must reference an existing stage"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :meter_thin,
        id: id,
        current: current,
        minimum: min,
        maximum: max
      }) do
    if valid_meter_range?(current, min, max) do
      :ok
    else
      {:error, [:composition, :meter_thin, id],
       "meter_thin #{inspect(id)} current, minimum, and maximum must be numeric and current must be within range"}
    end
  end

  def validate_node(%Node{
        kind: :workflow_progress_status_card,
        id: id,
        name: name,
        progress_pct: progress_pct,
        active_count: active_count,
        blocked_count: blocked_count,
        depends_on: depends_on,
        depended_by: depended_by,
        open_action: open_action
      }) do
    cond do
      not is_binary(name) or name == "" ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} name must be a non-empty string"}

      not valid_subject_progress?(progress_pct) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} progress_pct must be a number in 0.0..1.0"}

      not valid_non_negative_integer?(active_count) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} active_count must be a non-negative integer"}

      not valid_non_negative_integer?(blocked_count) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} blocked_count must be a non-negative integer"}

      not valid_subject_dependency_names?(depends_on) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} depends_on must be a list of subject name strings"}

      not valid_subject_dependency_names?(depended_by) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} depended_by must be a list of subject name strings"}

      not valid_subject_open_action?(open_action) ->
        {:error, [:composition, :workflow_progress_status_card, id],
         "workflow_progress_status_card #{inspect(id)} open_action must have label and intent without host-specific event or route fields"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{kind: :slide_over_panel, id: id, modal?: modal?}) do
    if modal? in [false, nil] do
      :ok
    else
      {:error, [:composition, :slide_over_panel, id],
       "slide_over_panel #{inspect(id)} must remain non-modal; use dialog for modal layers"}
    end
  end

  def validate_node(%Node{
        kind: :right_rail,
        id: id,
        side: side,
        panels: panels,
        active_panel: active_panel
      }) do
    cond do
      side not in @rail_sides ->
        {:error, [:composition, :right_rail, id],
         "right_rail #{inspect(id)} side must be one of #{inspect(@rail_sides)}"}

      not valid_rail_panels?(panels) ->
        {:error, [:composition, :right_rail, id],
         "right_rail #{inspect(id)} panels must be a non-empty list of maps with id and label and without host-specific event or route fields"}

      not active_rail_panel?(active_panel, panels) ->
        {:error, [:composition, :right_rail, id],
         "right_rail #{inspect(id)} active_panel must reference one of the declared panel ids"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :composer_query_preview,
        id: id,
        composer_id: composer_id,
        query: query,
        preview_state: preview_state,
        explanation: explanation,
        metrics: metrics,
        findings: findings,
        max_findings_shown: max_findings_shown
      }) do
    cond do
      not is_binary(composer_id) or composer_id == "" ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} composer_id must be a non-empty string"}

      not is_binary(query) or query == "" ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} query must be a non-empty string"}

      preview_state not in @query_preview_states ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} preview_state must be one of #{inspect(@query_preview_states)}"}

      preview_state == :ready and (not is_binary(explanation) or explanation == "") ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} explanation is required for ready previews"}

      not valid_optional_query_preview_metrics?(metrics) ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} metrics must be a map with non-negative integer counts"}

      not valid_query_preview_findings?(findings) ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} findings must be a list of maps with id, n, snippet, and confidence"}

      not valid_positive_integer?(max_findings_shown) ->
        {:error, [:composition, :composer_query_preview, id],
         "composer_query_preview #{inspect(id)} max_findings_shown must be a positive integer"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :propose_new_doc_card,
        id: id,
        target_path: target_path,
        title: title,
        body_md_preview: body_md_preview,
        body_md: body_md,
        status: status,
        conversation_seed_md: conversation_seed_md,
        actor_handle: actor_handle,
        proposed_at: proposed_at,
        actions: actions
      }) do
    cond do
      not non_blank_string?(target_path) ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} target_path must be a non-empty string"}

      not non_blank_string?(title) ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} title must be a non-empty string"}

      not non_blank_string?(body_md_preview) and not non_blank_string?(body_md) ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} body_md_preview or body_md must be a non-empty string"}

      not optional_string?(body_md_preview) or not optional_string?(body_md) or
        not optional_string?(conversation_seed_md) or not optional_string?(actor_handle) or
          not optional_string?(proposed_at) ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} markdown, actor, and timestamp fields must be strings when present"}

      status not in @propose_new_doc_statuses ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} status must be one of #{inspect(@propose_new_doc_statuses)}"}

      not valid_propose_new_doc_actions?(actions) ->
        {:error, [:composition, :propose_new_doc_card, id],
         "propose_new_doc_card #{inspect(id)} actions must be a list containing only accept, reject, or preview"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{
        kind: :escalation_card,
        id: id,
        target_project_id: target_project_id,
        text: text,
        severity: severity,
        related_finding_id: related_finding_id,
        proposed_action: proposed_action,
        target_finding_id: target_finding_id,
        target_severity: target_severity,
        originating_severity: originating_severity,
        actor_handle: actor_handle,
        escalated_at: escalated_at
      }) do
    cond do
      not non_blank_string?(target_project_id) ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} target_project_id must be a non-empty string"}

      not non_blank_string?(text) ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} text must be a non-empty string"}

      severity not in @escalation_severities ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} severity must be one of #{inspect(@escalation_severities)}"}

      not optional_string?(related_finding_id) or not optional_string?(proposed_action) or
        not optional_string?(target_finding_id) or not optional_string?(actor_handle) or
          not optional_string?(escalated_at) ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} optional string fields must be strings when present"}

      not (is_nil(target_severity) or target_severity in @escalation_severities) ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} target_severity must be one of #{inspect(@escalation_severities)}"}

      not (is_nil(originating_severity) or originating_severity in @escalation_severities) ->
        {:error, [:composition, :escalation_card, id],
         "escalation_card #{inspect(id)} originating_severity must be one of #{inspect(@escalation_severities)}"}

      true ->
        :ok
    end
  end

  def validate_node(%Node{kind: :redline_inline, id: id, segments: segments}) do
    if valid_redline_segments?(segments) do
      :ok
    else
      {:error, [:composition, :redline_inline, id],
       "redline_inline #{inspect(id)} segments must be a non-empty list of plain-text segment maps with supported state"}
    end
  end

  def validate_node(%Node{kind: :code_block_syntax_highlighted, id: id, tokens: tokens}) do
    if valid_code_tokens?(tokens) do
      :ok
    else
      {:error, [:composition, :code_block_syntax_highlighted, id],
       "code_block_syntax_highlighted #{inspect(id)} tokens must be a non-empty list of plain-text token maps with type and text"}
    end
  end

  def validate_node(%Node{
        kind: :list_repeat,
        id: id,
        repeat_binding: repeat_binding,
        row_scope: row_scope,
        row_fields: row_fields,
        children: children
      }) do
    cond do
      not is_atom(repeat_binding) ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} repeat_binding must reference a declared collection data_binding"}

      not is_atom(row_scope) ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} row_scope must be an atom"}

      not valid_row_fields?(row_fields) ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} row_fields must be shallow atom or string field names without host-specific path syntax"}

      length(children) != 1 ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} must declare exactly one child template"}

      not valid_repeat_template?(List.first(children)) ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} child template must be an artifact, row, or event-callout component"}

      true ->
        :ok
    end
  end

  def validate_node(_node), do: :ok

  defp validate_repeat_binding(
         %Node{kind: :list_repeat, id: id, repeat_binding: repeat_binding},
         bindings
       ) do
    cond do
      not Map.has_key?(bindings, repeat_binding) ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} repeat_binding #{inspect(repeat_binding)} must reference a declared data_binding"}

      not Map.fetch!(bindings, repeat_binding).collection? ->
        {:error, [:composition, :list_repeat, id],
         "list_repeat #{inspect(id)} repeat_binding #{inspect(repeat_binding)} must reference a collection data_binding"}

      true ->
        :ok
    end
  end

  defp validate_repeat_binding(_node, _bindings), do: :ok

  defp valid_heading_segments?(segments) when is_list(segments) and segments != [] do
    Enum.all?(segments, &valid_heading_segment?/1)
  end

  defp valid_heading_segments?(_segments), do: false

  defp valid_heading_segment?(segment) when is_map(segment) or is_list(segment) do
    segment = normalize_map(segment)
    Map.get(segment, :type) in @heading_segment_types and is_binary(Map.get(segment, :value))
  end

  defp valid_heading_segment?(_segment), do: false

  defp valid_options?(options) when is_list(options) and options != [] do
    Enum.all?(options, fn
      {value, label} ->
        valid_scalar?(value) and is_binary(label)

      option when is_map(option) or is_list(option) ->
        option = normalize_map(option)
        valid_scalar?(Map.get(option, :value)) and is_binary(Map.get(option, :label))

      _other ->
        false
    end)
  end

  defp valid_options?(_options), do: false

  defp valid_collection_picker_filters?(filters) when is_list(filters) do
    Enum.all?(filters, &valid_collection_picker_filter?/1)
  end

  defp valid_collection_picker_filters?(_filters), do: false

  defp valid_collection_picker_filter?(filter) when is_map(filter) or is_list(filter) do
    filter = normalize_map(filter)
    selected? = field(filter, :selected?)
    disabled? = field(filter, :disabled?)
    count = field(filter, :count)

    valid_scalar?(field(filter, :id)) and is_binary(field(filter, :label)) and
      (is_nil(selected?) or is_boolean(selected?)) and
      (is_nil(disabled?) or is_boolean(disabled?)) and
      (is_nil(count) or valid_non_negative_integer?(count)) and
      not has_forbidden_collection_picker_key_deep?(filter)
  end

  defp valid_collection_picker_filter?(_filter), do: false

  defp valid_collection_picker_items?(items) when is_list(items) do
    Enum.all?(items, &valid_collection_picker_item?/1)
  end

  defp valid_collection_picker_items?(_items), do: false

  defp valid_collection_picker_item?(item) when is_map(item) or is_list(item) do
    item = normalize_map(item)
    selected? = field(item, :selected?)
    disabled? = field(item, :disabled?)
    draggable? = field(item, :draggable?)
    description = field(item, :description)
    meta = field(item, :meta)

    valid_scalar?(field(item, :id)) and is_binary(field(item, :label)) and
      (is_nil(description) or is_binary(description)) and
      (is_nil(meta) or is_map(meta)) and
      (is_nil(selected?) or is_boolean(selected?)) and
      (is_nil(disabled?) or is_boolean(disabled?)) and
      (is_nil(draggable?) or is_boolean(draggable?)) and
      not has_forbidden_collection_picker_key_deep?(item)
  end

  defp valid_collection_picker_item?(_item), do: false

  defp valid_collection_picker_suggestions?(suggestions) when is_list(suggestions) do
    Enum.all?(suggestions, &valid_collection_picker_suggestion?/1)
  end

  defp valid_collection_picker_suggestions?(_suggestions), do: false

  defp valid_collection_picker_suggestion?(suggestion)
       when is_map(suggestion) or is_list(suggestion) do
    suggestion = normalize_map(suggestion)
    description = field(suggestion, :description)
    source = field(suggestion, :source)
    confidence = field(suggestion, :confidence)
    disabled? = field(suggestion, :disabled?)

    valid_scalar?(field(suggestion, :id)) and is_binary(field(suggestion, :label)) and
      (is_nil(description) or is_binary(description)) and
      (is_nil(source) or is_binary(source)) and
      (is_nil(disabled?) or is_boolean(disabled?)) and
      (is_nil(confidence) or
         (is_number(confidence) and confidence >= 0.0 and confidence <= 1.0)) and
      not has_forbidden_collection_picker_key_deep?(suggestion)
  end

  defp valid_collection_picker_suggestion?(_suggestion), do: false

  defp valid_form_fields?(fields) when is_list(fields) and fields != [] do
    Enum.all?(fields, fn
      field when is_map(field) or is_list(field) ->
        field = normalize_map(field)

        valid_scalar?(Map.get(field, :name)) and valid_scalar?(Map.get(field, :type)) and
          valid_field_attributes?(Map.get(field, :attributes))

      _other ->
        false
    end)
  end

  defp valid_form_fields?(_fields), do: false

  defp valid_column_template?(columns) when is_list(columns) and columns != [] do
    Enum.all?(columns, fn
      column when is_map(column) or is_list(column) ->
        column = normalize_map(column)
        valid_scalar?(Map.get(column, :id)) and is_binary(Map.get(column, :label))

      _other ->
        false
    end)
  end

  defp valid_column_template?(_columns), do: false

  defp valid_artifact_kind?(nil), do: true
  defp valid_artifact_kind?(kind), do: kind in @artifact_kinds

  defp valid_status_badges?(nil), do: true
  defp valid_status_badges?([]), do: true

  defp valid_status_badges?(badges) when is_list(badges) do
    Enum.all?(badges, fn
      badge when is_map(badge) or is_list(badge) ->
        badge = normalize_map(badge)
        tone = Map.get(badge, :tone)

        is_binary(Map.get(badge, :label)) and (is_nil(tone) or tone in @artifact_badge_tones)

      _other ->
        false
    end)
  end

  defp valid_status_badges?(_badges), do: false

  defp valid_artifact_counts?(nil), do: true
  defp valid_artifact_counts?(counts) when is_map(counts), do: true

  defp valid_artifact_counts?(counts) when is_list(counts) do
    Enum.all?(counts, fn
      {key, _value} ->
        valid_scalar?(key)

      count when is_map(count) or is_list(count) ->
        count = normalize_map(count)
        valid_scalar?(Map.get(count, :key)) and Map.has_key?(count, :value)

      _other ->
        false
    end)
  end

  defp valid_artifact_counts?(_counts), do: false

  defp valid_timestamp?(nil), do: true
  defp valid_timestamp?(%DateTime{}), do: true
  defp valid_timestamp?(%NaiveDateTime{}), do: true

  defp valid_timestamp?(value) when is_binary(value) do
    match?({:ok, _datetime, _offset}, DateTime.from_iso8601(value)) or
      match?({:ok, _datetime}, NaiveDateTime.from_iso8601(value))
  end

  defp valid_timestamp?(_value), do: false

  defp valid_labeled_state_items?(items) when is_list(items) and items != [] do
    Enum.all?(items, fn
      item when is_map(item) or is_list(item) ->
        item = normalize_map(item)

        valid_scalar?(Map.get(item, :id)) and is_binary(Map.get(item, :label)) and
          valid_scalar?(Map.get(item, :state))

      _other ->
        false
    end)
  end

  defp valid_labeled_state_items?(_items), do: false

  defp valid_progress_segments?(segments) when is_list(segments) and segments != [] do
    Enum.all?(segments, fn
      segment when is_map(segment) or is_list(segment) ->
        segment = normalize_map(segment)

        is_binary(Map.get(segment, :label)) and
          positive_number?(segment[:weight] || segment[:value])

      _other ->
        false
    end)
  end

  defp valid_progress_segments?(_segments), do: false

  defp valid_redline_segments?(segments) when is_list(segments) and segments != [] do
    Enum.all?(segments, fn
      segment when is_map(segment) or is_list(segment) ->
        segment = normalize_map(segment)
        Map.get(segment, :state) in @redline_states and is_binary(Map.get(segment, :text))

      _other ->
        false
    end)
  end

  defp valid_redline_segments?(_segments), do: false

  defp valid_code_tokens?(tokens) when is_list(tokens) and tokens != [] do
    Enum.all?(tokens, fn
      token when is_map(token) or is_list(token) ->
        token = normalize_map(token)
        valid_scalar?(Map.get(token, :type)) and is_binary(Map.get(token, :text))

      _other ->
        false
    end)
  end

  defp valid_code_tokens?(_tokens), do: false

  defp valid_row_fields?(fields) when is_list(fields) do
    Enum.all?(fields, fn
      field when is_atom(field) ->
        true

      field when is_binary(field) ->
        field != "" and not String.contains?(field, [".", "[", "]", "->", "::"])

      _other ->
        false
    end)
  end

  defp valid_row_fields?(_fields), do: false

  defp valid_repeat_template?(%Node{kind: kind}) do
    kind in [:artifact_row, :list_item_multi_column, :event_callout]
  end

  defp valid_repeat_template?(_node), do: false

  defp valid_rail_panels?(panels) when is_list(panels) and panels != [] do
    Enum.all?(panels, &valid_rail_panel?/1)
  end

  defp valid_rail_panels?(_panels), do: false

  defp valid_rail_panel?(panel) when is_map(panel) or is_list(panel) do
    panel = normalize_map(panel)
    disabled? = field(panel, :disabled?)
    content_slot = field(panel, :content_slot)

    valid_scalar?(field(panel, :id)) and is_binary(field(panel, :label)) and
      (is_nil(disabled?) or is_boolean(disabled?)) and
      (is_nil(content_slot) or valid_scalar?(content_slot)) and
      not has_forbidden_rail_panel_key?(panel)
  end

  defp valid_rail_panel?(_panel), do: false

  defp valid_optional_query_preview_metrics?(nil), do: true

  defp valid_optional_query_preview_metrics?(metrics) when is_map(metrics) or is_list(metrics) do
    metrics = normalize_map(metrics)

    [:results_count, :findings_count, :duration_ms, :sources_visited, :grains_visited]
    |> Enum.all?(fn key ->
      case field(metrics, key) do
        nil -> true
        value -> valid_non_negative_integer?(value)
      end
    end)
  end

  defp valid_optional_query_preview_metrics?(_metrics), do: false

  defp valid_query_preview_findings?(findings) when is_list(findings) do
    Enum.all?(findings, &valid_query_preview_finding?/1)
  end

  defp valid_query_preview_findings?(_findings), do: false

  defp valid_query_preview_finding?(finding) when is_map(finding) or is_list(finding) do
    finding = normalize_map(finding)
    id = field(finding, :id) || field(finding, :finding_id)
    confidence = field(finding, :confidence)

    is_binary(id) and id != "" and valid_positive_integer?(field(finding, :n)) and
      is_binary(field(finding, :snippet)) and field(finding, :snippet) != "" and
      is_number(confidence) and confidence >= 0.0 and confidence <= 1.0
  end

  defp valid_query_preview_finding?(_finding), do: false

  defp active_rail_panel?(active_panel, panels) do
    valid_scalar?(active_panel) and
      Enum.any?(panels, fn panel ->
        panel = normalize_map(panel)
        to_string(field(panel, :id)) == to_string(active_panel)
      end)
  end

  defp has_forbidden_rail_panel_key?(panel) do
    panel
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @rail_forbidden_panel_keys))
  end

  defp valid_index?(index, items) when is_integer(index) and is_list(items) do
    index >= 0 and index < length(items)
  end

  defp valid_index?(_index, _items), do: false

  defp valid_indices?(indices, items) when is_list(indices) do
    Enum.all?(indices, &valid_index?(&1, items))
  end

  defp valid_indices?(_indices, _items), do: false

  defp valid_meter_range?(current, min, max)
       when is_number(current) and is_number(min) and is_number(max) do
    min <= max and current >= min and current <= max
  end

  defp valid_meter_range?(_current, _min, _max), do: false

  defp valid_subject_progress?(nil), do: true

  defp valid_subject_progress?(value) when is_number(value) do
    value >= 0.0 and value <= 1.0
  end

  defp valid_subject_progress?(_value), do: false

  defp valid_non_negative_integer?(nil), do: true
  defp valid_non_negative_integer?(value), do: is_integer(value) and value >= 0
  defp valid_positive_integer?(value), do: is_integer(value) and value > 0

  defp valid_subject_dependency_names?(nil), do: true

  defp valid_subject_dependency_names?(dependencies) when is_list(dependencies) do
    Enum.all?(dependencies, &is_binary/1)
  end

  defp valid_subject_dependency_names?(_dependencies), do: false

  defp valid_subject_open_action?(nil), do: true

  defp valid_subject_open_action?(action) when is_map(action) or is_list(action) do
    action = normalize_map(action)

    is_binary(field(action, :label)) and valid_scalar?(field(action, :intent)) and
      not has_forbidden_progress_card_key?(action)
  end

  defp valid_subject_open_action?(_action), do: false

  defp has_forbidden_progress_card_key?(map) do
    map
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @progress_card_forbidden_keys))
  end

  defp has_forbidden_collection_picker_key?(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @collection_picker_forbidden_keys))
  end

  defp has_forbidden_collection_picker_key?(_map), do: false

  defp has_forbidden_collection_picker_key_deep?(value) when is_map(value) do
    has_forbidden_collection_picker_key?(value) or
      Enum.any?(Map.values(value), &has_forbidden_collection_picker_key_deep?/1)
  end

  defp has_forbidden_collection_picker_key_deep?(value) when is_list(value) do
    Enum.any?(value, &has_forbidden_collection_picker_key_deep?/1)
  end

  defp has_forbidden_collection_picker_key_deep?(_value), do: false

  defp valid_field_attributes?(nil), do: true
  defp valid_field_attributes?(attributes) when is_map(attributes), do: true

  defp valid_field_attributes?(attributes) when is_list(attributes) do
    Keyword.keyword?(attributes)
  end

  defp valid_field_attributes?(_attributes), do: false

  defp valid_scalar?(nil), do: false
  defp valid_scalar?(""), do: false
  defp valid_scalar?(value) when is_atom(value) or is_binary(value) or is_number(value), do: true
  defp valid_scalar?(_value), do: false

  defp non_blank_string?(value), do: is_binary(value) and String.trim(value) != ""
  defp optional_string?(nil), do: true
  defp optional_string?(value), do: is_binary(value)

  defp valid_propose_new_doc_actions?(actions) when is_list(actions) do
    actions != [] and Enum.all?(actions, &(&1 in @propose_new_doc_actions))
  end

  defp valid_propose_new_doc_actions?(_actions), do: false

  defp positive_number?(value) when is_number(value), do: value > 0
  defp positive_number?(_value), do: false

  defp normalize_map(segment) when is_map(segment) do
    Map.new(segment, fn
      {key, value} when is_binary(key) ->
        {String.to_existing_atom(key), value}

      {key, value} ->
        {key, value}
    end)
  rescue
    ArgumentError -> segment
  end

  defp normalize_map(segment) when is_list(segment), do: Map.new(segment)

  defp field(map, key) do
    Map.get(map, key, Map.get(map, Atom.to_string(key)))
  end

  defp flatten_nodes(nodes) do
    Enum.flat_map(nodes, fn %Node{children: children} = node ->
      [node | flatten_nodes(children)]
    end)
  end
end
