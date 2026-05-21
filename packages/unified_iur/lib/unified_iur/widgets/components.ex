defmodule UnifiedIUR.Widgets.Components do
  @moduledoc """
  Canonical constructors for the expanded widget-component catalog.

  These constructors preserve the portable content, state, accessibility, and
  safety shape for the AshUi PR 79-98 equivalents without embedding any runtime
  package implementation model.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Metadata

  # Spec traceability:
  # unified_iur.widget_components.canonical_node_types
  # unified_iur.widget_components.content_models
  # unified_iur.widget_components.interaction_descriptors
  # unified_iur.widget_components.accessibility_and_state_metadata
  # unified_iur.widget_components.text_safety_contract
  # unified_iur.widget_components.list_repeat_metadata
  # unified_iur.widget_components.runtime_mapping_completeness
  # unified_iur.widgets.expanded_widget_component_catalog
  # unified_iur.widgets.widget_semantics_preserved

  @type opts :: keyword() | map()

  @content_identity_kinds [
    :inline_rich_text_heading,
    :disclosure,
    :kicker,
    :avatar,
    :presence_dot
  ]

  @form_control_kinds [
    :segmented_button_group,
    :runtime_form_shell,
    :chat_composer,
    :collection_picker,
    :mode_nav
  ]

  @row_artifact_kinds [
    :list_item_multi_column,
    :artifact_row,
    :thread_card
  ]

  @artifact_kinds [
    :pr,
    :doc,
    :spec,
    :file,
    :grain,
    :generic
  ]

  @workflow_kinds [
    :pipeline_stepper_horizontal,
    :segmented_progress_bar,
    :workflow_stage_list_vertical,
    :meter_thin,
    :unread_badge,
    :workflow_progress_status_card
  ]

  @layer_callout_kinds [
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

  @query_preview_states [:loading, :ready, :empty, :error]

  @redline_code_kinds [
    :redline_inline,
    :code_block_syntax_highlighted
  ]

  @composition_behavior_kinds [
    :list_repeat
  ]

  @spec content_identity_kinds() :: [atom()]
  def content_identity_kinds, do: @content_identity_kinds

  @spec form_control_kinds() :: [atom()]
  def form_control_kinds, do: @form_control_kinds

  @spec row_artifact_kinds() :: [atom()]
  def row_artifact_kinds, do: @row_artifact_kinds

  @spec artifact_kinds() :: [atom()]
  def artifact_kinds, do: @artifact_kinds

  @spec workflow_kinds() :: [atom()]
  def workflow_kinds, do: @workflow_kinds

  @spec layer_callout_kinds() :: [atom()]
  def layer_callout_kinds, do: @layer_callout_kinds

  @spec redline_code_kinds() :: [atom()]
  def redline_code_kinds, do: @redline_code_kinds

  @spec composition_behavior_kinds() :: [atom()]
  def composition_behavior_kinds, do: @composition_behavior_kinds

  @spec kinds() :: [atom()]
  def kinds do
    @content_identity_kinds ++
      @form_control_kinds ++
      @row_artifact_kinds ++
      @workflow_kinds ++
      @layer_callout_kinds ++
      @redline_code_kinds ++
      @composition_behavior_kinds
  end

  @spec inline_rich_text_heading(atom(), [keyword() | map()], opts()) :: Element.t()
  def inline_rich_text_heading(level, segments, opts \\ [])
      when is_atom(level) and is_list(segments) do
    build_component(
      :inline_rich_text_heading,
      :content_identity_and_disclosure,
      %{heading: %{level: level, segments: normalize_maps(segments)}},
      opts
    )
  end

  @spec disclosure(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def disclosure(summary, children \\ [], opts \\ [])
      when is_binary(summary) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :disclosure,
      :content_identity_and_disclosure,
      %{disclosure: %{summary: summary, open?: option(opts, :open?, false)}},
      Map.put(opts, :children, children)
    )
  end

  @spec kicker([String.t()], opts()) :: Element.t()
  def kicker(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    build_component(
      :kicker,
      :content_identity_and_disclosure,
      %{kicker: %{items: items, separator: option(opts, :separator, "·")}},
      opts
    )
  end

  @spec avatar(opts()) :: Element.t()
  def avatar(opts \\ []) do
    opts = normalize_opts(opts)

    build_component(
      :avatar,
      :content_identity_and_disclosure,
      %{
        identity:
          %{}
          |> maybe_put(:initials, option(opts, :initials))
          |> maybe_put(:image_source, option(opts, :image_source))
          |> maybe_put(:size, option(opts, :size, :medium))
          |> maybe_put(:shape, option(opts, :shape, :round))
      },
      opts
    )
  end

  @spec presence_dot(atom(), opts()) :: Element.t()
  def presence_dot(state, opts \\ []) when is_atom(state) do
    opts = normalize_opts(opts)

    build_component(
      :presence_dot,
      :content_identity_and_disclosure,
      %{presence: %{state: state, size: option(opts, :size, :medium)}},
      opts
    )
  end

  @spec segmented_button_group([keyword() | map()], opts()) :: Element.t()
  def segmented_button_group(options, opts \\ []) when is_list(options) do
    opts = normalize_opts(opts)

    build_component(
      :segmented_button_group,
      :form_control_and_composer,
      %{
        selection:
          %{
            presentation: :segmented_button_group,
            multiple?: false,
            options: normalize_options(options)
          }
          |> maybe_put(:active_value, option(opts, :active_value))
          |> maybe_put(:selection_intent, option(opts, :selection_intent))
      },
      opts
    )
  end

  @spec runtime_form_shell([keyword() | map()], opts()) :: Element.t()
  def runtime_form_shell(fields, opts \\ []) when is_list(fields) do
    opts = normalize_opts(opts)

    build_component(
      :runtime_form_shell,
      :form_control_and_composer,
      %{
        form:
          %{
            fields: normalize_maps(fields)
          }
          |> maybe_put(:submit_label, option(opts, :submit_label))
          |> maybe_put(:submit_intent, option(opts, :submit_intent))
          |> maybe_put(:change_intent, option(opts, :change_intent))
          |> maybe_put(:validation_state, option(opts, :validation_state))
          |> maybe_put(
            :host_adapter_hints,
            normalize_optional_map(option(opts, :host_adapter_hints))
          )
      },
      opts
    )
  end

  @spec chat_composer([Element.t() | Element.Child.t() | {atom(), Element.t()} | map()], opts()) ::
          Element.t()
  def chat_composer(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :chat_composer,
      :form_control_and_composer,
      %{
        composer:
          %{}
          |> maybe_put(:name, option(opts, :name))
          |> maybe_put(:value, option(opts, :value))
          |> maybe_put(:placeholder, option(opts, :placeholder))
          |> maybe_put(:rows, option(opts, :rows, 3))
          |> maybe_put(:send_label, option(opts, :send_label, "Send"))
          |> maybe_put(:send_intent, option(opts, :send_intent))
          |> maybe_put(:change_intent, option(opts, :change_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec collection_picker(opts()) :: Element.t()
  def collection_picker(opts \\ []) do
    opts = normalize_opts(opts)

    picker_id =
      required_string!(
        opts,
        :picker_id,
        "collection_picker requires a non-empty :picker_id string"
      )

    opts = put_collection_picker_interactions(opts, picker_id)

    build_component(
      :collection_picker,
      :form_control_and_composer,
      %{
        collection_picker:
          %{
            picker_id: picker_id,
            query: option(opts, :query, ""),
            placeholder: option(opts, :placeholder, "Search collection"),
            filters: normalize_collection_filters!(option(opts, :filters, [])),
            items: normalize_collection_items!(option(opts, :items, [])),
            suggestions: normalize_collection_suggestions!(option(opts, :suggestions, [])),
            empty_label: option(opts, :empty_label, "No matching items.")
          }
          |> maybe_put(:title, option(opts, :title))
          |> maybe_put(:loading?, option(opts, :loading?))
          |> maybe_put(:density, option(opts, :density))
      },
      opts
    )
  end

  @spec list_item_multi_column(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def list_item_multi_column(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :list_item_multi_column,
      :row_and_artifact,
      %{
        row:
          common_row_attrs(opts)
          |> maybe_put(:column_template, normalize_maps(option(opts, :column_template, [])))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec artifact_row(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def artifact_row(title, children \\ [], opts \\ [])
      when is_binary(title) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :artifact_row,
      :row_and_artifact,
      %{
        artifact:
          common_row_attrs(opts)
          |> maybe_put(:title, title)
          |> maybe_put(:meta, option(opts, :meta))
          |> maybe_put(
            :kind,
            normalize_artifact_kind(option(opts, :artifact_kind, option(opts, :kind)))
          )
          |> maybe_put(
            :status_badges,
            normalize_artifact_status_badges(option(opts, :status_badges))
          )
          |> maybe_put(:counts, normalize_artifact_counts(option(opts, :counts)))
          |> maybe_put(:timestamp_at, option(opts, :timestamp_at))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec thread_card(opts()) :: Element.t()
  def thread_card(opts \\ []) do
    opts = normalize_opts(opts)

    thread_id = option(opts, :thread_id)
    title = option(opts, :title)
    seed_quote = option(opts, :seed_quote)
    reply_count = option(opts, :reply_count, 0)
    progress_pct = normalize_thread_progress!(option(opts, :progress_pct))

    unless non_empty_string?(thread_id) do
      raise ArgumentError, "thread_card requires a non-empty :thread_id string"
    end

    unless non_empty_string?(title) do
      raise ArgumentError, "thread_card requires a non-empty :title string"
    end

    unless non_empty_string?(seed_quote) do
      raise ArgumentError, "thread_card requires a non-empty :seed_quote string"
    end

    unless non_negative_integer?(reply_count) do
      raise ArgumentError, "thread_card :reply_count must be a non-negative integer"
    end

    opts = put_thread_open_interaction(opts, thread_id)

    build_component(
      :thread_card,
      :row_and_artifact,
      %{
        thread:
          %{
            thread_id: thread_id,
            title: title,
            reply_count: reply_count,
            seed_quote: seed_quote
          }
          |> maybe_put(:progress_pct, progress_pct)
          |> maybe_put(:last_activity_at, option(opts, :last_activity_at)),
        participants: normalize_thread_participants!(option(opts, :participants, []))
      },
      opts
    )
  end

  @spec pipeline_stepper_horizontal([keyword() | map()], opts()) :: Element.t()
  def pipeline_stepper_horizontal(steps, opts \\ []) when is_list(steps) do
    opts = normalize_opts(opts)

    build_component(
      :pipeline_stepper_horizontal,
      :workflow_progress_and_status,
      %{
        workflow:
          %{
            presentation: :pipeline_stepper_horizontal,
            steps: normalize_maps(steps),
            active_index: option(opts, :active_index, 0),
            completed_indices: option(opts, :completed_indices, [])
          }
          |> maybe_put(:navigation_intent, option(opts, :navigation_intent))
      },
      opts
    )
  end

  @spec segmented_progress_bar([keyword() | map()], opts()) :: Element.t()
  def segmented_progress_bar(segments, opts \\ []) when is_list(segments) do
    opts = normalize_opts(opts)

    build_component(
      :segmented_progress_bar,
      :workflow_progress_and_status,
      %{
        progress:
          %{
            presentation: :segmented_progress_bar,
            segments: normalize_maps(segments)
          }
          |> maybe_put(:aggregate, normalize_optional_map(option(opts, :aggregate_progress)))
          |> maybe_put(:label, option(opts, :label))
      },
      opts
    )
  end

  @spec workflow_stage_list_vertical([keyword() | map()], opts()) :: Element.t()
  def workflow_stage_list_vertical(stages, opts \\ []) when is_list(stages) do
    opts = normalize_opts(opts)

    build_component(
      :workflow_stage_list_vertical,
      :workflow_progress_and_status,
      %{
        workflow: %{
          presentation: :workflow_stage_list_vertical,
          stages: normalize_maps(stages),
          active_index: option(opts, :active_index, 0)
        }
      },
      opts
    )
  end

  @spec meter_thin(number(), opts()) :: Element.t()
  def meter_thin(current, opts \\ []) when is_number(current) do
    opts = normalize_opts(opts)

    build_component(
      :meter_thin,
      :workflow_progress_and_status,
      %{
        meter:
          %{
            current: current,
            minimum: option(opts, :minimum, 0),
            maximum: option(opts, :maximum, 100)
          }
          |> maybe_put(:label, option(opts, :label))
          |> maybe_put(:state, option(opts, :state))
      },
      opts
    )
  end

  @spec sticky_frosted_header(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def sticky_frosted_header(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :sticky_frosted_header,
      :layer_shell_and_callout,
      %{
        shell:
          %{
            position: :sticky,
            visual_effect: :frosted
          }
          |> maybe_put(:title, option(opts, :title))
          |> maybe_put(:leading, option(opts, :leading, []))
          |> maybe_put(:trailing, option(opts, :trailing, []))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec slide_over_panel(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def slide_over_panel(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :slide_over_panel,
      :layer_shell_and_callout,
      %{
        panel:
          %{
            modal?: false,
            open?: option(opts, :open?, false),
            size: option(opts, :size, :medium)
          }
          |> maybe_put(:label, option(opts, :label, option(opts, :accessibility_label)))
          |> maybe_put(:dismiss_intent, option(opts, :dismiss_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec event_callout(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def event_callout(message, children \\ [], opts \\ [])
      when is_binary(message) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :event_callout,
      :layer_shell_and_callout,
      %{
        callout:
          %{
            message: message,
            tone: option(opts, :tone, :info)
          }
          |> maybe_put(:eyebrow, option(opts, :eyebrow))
          |> maybe_put(:title, option(opts, :title))
          |> maybe_put(:action_intent, option(opts, :action_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec redline_inline([keyword() | map()], opts()) :: Element.t()
  def redline_inline(segments, opts \\ []) when is_list(segments) do
    opts = normalize_opts(opts)

    build_component(
      :redline_inline,
      :redline_and_code,
      %{
        redline: %{segments: normalize_maps(segments)},
        text_safety: %{content: option(opts, :text_safety, :plain_text)}
      },
      opts
    )
  end

  @spec code_block_syntax_highlighted(atom() | String.t(), [keyword() | map()], opts()) ::
          Element.t()
  def code_block_syntax_highlighted(language, tokens, opts \\ [])
      when (is_atom(language) or is_binary(language)) and is_list(tokens) do
    opts = normalize_opts(opts)

    build_component(
      :code_block_syntax_highlighted,
      :redline_and_code,
      %{
        code: %{language: language, tokens: normalize_maps(tokens)},
        text_safety: %{content: option(opts, :text_safety, :plain_text)}
      },
      opts
    )
  end

  @spec list_repeat(Element.t() | nil, opts()) :: Element.t()
  def list_repeat(template, opts \\ []) do
    opts = normalize_opts(opts)

    children =
      option(
        opts,
        :children,
        if(template, do: [Element.Child.new(:template, template)], else: [])
      )

    build_component(
      :list_repeat,
      :composition_behavior,
      %{
        repeat:
          %{
            binding_id: option(opts, :repeat_binding),
            row_scope: option(opts, :row_scope, :row),
            row_fields: option(opts, :row_fields, []),
            identity_strategy: option(opts, :identity_strategy, :row_identity),
            child_slot: option(opts, :child_slot, :default),
            hydrated?: option(opts, :hydrated?, false),
            row_count: option(opts, :row_count, 0)
          }
          |> maybe_put(:binding_ref, normalize_optional_map(option(opts, :binding_ref)))
          |> maybe_put(:template_identity, option(opts, :template_identity))
          |> maybe_put(:template, normalize_optional_map(option(opts, :template)))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec top_strip(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) :: Element.t()
  def top_strip(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :top_strip,
      :layer_shell_and_callout,
      %{
        shell: %{
          position: :top,
          brand: option(opts, :brand, ""),
          context: option(opts, :context, ""),
          theme: option(opts, :theme, :light),
          pane_open?: option(opts, :pane_open?, false)
        }
      },
      Map.put(opts, :children, children)
    )
  end

  @spec mode_nav([keyword() | map()], opts()) :: Element.t()
  def mode_nav(items, opts \\ []) when is_list(items) do
    opts = normalize_opts(opts)

    build_component(
      :mode_nav,
      :form_control_and_composer,
      %{
        navigation:
          %{
            items: normalize_maps(items)
          }
          |> maybe_put(:aria_label, option(opts, :aria_label))
          |> maybe_put(:navigation_intent, option(opts, :navigation_intent))
          |> maybe_put(:navigation_value_key, option(opts, :navigation_value_key))
      },
      opts
    )
  end

  @spec sidebar_shell(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) :: Element.t()
  def sidebar_shell(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :sidebar_shell,
      :layer_shell_and_callout,
      %{
        shell: %{
          position: :side,
          collapsed?: option(opts, :collapsed?, false)
        }
      },
      Map.put(opts, :children, children)
    )
  end

  @spec sidebar_section(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) :: Element.t()
  def sidebar_section(label, children \\ [], opts \\ [])
      when is_binary(label) and is_list(children) do
    opts = normalize_opts(opts)
    opts = put_sidebar_section_interactions(opts, label)

    build_component(
      :sidebar_section,
      :layer_shell_and_callout,
      %{
        section:
          %{
            label: label,
            collapsible?: option(opts, :collapsible?, false),
            expanded?: option(opts, :expanded?, true)
          }
          |> maybe_put(:action_glyph, option(opts, :action_glyph))
          |> maybe_put(:action_label, option(opts, :action_label))
          |> maybe_put(:action_intent, option(opts, :action_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec sidebar_item(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) :: Element.t()
  def sidebar_item(label, children \\ [], opts \\ [])
      when is_binary(label) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :sidebar_item,
      :layer_shell_and_callout,
      %{
        item:
          %{
            label: label,
            selected?: option(opts, :selected?, false)
          }
          |> maybe_put(:item_intent, option(opts, :item_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec right_rail(opts()) :: Element.t()
  def right_rail(opts \\ []) do
    opts = normalize_opts(opts)

    build_component(
      :right_rail,
      :layer_shell_and_callout,
      %{
        rail:
          %{
            id: option(opts, :rail_id, option(opts, :id)),
            side: option(opts, :side, :right),
            panels: normalize_maps(option(opts, :panels, [])),
            active_panel: option(opts, :active_panel),
            collapsed?: option(opts, :collapsed?, false),
            collapsible?: option(opts, :collapsible?, true)
          }
          |> maybe_put(:density, option(opts, :density))
          |> maybe_put(:width, option(opts, :width))
      },
      opts
    )
  end

  @spec unread_badge(non_neg_integer(), opts()) :: Element.t()
  def unread_badge(count, opts \\ []) when is_integer(count) and count >= 0 do
    opts = normalize_opts(opts)

    build_component(
      :unread_badge,
      :workflow_progress_and_status,
      %{
        status: %{
          count: count,
          threshold: option(opts, :threshold, 99)
        }
      },
      opts
    )
  end

  @spec workflow_progress_status_card(opts()) :: Element.t()
  def workflow_progress_status_card(opts \\ []) do
    opts = normalize_opts(opts)

    name = option(opts, :name)

    unless is_binary(name) and byte_size(name) > 0 do
      raise ArgumentError, "workflow_progress_status_card requires a non-empty :name string"
    end

    subject_id = option(opts, :subject_id, name)

    unless is_binary(subject_id) and byte_size(subject_id) > 0 do
      raise ArgumentError, "workflow_progress_status_card requires a non-empty :subject_id string"
    end

    progress = normalize_subject_progress!(opts)
    status_counts = normalize_subject_status_counts!(opts)
    dependencies = normalize_subject_dependencies!(opts)
    activity = normalize_subject_activity(opts)
    actions = normalize_subject_actions!(opts)
    interactions = normalize_subject_interactions!(opts, subject_id)
    state = normalize_subject_state!(opts)

    subject =
      %{
        id: subject_id,
        name: name,
        progress: progress,
        status_counts: status_counts,
        dependencies: dependencies
      }
      |> maybe_put(:path, option(opts, :path))
      |> maybe_put(:activity, activity)
      |> maybe_put(:state, state)
      |> maybe_put(:actions, empty_map_to_nil(actions))
      |> maybe_put(:interactions, empty_map_to_nil(interactions))

    build_component(
      :workflow_progress_status_card,
      :workflow_progress_and_status,
      %{subject: subject},
      opts
    )
  end

  defp normalize_subject_progress!(opts) do
    progress = option(opts, :progress)

    progress =
      if is_nil(progress) do
        progress_pct = option(opts, :progress_pct, 0.0)

        unless is_float(progress_pct) or is_integer(progress_pct) do
          raise ArgumentError, "workflow_progress_status_card :progress_pct must be a number"
        end

        unless progress_pct >= 0.0 and progress_pct <= 1.0 do
          raise ArgumentError, "workflow_progress_status_card :progress_pct must be in 0.0..1.0"
        end

        progress_pct * 100.0
      else
        progress
      end

    unless is_float(progress) or is_integer(progress) do
      raise ArgumentError, "workflow_progress_status_card :progress must be a number"
    end

    unless progress >= 0.0 and progress <= 100.0 do
      raise ArgumentError, "workflow_progress_status_card :progress must be in 0.0..100.0"
    end

    progress / 1.0
  end

  defp normalize_subject_status_counts!(opts) do
    counts = opts |> option(:status_counts, %{}) |> normalize_map()

    active_count = option(opts, :active_count, option(counts, :active, 0))
    blocked_count = option(opts, :blocked_count, option(counts, :blocked, 0))
    done_count = option(opts, :done_count, option(counts, :done))
    failed_count = option(opts, :failed_count, option(counts, :failed))
    custom_counts = option(opts, :custom_counts, option(counts, :custom))

    unless non_negative_integer?(active_count) do
      raise ArgumentError,
            "workflow_progress_status_card :active_count must be a non-negative integer"
    end

    unless non_negative_integer?(blocked_count) do
      raise ArgumentError,
            "workflow_progress_status_card :blocked_count must be a non-negative integer"
    end

    if not is_nil(done_count) and not non_negative_integer?(done_count) do
      raise ArgumentError,
            "workflow_progress_status_card :done_count must be a non-negative integer"
    end

    if not is_nil(failed_count) and not non_negative_integer?(failed_count) do
      raise ArgumentError,
            "workflow_progress_status_card :failed_count must be a non-negative integer"
    end

    %{
      active: active_count,
      blocked: blocked_count
    }
    |> maybe_put(:done, done_count)
    |> maybe_put(:failed, failed_count)
    |> maybe_put(:custom, normalize_subject_custom_counts!(custom_counts))
  end

  defp normalize_subject_custom_counts!(nil), do: nil

  defp normalize_subject_custom_counts!(counts) when is_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> normalize_subject_custom_count!({key, value}) end)
  end

  defp normalize_subject_custom_counts!(counts) when is_list(counts) do
    Enum.map(counts, &normalize_subject_custom_count!/1)
  end

  defp normalize_subject_custom_counts!(_counts) do
    raise ArgumentError, "workflow_progress_status_card :custom_counts must be a map or list"
  end

  defp normalize_subject_custom_count!({key, value}) do
    normalize_subject_custom_count!(%{key: key, value: value})
  end

  defp normalize_subject_custom_count!(count) when is_map(count) or is_list(count) do
    count = normalize_map(count)
    key = option(count, :key)
    value = option(count, :value)

    unless not is_nil(key) and non_negative_integer?(value) do
      raise ArgumentError,
            "workflow_progress_status_card custom counts require :key and non-negative :value"
    end

    %{
      key: key,
      value: value
    }
    |> maybe_put(:label, option(count, :label))
  end

  defp normalize_subject_custom_count!(_count) do
    raise ArgumentError, "workflow_progress_status_card custom counts must be maps"
  end

  defp normalize_subject_activity(opts) do
    activity = opts |> option(:activity, %{}) |> normalize_map()

    activity
    |> maybe_put(:last_activity_at, option(opts, :last_activity_at))
    |> empty_map_to_nil()
  end

  defp normalize_subject_dependencies!(opts) do
    %{
      depends_on:
        opts
        |> option(:depends_on, [])
        |> normalize_subject_dependency_edges!(:depends_on),
      depended_by:
        opts
        |> option(:depended_by, [])
        |> normalize_subject_dependency_edges!(:depended_by)
    }
  end

  defp normalize_subject_dependency_edges!(edges, direction) when is_list(edges) do
    Enum.map(edges, &normalize_subject_dependency_edge!(&1, direction))
  end

  defp normalize_subject_dependency_edges!(_edges, direction) do
    raise ArgumentError,
          "workflow_progress_status_card :#{direction} must be a list of dependency edges"
  end

  defp normalize_subject_dependency_edge!(edge, direction) when is_binary(edge) do
    %{id: edge, label: edge, direction: direction}
  end

  defp normalize_subject_dependency_edge!(edge, direction) when is_map(edge) or is_list(edge) do
    edge = normalize_map(edge)
    id = option(edge, :id)

    unless is_binary(id) and byte_size(id) > 0 do
      raise ArgumentError,
            "workflow_progress_status_card dependency edges require a non-empty :id string"
    end

    %{
      id: id,
      label: option(edge, :label, id),
      direction: option(edge, :direction, direction)
    }
    |> maybe_put(:state, option(edge, :state))
    |> maybe_put(:metadata, edge |> option(:metadata) |> normalize_optional_map())
    |> maybe_put(:interaction, normalize_subject_interaction(option(edge, :interaction)))
  end

  defp normalize_subject_dependency_edge!(_edge, direction) do
    raise ArgumentError,
          "workflow_progress_status_card :#{direction} must be a list of strings or maps"
  end

  defp normalize_subject_actions!(opts) do
    %{}
    |> maybe_put(:open, opts |> option(:open_action) |> normalize_subject_open_action!())
  end

  defp normalize_subject_open_action!(nil), do: nil

  defp normalize_subject_open_action!(action) when is_map(action) or is_list(action) do
    action = normalize_map(action)
    label = option(action, :label)
    intent = option(action, :intent)

    unless is_binary(label) and byte_size(label) > 0 and not is_nil(intent) do
      raise ArgumentError,
            "workflow_progress_status_card :open_action must have :label and :intent keys"
    end

    %{
      label: label,
      intent: intent
    }
    |> maybe_put(:visible_when, option(action, :visible_when))
    |> maybe_put(:metadata, action |> option(:metadata) |> normalize_optional_map())
    |> maybe_put(:interaction, action |> option(:interaction) |> normalize_subject_interaction())
  end

  defp normalize_subject_open_action!(_action) do
    raise ArgumentError, "workflow_progress_status_card :open_action must be a map"
  end

  defp normalize_subject_interactions!(opts, subject_id) do
    focus_interaction =
      case option(opts, :focus_interaction) do
        nil ->
          case option(opts, :focus_intent, "focus_subject") do
            nil -> nil
            intent -> Interaction.focus(intent: intent, entity: subject_id)
          end

        interaction ->
          normalize_subject_interaction(interaction)
      end

    dependency_select_interaction =
      case option(opts, :dependency_select_interaction) do
        nil ->
          case option(opts, :dependency_select_intent) do
            nil -> nil
            intent -> Interaction.selection(intent: intent, entity: subject_id)
          end

        interaction ->
          normalize_subject_interaction(interaction)
      end

    %{}
    |> maybe_put(:focus, focus_interaction)
    |> maybe_put(:dependency_select, dependency_select_interaction)
  end

  defp normalize_subject_interaction(nil), do: nil

  defp normalize_subject_interaction(%Interaction{} = interaction),
    do: Interaction.new(interaction)

  defp normalize_subject_interaction(interaction)
       when is_map(interaction) or is_list(interaction),
       do: Interaction.new(interaction)

  defp normalize_subject_interaction(_interaction) do
    raise ArgumentError,
          "workflow_progress_status_card interactions must be canonical interaction maps"
  end

  defp normalize_subject_state!(opts) do
    selected? = option(opts, :selected?, false)

    unless is_boolean(selected?) do
      raise ArgumentError, "workflow_progress_status_card :selected? must be boolean"
    end

    %{selected?: selected?}
  end

  @spec command_palette(
          [keyword() | map()],
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) :: Element.t()
  def command_palette(items \\ [], children \\ [], opts \\ [])
      when is_list(items) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :command_palette,
      :layer_shell_and_callout,
      %{
        palette:
          %{
            open?: option(opts, :open?, false),
            items: normalize_maps(items)
          }
          |> maybe_put(:filter_intent, option(opts, :filter_intent))
          |> maybe_put(:select_intent, option(opts, :select_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec composer_query_preview(opts()) :: Element.t()
  def composer_query_preview(opts \\ []) do
    opts = normalize_opts(opts)

    composer_id =
      required_string!(
        opts,
        :composer_id,
        "composer_query_preview requires a non-empty :composer_id string"
      )

    query =
      required_string!(
        opts,
        :query,
        "composer_query_preview requires a non-empty :query string"
      )

    preview_state = normalize_query_preview_state!(option(opts, :preview_state, :empty))
    max_findings_shown = option(opts, :max_findings_shown, 2)
    validate_positive_integer!(max_findings_shown, "max_findings_shown")

    explanation = option(opts, :explanation)
    metrics = normalize_query_preview_metrics!(option(opts, :metrics))
    findings = normalize_query_preview_findings!(option(opts, :findings, []))

    if preview_state == :ready and not non_empty_string?(explanation) do
      raise ArgumentError,
            "composer_query_preview requires a non-empty :explanation string when preview_state is :ready"
    end

    opts = put_query_preview_interactions(opts, composer_id, query)

    build_component(
      :composer_query_preview,
      :layer_shell_and_callout,
      %{
        query_preview:
          %{
            composer_id: composer_id,
            query: query,
            preview_state: preview_state,
            max_findings_shown: max_findings_shown,
            findings: findings
          }
          |> maybe_put(:explanation, explanation)
          |> maybe_put(:metrics, metrics)
          |> maybe_put(:error_message, option(opts, :error_message))
          |> maybe_put(:loading_label, option(opts, :loading_label, "Searching"))
          |> maybe_put(:empty_label, option(opts, :empty_label, "No results for this query."))
          |> maybe_put(:open_label, option(opts, :open_label, "Open query"))
          |> maybe_put(:save_label, option(opts, :save_label, "Save query"))
      },
      opts
    )
  end

  defp build_component(kind, family, kind_attributes, opts) do
    opts = normalize_opts(opts)

    Element.new(:widget, kind,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{
          component: %{
            family: family,
            kind: kind
          }
        }
        |> merge_attributes(kind_attributes)
        |> merge_attribute(:accessibility, normalize_accessibility(opts))
        |> merge_attribute(:state, normalize_state(opts))
        |> Attachment.merge(opts,
          component: kind,
          tone: option(opts, :tone),
          local_style: option(opts, :style)
        ),
      children: option(opts, :children, [])
    )
  end

  defp common_row_attrs(opts) do
    %{}
    |> maybe_put(:row_identity, option(opts, :row_identity))
    |> maybe_put(:active?, option(opts, :active?))
    |> maybe_put(:link_target, option(opts, :link_target))
    |> maybe_put(:action_intent, option(opts, :action_intent))
  end

  defp normalize_artifact_kind(nil), do: :generic
  defp normalize_artifact_kind(kind) when kind in @artifact_kinds, do: kind

  defp normalize_artifact_kind(kind) when is_binary(kind) do
    kind
    |> String.to_existing_atom()
    |> normalize_artifact_kind()
  rescue
    ArgumentError -> :generic
  end

  defp normalize_artifact_kind(_other), do: :generic

  defp normalize_artifact_status_badges(nil), do: nil

  defp normalize_artifact_status_badges(badges) when is_list(badges) do
    badges
    |> Enum.map(&normalize_artifact_status_badge/1)
    |> Enum.reject(&(&1 == %{}))
    |> empty_to_nil()
  end

  defp normalize_artifact_status_badges(_other), do: nil

  defp normalize_artifact_status_badge(badge) when is_map(badge) or is_list(badge) do
    badge = normalize_map(badge)

    %{}
    |> maybe_put(:label, option(badge, :label))
    |> maybe_put(:tone, option(badge, :tone))
  end

  defp normalize_artifact_status_badge(_other), do: %{}

  defp normalize_artifact_counts(nil), do: nil

  defp normalize_artifact_counts(counts) when is_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> %{key: key, value: value} end)
    |> empty_to_nil()
  end

  defp normalize_artifact_counts(counts) when is_list(counts) do
    counts
    |> Enum.map(&normalize_artifact_count/1)
    |> Enum.reject(&(&1 == %{}))
    |> empty_to_nil()
  end

  defp normalize_artifact_counts(_other), do: nil

  defp normalize_artifact_count({key, value}), do: %{key: key, value: value}

  defp normalize_artifact_count(count) when is_map(count) or is_list(count) do
    count = normalize_map(count)

    %{}
    |> maybe_put(:key, option(count, :key))
    |> maybe_put(:value, option(count, :value))
    |> maybe_put(:label, option(count, :label))
  end

  defp normalize_artifact_count(_other), do: %{}

  defp put_sidebar_section_interactions(opts, label) do
    cond do
      not option(opts, :collapsible?, false) ->
        opts

      explicit_interactions?(opts) ->
        opts

      true ->
        Map.put(opts, :interactions, [sidebar_section_toggle_interaction(opts, label)])
    end
  end

  defp sidebar_section_toggle_interaction(opts, label) do
    Interaction.change(
      intent:
        option(opts, :toggle_intent, option(opts, :collapse_intent, :toggle_sidebar_section)),
      element_id: option(opts, :id),
      entity: option(opts, :section_id, option(opts, :id, label)),
      mapping: %{expanded?: :expanded}
    )
  end

  defp explicit_interactions?(opts) do
    Map.has_key?(opts, :interactions) or Map.has_key?(opts, "interactions") or
      Map.has_key?(opts, :interaction) or Map.has_key?(opts, "interaction")
  end

  defp put_thread_open_interaction(opts, thread_id) do
    cond do
      Map.has_key?(opts, :interactions) or Map.has_key?(opts, "interactions") or
        Map.has_key?(opts, :interaction) or Map.has_key?(opts, "interaction") ->
        opts

      true ->
        Map.put(opts, :interactions, [thread_open_interaction(opts, thread_id)])
    end
  end

  defp thread_open_interaction(opts, thread_id) do
    case option(opts, :open_interaction) do
      nil ->
        Interaction.open(
          intent: option(opts, :open_intent, :open_thread),
          element_id: option(opts, :id),
          entity: thread_id,
          value: thread_id
        )

      interaction ->
        Interaction.new(interaction)
    end
  end

  defp put_query_preview_interactions(opts, composer_id, query) do
    cond do
      Map.has_key?(opts, :interactions) or Map.has_key?(opts, "interactions") or
        Map.has_key?(opts, :interaction) or Map.has_key?(opts, "interaction") ->
        opts

      true ->
        Map.put(opts, :interactions, query_preview_interactions(opts, composer_id, query))
    end
  end

  defp query_preview_interactions(opts, composer_id, query) do
    [
      Interaction.close(
        intent: option(opts, :dismiss_intent, :dismiss_query_preview),
        element_id: option(opts, :id),
        entity: composer_id,
        value: query
      ),
      Interaction.open(
        intent: option(opts, :open_intent, :open_query_preview),
        element_id: option(opts, :id),
        entity: composer_id,
        value: query
      ),
      Interaction.command(
        intent: option(opts, :save_intent, :save_query),
        element_id: option(opts, :id),
        entity: composer_id,
        command: :save_query,
        value: query
      )
    ]
  end

  defp put_collection_picker_interactions(opts, picker_id) do
    cond do
      Map.has_key?(opts, :interactions) or Map.has_key?(opts, "interactions") or
        Map.has_key?(opts, :interaction) or Map.has_key?(opts, "interaction") ->
        opts

      true ->
        Map.put(opts, :interactions, collection_picker_interactions(opts, picker_id))
    end
  end

  defp collection_picker_interactions(opts, picker_id) do
    [
      Interaction.change(
        intent: option(opts, :change_intent, :change_collection_query),
        element_id: option(opts, :id),
        entity: picker_id,
        mapping: %{query: :value}
      ),
      Interaction.selection(
        intent: option(opts, :selection_intent, :select_collection_item),
        element_id: option(opts, :id),
        entity: picker_id,
        mapping: %{item_id: :item_id, selected_value: :item_id}
      ),
      Interaction.command(
        intent: option(opts, :filter_toggle_intent, :toggle_collection_filter),
        element_id: option(opts, :id),
        entity: picker_id,
        command: :toggle_filter,
        mapping: %{filter_id: :filter_id}
      ),
      Interaction.command(
        intent: option(opts, :suggestion_accept_intent, :accept_collection_suggestion),
        element_id: option(opts, :id),
        entity: picker_id,
        command: :accept_suggestion,
        mapping: %{suggestion_id: :suggestion_id}
      ),
      Interaction.command(
        intent: option(opts, :suggestion_dismiss_intent, :dismiss_collection_suggestion),
        element_id: option(opts, :id),
        entity: picker_id,
        command: :dismiss_suggestion,
        mapping: %{suggestion_id: :suggestion_id}
      )
    ]
  end

  defp normalize_collection_filters!(nil), do: []

  defp normalize_collection_filters!(filters) when is_list(filters) do
    Enum.map(filters, &normalize_collection_filter!/1)
  end

  defp normalize_collection_filters!(_filters) do
    raise ArgumentError, "collection_picker :filters must be a list of maps"
  end

  defp normalize_collection_filter!(filter) when is_map(filter) or is_list(filter) do
    filter = normalize_map(filter)
    id = normalize_required_collection_id!(filter, :id, "filter")
    label = normalize_required_collection_label!(filter, id, "filter")
    count = option(filter, :count)

    if not is_nil(count) and not non_negative_integer?(count) do
      raise ArgumentError, "collection_picker filter :count must be a non-negative integer"
    end

    %{
      id: id,
      label: label
    }
    |> maybe_put(:selected?, option(filter, :selected?))
    |> maybe_put(:count, count)
    |> maybe_put(:disabled?, option(filter, :disabled?))
  end

  defp normalize_collection_filter!(_filter) do
    raise ArgumentError, "collection_picker filters must be maps"
  end

  defp normalize_collection_items!(nil), do: []

  defp normalize_collection_items!(items) when is_list(items) do
    Enum.map(items, &normalize_collection_item!/1)
  end

  defp normalize_collection_items!(_items) do
    raise ArgumentError, "collection_picker :items must be a list of maps"
  end

  defp normalize_collection_item!(item) when is_map(item) or is_list(item) do
    item = normalize_map(item)
    id = normalize_required_collection_id!(item, :id, "item")
    label = normalize_required_collection_label!(item, id, "item")

    %{
      id: id,
      label: label
    }
    |> maybe_put(:description, option(item, :description))
    |> maybe_put(:meta, normalize_optional_map(option(item, :meta)))
    |> maybe_put(:selected?, option(item, :selected?))
    |> maybe_put(:disabled?, option(item, :disabled?))
    |> maybe_put(:draggable?, option(item, :draggable?))
  end

  defp normalize_collection_item!(_item) do
    raise ArgumentError, "collection_picker items must be maps"
  end

  defp normalize_collection_suggestions!(nil), do: []

  defp normalize_collection_suggestions!(suggestions) when is_list(suggestions) do
    Enum.map(suggestions, &normalize_collection_suggestion!/1)
  end

  defp normalize_collection_suggestions!(_suggestions) do
    raise ArgumentError, "collection_picker :suggestions must be a list of maps"
  end

  defp normalize_collection_suggestion!(suggestion)
       when is_map(suggestion) or is_list(suggestion) do
    suggestion = normalize_map(suggestion)
    id = normalize_required_collection_id!(suggestion, :id, "suggestion")
    label = normalize_required_collection_label!(suggestion, id, "suggestion")
    confidence = option(suggestion, :confidence)

    if not is_nil(confidence) and not normalized_confidence?(confidence) do
      raise ArgumentError, "collection_picker suggestion :confidence must be in 0.0..1.0"
    end

    %{
      id: id,
      label: label
    }
    |> maybe_put(:description, option(suggestion, :description))
    |> maybe_put(:source, option(suggestion, :source))
    |> maybe_put(:confidence, if(is_nil(confidence), do: nil, else: confidence / 1))
    |> maybe_put(:disabled?, option(suggestion, :disabled?))
  end

  defp normalize_collection_suggestion!(_suggestion) do
    raise ArgumentError, "collection_picker suggestions must be maps"
  end

  defp normalize_required_collection_id!(map, key, label) do
    case option(map, key) do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
      value when is_integer(value) -> Integer.to_string(value)
      _other -> raise ArgumentError, "collection_picker #{label} requires a non-empty :id"
    end
  end

  defp normalize_required_collection_label!(map, fallback, label) do
    case option(map, :label, fallback) do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
      value when is_integer(value) -> Integer.to_string(value)
      _other -> raise ArgumentError, "collection_picker #{label} requires a non-empty :label"
    end
  end

  defp normalize_thread_participants!(nil), do: []

  defp normalize_thread_participants!(participants) when is_list(participants) do
    Enum.map(participants, &normalize_thread_participant!/1)
  end

  defp normalize_thread_participants!(_other) do
    raise ArgumentError, "thread_card :participants must be a list of maps"
  end

  defp normalize_thread_participant!(participant)
       when is_map(participant) or is_list(participant) do
    participant = normalize_map(participant)
    avatar = participant |> option(:avatar) |> normalize_optional_map()

    %{}
    |> maybe_put(:actor_id, option(participant, :actor_id))
    |> maybe_put(:actor_name, option(participant, :actor_name))
    |> maybe_put(:avatar, empty_map_to_nil(avatar))
  end

  defp normalize_thread_participant!(_other) do
    raise ArgumentError, "thread_card participants must be maps"
  end

  defp normalize_thread_progress!(nil), do: nil

  defp normalize_thread_progress!(progress_pct)
       when is_float(progress_pct) or is_integer(progress_pct) do
    unless progress_pct >= 0.0 and progress_pct <= 1.0 do
      raise ArgumentError, "thread_card :progress_pct must be in 0.0..1.0"
    end

    progress_pct / 1
  end

  defp normalize_thread_progress!(_other) do
    raise ArgumentError, "thread_card :progress_pct must be a number"
  end

  defp normalize_query_preview_state!(state) when state in @query_preview_states, do: state

  defp normalize_query_preview_state!(state) when is_binary(state) do
    state
    |> String.to_existing_atom()
    |> normalize_query_preview_state!()
  rescue
    ArgumentError ->
      raise ArgumentError,
            "composer_query_preview :preview_state must be one of #{inspect(@query_preview_states)}"
  end

  defp normalize_query_preview_state!(_state) do
    raise ArgumentError,
          "composer_query_preview :preview_state must be one of #{inspect(@query_preview_states)}"
  end

  defp normalize_query_preview_metrics!(nil), do: nil

  defp normalize_query_preview_metrics!(metrics) when is_map(metrics) or is_list(metrics) do
    metrics = normalize_map(metrics)
    results_count = option(metrics, :results_count, option(metrics, :findings_count))
    duration_ms = option(metrics, :duration_ms)
    sources_visited = option(metrics, :sources_visited, option(metrics, :grains_visited))

    %{}
    |> maybe_put(:results_count, normalize_non_negative_integer!(results_count, "results_count"))
    |> maybe_put(:duration_ms, normalize_non_negative_integer!(duration_ms, "duration_ms"))
    |> maybe_put(
      :sources_visited,
      normalize_non_negative_integer!(sources_visited, "sources_visited")
    )
    |> empty_map_to_nil()
  end

  defp normalize_query_preview_metrics!(_metrics) do
    raise ArgumentError, "composer_query_preview :metrics must be a map"
  end

  defp normalize_query_preview_findings!(findings) when is_list(findings) do
    Enum.map(findings, &normalize_query_preview_finding!/1)
  end

  defp normalize_query_preview_findings!(_findings) do
    raise ArgumentError, "composer_query_preview :findings must be a list of maps"
  end

  defp normalize_query_preview_finding!(finding) when is_map(finding) or is_list(finding) do
    finding = normalize_map(finding)
    id = option(finding, :id, option(finding, :finding_id))
    n = option(finding, :n)
    snippet = option(finding, :snippet)
    confidence = option(finding, :confidence)

    unless non_empty_string?(id) do
      raise ArgumentError, "composer_query_preview findings require a non-empty :id string"
    end

    unless positive_integer?(n) do
      raise ArgumentError, "composer_query_preview findings require positive integer :n values"
    end

    unless non_empty_string?(snippet) do
      raise ArgumentError, "composer_query_preview findings require non-empty :snippet strings"
    end

    unless normalized_confidence?(confidence) do
      raise ArgumentError, "composer_query_preview finding :confidence must be in 0.0..1.0"
    end

    %{
      id: id,
      n: n,
      snippet: snippet,
      confidence: confidence / 1
    }
  end

  defp normalize_query_preview_finding!(_finding) do
    raise ArgumentError, "composer_query_preview findings must be maps"
  end

  defp required_string!(opts, key, message) do
    case option(opts, key) do
      value when is_binary(value) and value != "" -> value
      _other -> raise ArgumentError, message
    end
  end

  defp validate_positive_integer!(value, field) do
    unless positive_integer?(value) do
      raise ArgumentError, "composer_query_preview :#{field} must be a positive integer"
    end
  end

  defp normalize_non_negative_integer!(nil, _field), do: nil

  defp normalize_non_negative_integer!(value, _field) when is_integer(value) and value >= 0 do
    value
  end

  defp normalize_non_negative_integer!(_value, field) do
    raise ArgumentError, "composer_query_preview metrics.#{field} must be a non-negative integer"
  end

  defp empty_to_nil([]), do: nil
  defp empty_to_nil(value), do: value

  defp empty_map_to_nil(%{} = value) when map_size(value) == 0, do: nil
  defp empty_map_to_nil(value), do: value

  defp non_empty_string?(value), do: is_binary(value) and byte_size(value) > 0
  defp non_negative_integer?(value), do: is_integer(value) and value >= 0
  defp positive_integer?(value), do: is_integer(value) and value > 0

  defp normalized_confidence?(value) when is_integer(value) or is_float(value) do
    value >= 0.0 and value <= 1.0
  end

  defp normalized_confidence?(_value), do: false

  defp normalize_metadata(opts) do
    opts
    |> option(:metadata)
    |> Metadata.merge(%{
      authored_ref: option(opts, :authored_ref),
      description: option(opts, :description),
      annotations: option(opts, :annotations, %{}),
      tags: option(opts, :tags, []),
      extra: option(opts, :extra, %{})
    })
  end

  defp normalize_accessibility(opts) do
    opts
    |> option(:accessibility, %{})
    |> normalize_map()
    |> maybe_put(:label, option(opts, :accessibility_label))
    |> maybe_put(:description, option(opts, :accessibility_description))
    |> maybe_put(:decorative?, option(opts, :decorative?))
  end

  defp normalize_state(opts) do
    opts
    |> option(:state, %{})
    |> normalize_state_map()
    |> maybe_put(:disabled?, option(opts, :disabled?))
    |> maybe_put(:active?, option(opts, :active?))
    |> maybe_put(:open?, option(opts, :open?))
  end

  defp normalize_state_map(value) when is_map(value) or is_list(value), do: normalize_map(value)
  defp normalize_state_map(_value), do: %{}

  defp normalize_options(options) do
    Enum.map(options, fn option_value ->
      option_value = normalize_opts(option_value)

      %{}
      |> maybe_put(:value, option(option_value, :value))
      |> maybe_put(:label, option(option_value, :label))
      |> maybe_put(:disabled?, option(option_value, :disabled?))
    end)
  end

  defp normalize_maps(values) when is_list(values) do
    Enum.map(values, &normalize_map/1)
  end

  defp normalize_maps(_values), do: []

  defp normalize_optional_map(nil), do: nil
  defp normalize_optional_map(value), do: normalize_map(value)

  defp normalize_map(nil), do: %{}
  defp normalize_map(value) when is_map(value), do: Map.new(value)
  defp normalize_map(value) when is_list(value), do: Enum.into(value, %{})

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp merge_attributes(attributes, values) do
    Enum.reduce(values, attributes, fn {key, value}, acc -> merge_attribute(acc, key, value) end)
  end

  defp merge_attribute(attributes, _key, value) when value in [%{}, [], nil], do: attributes
  defp merge_attribute(attributes, key, value), do: Map.put(attributes, key, value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
