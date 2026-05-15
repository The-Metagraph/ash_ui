defmodule UnifiedIUR.Widgets.Components do
  @moduledoc """
  Canonical constructors for the expanded widget-component catalog.

  These constructors preserve the portable content, state, accessibility, and
  safety shape for the AshUi PR 79-98 equivalents without embedding any runtime
  package implementation model.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
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
    :presence_dot,
    :unread_badge
  ]

  @form_control_kinds [
    :segmented_button_group,
    :runtime_form_shell,
    :chat_composer
  ]

  @row_artifact_kinds [
    :list_item_multi_column,
    :artifact_row,
    :sidebar_item
  ]

  @workflow_kinds [
    :pipeline_stepper_horizontal,
    :segmented_progress_bar,
    :workflow_stage_list_vertical,
    :meter_thin
  ]

  @layer_callout_kinds [
    :sidebar_shell,
    :sidebar_section,
    :sticky_frosted_header,
    :slide_over_panel,
    :event_callout
  ]

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

  @spec unread_badge(integer(), opts()) :: Element.t()
  def unread_badge(count, opts \\ []) when is_integer(count) do
    opts = normalize_opts(opts)

    build_component(
      :unread_badge,
      :content_identity_and_disclosure,
      %{badge: %{count: count, tone: option(opts, :tone, :default)}},
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
      },
      Map.put(opts, :children, children)
    )
  end

  @spec sidebar_item(String.t(), opts()) :: Element.t()
  def sidebar_item(label, opts \\ []) when is_binary(label) do
    opts = normalize_opts(opts)

    build_component(
      :sidebar_item,
      :row_and_artifact,
      %{
        sidebar_item:
          %{
            label: label,
            state: option(opts, :state, :default),
            item_kind: option(opts, :item_kind, :channel)
          }
          |> maybe_put(:glyph, option(opts, :glyph))
          |> maybe_put(:meta, option(opts, :meta))
          |> maybe_put(:item_id, option(opts, :item_id, option(opts, :row_identity)))
          |> maybe_put(:link_target, option(opts, :link_target))
          |> maybe_put(:action_intent, option(opts, :action_intent))
          |> maybe_put(:unread_count, normalize_unread_count(option(opts, :unread_count)))
      },
      Map.put(opts, :children, compose_sidebar_item_children(opts))
    )
  end

  @spec sidebar_section(
          String.t(),
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def sidebar_section(title, children \\ [], opts \\ [])
      when is_binary(title) and is_list(children) do
    opts = normalize_opts(opts)

    build_component(
      :sidebar_section,
      :layer_shell_and_callout,
      %{
        sidebar_section:
          %{title: title}
          |> maybe_put(:action_glyph, option(opts, :action_glyph))
          |> maybe_put(:action_label, option(opts, :action_label))
          |> maybe_put(:action_intent, option(opts, :action_intent))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec sidebar_shell(
          [Element.t() | Element.Child.t() | {atom(), Element.t()} | map()],
          opts()
        ) ::
          Element.t()
  def sidebar_shell(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)
    aria_label = option(opts, :aria_label, "primary navigation")
    opts = Map.put_new(opts, :accessibility_label, aria_label)

    build_component(
      :sidebar_shell,
      :layer_shell_and_callout,
      %{
        sidebar_shell: %{
          width: option(opts, :width, :wide),
          aria_label: aria_label
        }
      },
      Map.put(opts, :children, children)
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

  defp compose_sidebar_item_children(opts) do
    base_children = option(opts, :children, [])
    unread_count = normalize_unread_count(option(opts, :unread_count))

    cond do
      unread_count < 1 ->
        base_children

      has_unread_badge_child?(base_children) ->
        base_children

      true ->
        badge_tone =
          option(opts, :badge_tone, if(unread_count > 5, do: :critical, else: :default))

        badge_label =
          option(
            opts,
            :badge_label,
            "#{unread_count} unread #{if unread_count == 1, do: "item", else: "items"}"
          )

        base_children ++
          [
            Element.Child.new(
              :trailing,
              unread_badge(unread_count,
                tone: badge_tone,
                accessibility_label: badge_label,
                id: option(opts, :badge_id)
              )
            )
          ]
    end
  end

  defp has_unread_badge_child?(children) do
    Enum.any?(children, fn
      %Element.Child{element: %Element{kind: :unread_badge}} -> true
      %Element{kind: :unread_badge} -> true
      {:trailing, %Element{kind: :unread_badge}} -> true
      _other -> false
    end)
  end

  defp normalize_unread_count(value) when is_integer(value), do: value
  defp normalize_unread_count(_value), do: 0

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
