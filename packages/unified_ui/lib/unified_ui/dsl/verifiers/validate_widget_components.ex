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

  def validate_node(%Node{kind: :slide_over_panel, id: id, modal?: modal?}) do
    if modal? in [false, nil] do
      :ok
    else
      {:error, [:composition, :slide_over_panel, id],
       "slide_over_panel #{inspect(id)} must remain non-modal; use dialog for modal layers"}
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

  defp flatten_nodes(nodes) do
    Enum.flat_map(nodes, fn %Node{children: children} = node ->
      [node | flatten_nodes(children)]
    end)
  end
end
