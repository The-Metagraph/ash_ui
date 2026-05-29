defmodule AshUI.Rendering.IURAdapter do
  @moduledoc """
  Adapter for converting Ash IUR to canonical unified_iur format.

  This module handles the conversion from Ash-internal IUR structures
  to the canonical IUR format that renderer packages consume.
  """

  alias AshUI.Compilation.IUR
  alias AshUI.Telemetry
  alias AshUI.WidgetComponents
  alias UnifiedIUR.{Binding, Element, Metadata, Normalize, Validate}
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Widgets.Components, as: IURComponents

  @doc """
  Converts an Ash IUR to canonical unified_iur Screen format.

  ## Options
    * `:telemetry` - Whether to emit telemetry events (default: true)

  ## Returns
    * `{:ok, canonical_iur}` - Successfully converted
    * `{:error, reason}` - Conversion failed
  """
  @spec to_canonical(IUR.t(), keyword()) :: {:ok, Element.t()} | {:error, term()}
  def to_canonical(%IUR{} = ash_iur, opts \\ []) do
    telemetry? = Keyword.get(opts, :telemetry, true)

    case IUR.validate(ash_iur) do
      :ok ->
        try do
          with {:ok, canonical} <- ash_iur |> convert_iur() |> normalize_with_unified_iur() do
            if telemetry? do
              Telemetry.execute(
                [:ash_ui, :rendering, :convert_success],
                %{count: 1},
                %{resource_id: ash_iur.id, resource_type: ash_iur.type, status: :ok}
              )
            end

            {:ok, canonical}
          else
            {:error, reason} -> emit_conversion_error(ash_iur, telemetry?, reason)
          end
        rescue
          error ->
            emit_conversion_error(ash_iur, telemetry?, error)
        end

      {:error, reason} ->
        emit_conversion_error(ash_iur, telemetry?, reason)
    end
  end

  @doc """
  Checks if a renderer is compatible with the given IUR.

  ## Returns
    * `true` - Compatible
    * `false` - Not compatible
  """
  @spec compatible?(IUR.t(), atom()) :: boolean()
  def compatible?(%IUR{type: :screen}, :live_ui), do: true
  def compatible?(%IUR{type: :screen}, :elm), do: true
  def compatible?(%IUR{type: :screen}, :desktop_ui), do: true
  def compatible?(%IUR{}, _renderer), do: false

  # Convert Ash IUR to canonical UnifiedIUR elements.
  defp convert_iur(%IUR{type: :screen} = iur) do
    Element.new(:composite, :screen,
      id: iur.id || generate_id(),
      metadata: convert_metadata(iur),
      attributes:
        %{
          screen:
            compact_map(%{
              name: iur.name,
              layout: convert_layout(fetch(iur.attributes, :layout)),
              version: iur.version
            }),
          bindings: Enum.map(iur.bindings, &convert_binding/1)
        }
        |> Map.merge(interaction_attributes(%{actions: fetch(iur.attributes, :actions, [])})),
      children: convert_children(iur.children)
    )
  end

  defp convert_iur(%IUR{} = iur) do
    convert_element(iur)
  end

  defp convert_element(%IUR{} = element) do
    kind = map_element_kind(element.type)
    type = map_element_type(kind)
    props = if map_size(element.props || %{}) > 0, do: element.props, else: element.attributes
    fallback_id = element.id || generate_id()
    element_id = element_id_for_kind(kind, convert_props(props), fallback_id)
    attribute_element_id = if kind == :live_session_card, do: element_id, else: element.id

    Element.new(type, kind,
      id: element_id,
      metadata: convert_metadata(element),
      attributes: convert_attributes(kind, props, attribute_element_id),
      children: convert_children(element.children)
    )
  end

  defp convert_children(children) do
    Enum.map(children, fn child ->
      Child.new(child_slot(child), convert_element(child))
    end)
  end

  defp child_slot(%IUR{} = child) do
    child.metadata
    |> fetch(:composition, %{})
    |> fetch(:slot, fetch(child.metadata, :slot, :default))
    |> normalize_existing_atom()
  end

  defp map_element_kind(:textinput), do: :text_input
  defp map_element_kind(:textarea), do: :text_input
  defp map_element_kind(:radio), do: :radio_group
  defp map_element_kind(:switch), do: :toggle
  defp map_element_kind(:divider), do: :separator
  defp map_element_kind(:container), do: :content

  defp map_element_kind(kind) when is_atom(kind) do
    case WidgetComponents.canonical_kind(kind) do
      {:ok, canonical_kind} -> canonical_kind
      {:error, _diagnostic} -> kind
    end
  end

  defp map_element_kind(kind) when is_binary(kind) do
    kind
    |> convert_camel_to_snake()
    |> String.to_atom()
    |> map_element_kind()
  end

  defp map_element_kind(kind), do: kind |> to_string() |> map_element_kind()

  defp map_element_type(kind) when kind in [:fragment, :screen], do: :composite

  defp map_element_type(kind) when kind in [:form_builder, :field_group, :field, :form_field],
    do: :composite

  defp map_element_type(kind) when kind in [:row, :column, :grid, :stack, :split_pane],
    do: :layout

  defp map_element_type(kind) when kind in [:viewport, :scroll_bar], do: :layout

  defp map_element_type(kind)
       when kind in [:overlay, :dialog, :toast, :alert_dialog, :context_menu],
       do: :layer

  defp map_element_type(_kind), do: :widget

  defp element_id_for_kind(:live_session_card, props, fallback_id) do
    live_session = props |> fetch(:live_session, %{}) |> normalize_map()

    session_id =
      first_present(live_session, [:session_id]) ||
        first_present(props, [:session_id])

    status_version =
      first_present(live_session, [:status_version]) ||
        first_present(props, [:status_version])

    if is_binary(session_id) and not is_nil(status_version) do
      "live_session:#{session_id}:#{status_version}"
    else
      fallback_id
    end
  end

  defp element_id_for_kind(_kind, _props, fallback_id), do: fallback_id

  # Convert props with name transformations
  defp convert_props(props) when is_map(props) do
    Enum.reduce(props, %{}, fn {key, value}, acc ->
      merge_converted_prop(acc, convert_prop_name(key), value)
    end)
  end

  defp convert_props(_), do: %{}

  defp convert_attributes(kind, props, element_id) do
    props = convert_props(props)
    props = if is_nil(element_id), do: props, else: Map.put_new(props, :_element_id, element_id)

    kind
    |> base_attributes(props)
    |> Map.merge(style_attributes(props))
    |> Map.merge(theme_attributes(props))
    |> Map.merge(binding_attributes(props))
    |> Map.merge(interaction_attributes(props))
    |> compact_map()
  end

  defp base_attributes(:inline_rich_text_heading = kind, props) do
    component_attributes(
      kind,
      :content_identity_and_disclosure,
      %{
        heading:
          compact_map(%{
            level: normalize_existing_atom(first_present(props, [:level, :heading_level]) || :h2),
            segments: normalize_heading_segments(props)
          })
      },
      props
    )
  end

  defp base_attributes(:disclosure = kind, props) do
    component_attributes(
      kind,
      :content_identity_and_disclosure,
      %{
        disclosure:
          compact_map(%{
            summary: first_present(props, [:summary, :label, :title]),
            open?: first_present(props, [:open?, :open]) || false
          })
      },
      props
    )
  end

  defp base_attributes(:kicker = kind, props) do
    component_attributes(
      kind,
      :content_identity_and_disclosure,
      %{
        kicker: %{
          items: normalize_string_list(first_present(props, [:items, :labels, :content, :text])),
          separator: first_present(props, [:separator]) || "/"
        }
      },
      props
    )
  end

  defp base_attributes(:avatar = kind, props) do
    component_attributes(
      kind,
      :content_identity_and_disclosure,
      %{
        identity:
          compact_map(%{
            initials: first_present(props, [:initials, :fallback, :label]),
            image_source: first_present(props, [:image_source, :image, :src, :url]),
            size: normalize_existing_atom(first_present(props, [:size]) || :medium),
            shape: normalize_existing_atom(first_present(props, [:shape]) || :round)
          })
      },
      props
    )
  end

  defp base_attributes(:presence_dot = kind, props) do
    component_attributes(
      kind,
      :content_identity_and_disclosure,
      %{
        presence: %{
          state: normalize_existing_atom(first_present(props, [:state, :status]) || :offline),
          size: normalize_existing_atom(first_present(props, [:size]) || :medium)
        }
      },
      props
    )
  end

  defp base_attributes(:runtime_form_shell = kind, props) do
    component_attributes(
      kind,
      :form_control_and_composer,
      %{
        form:
          compact_map(%{
            fields: normalize_maps(fetch(props, :fields, [])),
            submit_label: first_present(props, [:submit_label, :label]),
            submit_intent: first_present(props, [:submit_intent, :submit_action]),
            change_intent: first_present(props, [:change_intent, :change_action]),
            validation_state: normalize_existing_atom(fetch(props, :validation_state)),
            host_adapter_hints: normalize_optional_map(fetch(props, :host_adapter_hints))
          })
      },
      props
    )
  end

  defp base_attributes(:segmented_button_group = kind, props) do
    component_attributes(
      kind,
      :form_control_and_composer,
      %{
        selection:
          compact_map(%{
            presentation: :segmented_button_group,
            multiple?: false,
            options: normalize_options(fetch(props, :options, [])),
            active_value: first_present(props, [:active_value, :value, :selected]),
            selection_intent: first_present(props, [:selection_intent, :change_intent])
          })
      },
      props
    )
  end

  defp base_attributes(:chat_composer = kind, props) do
    component_attributes(
      kind,
      :form_control_and_composer,
      %{
        composer:
          compact_map(%{
            name: first_present(props, [:name]),
            value: first_present(props, [:value, :text, :content]),
            placeholder: first_present(props, [:placeholder]),
            rows: fetch(props, :rows, 3),
            send_label: first_present(props, [:send_label]) || "Send",
            send_intent: first_present(props, [:send_intent, :submit_intent]),
            change_intent: first_present(props, [:change_intent])
          })
      },
      props
    )
  end

  defp base_attributes(:collection_picker, props) do
    props
    |> collection_picker_opts()
    |> IURComponents.collection_picker()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:list_item_multi_column = kind, props) do
    component_attributes(
      kind,
      :row_and_artifact,
      %{
        row:
          common_row_attrs(props)
          |> maybe_put(:column_template, normalize_maps(fetch(props, :column_template, [])))
      },
      props
    )
  end

  defp base_attributes(:artifact_row = kind, props) do
    component_attributes(
      kind,
      :row_and_artifact,
      %{
        artifact:
          common_row_attrs(props)
          |> maybe_put(:title, first_present(props, [:title, :label, :name]))
          |> maybe_put(:meta, fetch(props, :meta))
          |> maybe_put(
            :kind,
            normalize_artifact_kind(first_present(props, [:artifact_kind, :artifact_type]))
          )
          |> maybe_put(
            :status_badges,
            normalize_artifact_status_badges(fetch(props, :status_badges))
          )
          |> maybe_put(:counts, normalize_artifact_counts(fetch(props, :counts)))
          |> maybe_put(
            :timestamp_at,
            first_present(props, [:timestamp_at, :updated_at, :created_at])
          )
      },
      props
    )
  end

  defp base_attributes(:thread_card, props) do
    props
    |> thread_card_opts()
    |> IURComponents.thread_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:tool_call_card, props) do
    props
    |> tool_call_card_opts()
    |> IURComponents.tool_call_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:live_session_card, props) do
    props
    |> live_session_card_opts()
    |> IURComponents.live_session_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:pipeline_stepper_horizontal = kind, props) do
    component_attributes(
      kind,
      :workflow_progress_and_status,
      %{
        workflow:
          compact_map(%{
            presentation: :pipeline_stepper_horizontal,
            steps: normalize_maps(fetch(props, :steps, [])),
            active_index: fetch(props, :active_index, 0),
            completed_indices: fetch(props, :completed_indices, []),
            navigation_intent: first_present(props, [:navigation_intent])
          })
      },
      props
    )
  end

  defp base_attributes(:segmented_progress_bar = kind, props) do
    component_attributes(
      kind,
      :workflow_progress_and_status,
      %{
        progress:
          compact_map(%{
            presentation: :segmented_progress_bar,
            segments: normalize_maps(fetch(props, :segments, [])),
            aggregate:
              normalize_optional_map(first_present(props, [:aggregate_progress, :aggregate])),
            label: first_present(props, [:label])
          })
      },
      props
    )
  end

  defp base_attributes(:workflow_stage_list_vertical = kind, props) do
    component_attributes(
      kind,
      :workflow_progress_and_status,
      %{
        workflow:
          compact_map(%{
            presentation: :workflow_stage_list_vertical,
            stages: normalize_maps(fetch(props, :stages, [])),
            active_index: fetch(props, :active_index, 0)
          })
      },
      props
    )
  end

  defp base_attributes(:meter_thin = kind, props) do
    component_attributes(
      kind,
      :workflow_progress_and_status,
      %{
        meter:
          compact_map(%{
            current: first_present(props, [:current, :value]) || 0,
            minimum: fetch(props, :minimum, 0),
            maximum: fetch(props, :maximum, 100),
            label: first_present(props, [:label]),
            state: normalize_existing_atom(fetch(props, :state))
          })
      },
      props
    )
  end

  defp base_attributes(:sticky_frosted_header = kind, props) do
    component_attributes(
      kind,
      :layer_shell_and_callout,
      %{
        shell:
          compact_map(%{
            position: :sticky,
            visual_effect: :frosted,
            title: first_present(props, [:title, :label]),
            leading: fetch(props, :leading, []),
            trailing: fetch(props, :trailing, [])
          })
      },
      props
    )
  end

  defp base_attributes(:slide_over_panel = kind, props) do
    component_attributes(
      kind,
      :layer_shell_and_callout,
      %{
        panel:
          compact_map(%{
            modal?: false,
            open?: first_present(props, [:open?, :open]) || false,
            size: normalize_existing_atom(first_present(props, [:size]) || :medium),
            label: first_present(props, [:label, :accessibility_label, :title]),
            dismiss_intent: first_present(props, [:dismiss_intent, :close_intent])
          })
      },
      props
    )
  end

  defp base_attributes(:event_callout = kind, props) do
    component_attributes(
      kind,
      :layer_shell_and_callout,
      %{
        callout:
          compact_map(%{
            message: first_present(props, [:message, :body, :content, :text]),
            tone: normalize_existing_atom(first_present(props, [:tone]) || :info),
            eyebrow: first_present(props, [:eyebrow, :kicker]),
            title: first_present(props, [:title]),
            action_intent: first_present(props, [:action_intent])
          })
      },
      props
    )
  end

  defp base_attributes(:right_rail = kind, props) do
    collapsible? = first_present(props, [:collapsible?, :collapsible])

    component_attributes(
      kind,
      :layer_shell_and_callout,
      %{
        rail:
          compact_map(%{
            id: first_present(props, [:rail_id, :id, :_element_id]),
            side: normalize_existing_atom(first_present(props, [:side]) || :right),
            panels: normalize_maps(fetch(props, :panels, [])),
            active_panel: first_present(props, [:active_panel, :active_tab, :selected_panel]),
            collapsed?: first_present(props, [:collapsed?, :collapsed]) || false,
            collapsible?: if(is_nil(collapsible?), do: true, else: collapsible?),
            density: normalize_existing_atom(fetch(props, :density)),
            width: normalize_existing_atom(fetch(props, :width))
          })
      },
      props
    )
  end

  defp base_attributes(:composer_query_preview, props) do
    props
    |> composer_query_preview_opts()
    |> IURComponents.composer_query_preview()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:propose_new_doc_card, props) do
    props
    |> propose_new_doc_card_opts()
    |> IURComponents.propose_new_doc_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:escalation_card, props) do
    props
    |> escalation_card_opts()
    |> IURComponents.escalation_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(:redline_inline = kind, props) do
    component_attributes(
      kind,
      :redline_and_code,
      %{
        redline: %{segments: normalize_redline_segments(fetch(props, :segments, []))},
        text_safety: %{content: normalize_existing_atom(fetch(props, :text_safety, :plain_text))}
      },
      props
    )
  end

  defp base_attributes(:code_block_syntax_highlighted = kind, props) do
    component_attributes(
      kind,
      :redline_and_code,
      %{
        code: %{
          language: first_present(props, [:language, :lang]) || :text,
          tokens: normalize_code_tokens(fetch(props, :tokens, []))
        },
        text_safety: %{content: normalize_existing_atom(fetch(props, :text_safety, :plain_text))}
      },
      props
    )
  end

  defp base_attributes(:list_repeat = kind, props) do
    component_attributes(
      kind,
      :composition_behavior,
      %{
        repeat:
          compact_map(%{
            binding_id: first_present(props, [:repeat_binding, :binding_id, :binding]),
            row_scope: first_present(props, [:row_scope]) || :row,
            row_fields: fetch(props, :row_fields, []),
            identity_strategy: first_present(props, [:identity_strategy]) || :row_identity,
            child_slot: first_present(props, [:child_slot]) || :default,
            hydrated?: first_present(props, [:hydrated?, :hydrated]) || false,
            row_count: fetch(props, :row_count, 0),
            binding_ref: normalize_optional_map(fetch(props, :binding_ref)),
            template_identity: first_present(props, [:template_identity]),
            template: normalize_optional_map(fetch(props, :template))
          })
      },
      props
    )
  end

  defp base_attributes(kind, props) when kind in [:row, :column, :grid, :stack] do
    %{layout: Map.drop(props, attachment_prop_keys())}
  end

  defp base_attributes(:text, props) do
    %{content: %{text: first_present(props, [:content, :text, :label, :value])}}
  end

  defp base_attributes(:label, props) do
    %{
      content: %{text: first_present(props, [:content, :text, :label, :value])},
      label: compact_map(%{for: fetch(props, :for)})
    }
  end

  defp base_attributes(:button, props) do
    %{
      content: %{text: first_present(props, [:label, :content, :text, :value])},
      button: Map.drop(props, [:label, :content, :text, :value] ++ attachment_prop_keys())
    }
  end

  defp base_attributes(:link, props) do
    %{
      content: %{text: first_present(props, [:label, :content, :text, :value])},
      link: compact_map(%{target: first_present(props, [:target, :href])})
    }
  end

  defp base_attributes(:icon, props) do
    %{
      icon:
        compact_map(%{
          name: first_present(props, [:name, :icon]),
          set: fetch(props, :set),
          fallback_text: fetch(props, :fallback_text)
        })
    }
  end

  defp base_attributes(:image, props) do
    %{
      image:
        compact_map(%{
          source: first_present(props, [:source, :src, :url]),
          alt_text: first_present(props, [:alt_text, :alt]),
          fit: fetch(props, :fit)
        })
    }
  end

  defp base_attributes(:separator, props),
    do: %{separator: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:spacer, props), do: %{spacer: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:content, props), do: %{container: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:text_input, props), do: %{input: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:numeric_input, props),
    do: %{input: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:select, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:pick_list, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:slider, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:date_input, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:time_input, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:file_input, props), do: %{input: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:toggle, props), do: %{state: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:checkbox, props), do: %{state: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:radio_group, props),
    do: %{selection: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:menu, props), do: %{navigation: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:tabs, props), do: %{navigation: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:context_selector, props) do
    max_selections = first_present(props, [:max_selections]) || 1

    %{
      context_selector:
        compact_map(%{
          selector_id: first_present(props, [:selector_id, :context_id, :id, :_element_id]),
          groups: normalize_context_selector_groups(fetch(props, :groups, [])),
          placeholder: first_present(props, [:placeholder]) || "Select context...",
          selected_values: List.wrap(fetch(props, :selected_values, [])),
          max_selections: max_selections,
          multiple?:
            boolean_present(
              props,
              [:multiple?],
              context_selector_multiple?(max_selections)
            ),
          label_prefix: first_present(props, [:label_prefix]) || "context:",
          open?: boolean_present(props, [:open?], false),
          disabled?: boolean_present(props, [:disabled?], false),
          selection_intent: first_present(props, [:selection_intent, :change_intent])
        })
    }
  end

  defp base_attributes(:file_tree_browser, props) do
    %{
      file_tree:
        compact_map(%{
          tree_id: first_present(props, [:tree_id, :id_key, :id, :_element_id]),
          root_label: first_present(props, [:root_label, :label]) || "",
          nodes: normalize_maps(fetch(props, :nodes, [])),
          selected_path: first_present(props, [:selected_path]),
          default_expanded?:
            boolean_present(props, [:default_expanded?, :default_expanded], true),
          selection_intent: first_present(props, [:selection_intent, :select_intent]),
          toggle_intent: first_present(props, [:toggle_intent])
        })
    }
  end

  defp base_attributes(:command_palette, props),
    do: %{command_palette: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:ask_sidebar = kind, props) do
    component_attributes(
      kind,
      :layer_shell_and_callout,
      %{
        ask_sidebar:
          compact_map(%{
            sidebar_id: first_present(props, [:sidebar_id, :id_key]),
            on_map_jump_event: first_present(props, [:on_map_jump_event, :map_jump_event]),
            recent_items: fetch(props, :recent_items, []),
            saved_items: fetch(props, :saved_items, []),
            blocker_count: fetch(props, :blocker_count, 0),
            empty_recent_label:
              first_present(props, [:empty_recent_label]) || "No recent queries",
            empty_saved_label:
              first_present(props, [:empty_saved_label]) || "No saved queries yet"
          })
          |> maybe_put(:active_item_id, first_present(props, [:active_item_id]))
          |> maybe_put(:on_new_saved_event, first_present(props, [:on_new_saved_event]))
          |> maybe_put(:on_see_all_event, first_present(props, [:on_see_all_event]))
      },
      props
    )
  end

  defp base_attributes(:list, props), do: %{list: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:table, props), do: %{table: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:tree_view, props), do: %{tree: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:stat, props), do: %{stat: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:key_value, props),
    do: %{key_value: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:info_list, props),
    do: %{info_list: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:status, props), do: %{feedback: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:progress, props), do: %{progress: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:gauge, props), do: %{chart: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:inline_feedback, props),
    do: %{feedback: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:diff_banner, props) do
    %{
      diff:
        compact_map(%{
          new_count: normalize_count(fetch(props, :new_count, 0)),
          changed_count: normalize_count(fetch(props, :changed_count, 0)),
          removed_count: normalize_count(fetch(props, :removed_count, 0)),
          base_label: first_present(props, [:base_label]),
          active_filter: normalize_existing_atom(first_present(props, [:active_filter])) || :all,
          show_filter_chips?: boolean_present(props, [:show_filter_chips?], true),
          size: normalize_existing_atom(first_present(props, [:size])) || :default,
          filter_intent: first_present(props, [:filter_intent, :selection_intent])
        })
    }
  end

  defp base_attributes(:confidence_indicator, props) do
    confidence =
      %{
        value: first_present(props, [:value, :confidence_value]) || 0.0,
        thresholds:
          normalize_optional_map(first_present(props, [:thresholds])) ||
            %{
              warn: 0.5,
              pass: 0.8
            },
        show_numeric?: boolean_present(props, [:show_numeric?], true),
        show_glyph?: boolean_present(props, [:show_glyph?], true),
        size: normalize_existing_atom(first_present(props, [:size]) || :medium)
      }
      |> maybe_put(:label, first_present(props, [:label]))

    %{confidence: confidence}
  end

  defp base_attributes(:dialog, props), do: %{dialog: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:alert_dialog, props),
    do: %{alert_dialog: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:toast, props), do: %{toast: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:overlay, props), do: %{overlay: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:context_menu, props),
    do: %{context_menu: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:viewport, props), do: %{viewport: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:scroll_bar, props),
    do: %{scroll_bar: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:split_pane, props), do: %{split: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:canvas, props), do: %{canvas: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:form_builder, props), do: %{form: Map.drop(props, attachment_prop_keys())}
  defp base_attributes(:field_group, props), do: %{group: Map.drop(props, attachment_prop_keys())}

  defp base_attributes(:workflow_progress_status_card, props) do
    props
    |> workflow_progress_status_card_opts()
    |> IURComponents.workflow_progress_status_card()
    |> Map.fetch!(:attributes)
  end

  defp base_attributes(kind, props), do: %{kind => Map.drop(props, attachment_prop_keys())}

  defp style_attributes(props) do
    style =
      props
      |> fetch(:style)
      |> merge_style_extra(%{
        class: fetch(props, :class),
        css: fetch(props, :inline_style)
      })

    if style in [nil, %{}], do: %{}, else: %{style: style}
  end

  defp theme_attributes(props) do
    %{}
    |> maybe_put(:theme, fetch(props, :theme))
    |> maybe_put(:theme_id, fetch(props, :theme_id))
    |> maybe_put(:style_refs, fetch(props, :style_refs))
    |> maybe_put(:token_refs, fetch(props, :token_refs))
    |> maybe_put(:variant, fetch(props, :variant))
    |> maybe_put(:state, fetch(props, :state))
    |> maybe_put(:tone, fetch(props, :tone))
  end

  defp binding_attributes(props) do
    props
    |> fetch(:bindings, [])
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> %{}
      bindings -> %{bindings: Enum.map(bindings, &Binding.new/1)}
    end
  end

  defp interaction_attributes(props) do
    explicit_interactions =
      props
      |> fetch(:interactions, [])
      |> List.wrap()

    action_interactions =
      props
      |> fetch(:actions, [])
      |> List.wrap()
      |> Enum.map(&convert_action_interaction/1)

    (explicit_interactions ++ action_interactions)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> %{}
      interactions -> %{interactions: Enum.map(interactions, &UnifiedIUR.Interaction.new/1)}
    end
  end

  defp convert_action_interaction(action) when is_map(action) do
    case fetch(action, :navigation) do
      nil -> convert_generic_action_interaction(action)
      navigation -> convert_navigation_action_interaction(action, navigation)
    end
  end

  defp convert_action_interaction(_action), do: nil

  defp convert_navigation_action_interaction(action, navigation) do
    target_intent = AshUI.Navigation.Intent.normalize!(navigation, label: "canonical navigation")

    signal =
      UnifiedUi.Signal.new(%{
        id: fetch(action, :id),
        family: :navigation,
        intent: fetch(action, :signal, :navigation),
        source_context: fetch(action, :source_context, %{}),
        target_intent: target_intent,
        payload_mapping: fetch(action, :payload_mapping, fetch(action, :transform, %{})),
        binding_refs: fetch(action, :binding_refs, []),
        summary: fetch(action, :summary),
        metadata: fetch(action, :metadata, %{})
      })

    descriptor = UnifiedUi.Signal.navigation_descriptor(signal)

    UnifiedIUR.Interaction.new(%{
      family: :navigation,
      intent: fetch(target_intent, :action, fetch(action, :id)),
      source:
        %{
          action_id: fetch(action, :id),
          trigger: fetch(action, :signal),
          context: signal.source_context
        }
        |> compact_map(),
      target: %{navigation: descriptor},
      payload:
        %{
          mapping: signal.payload_mapping,
          binding_refs: signal.binding_refs
        }
        |> compact_map(),
      metadata:
        %{
          ash_ui: fetch(action, :metadata, %{}),
          summary: signal.summary
        }
        |> compact_map()
    })
  end

  defp convert_generic_action_interaction(action) do
    UnifiedIUR.Interaction.new(%{
      family: fetch(action, :signal, :command),
      intent: fetch(action, :id),
      source: fetch(action, :source, %{}),
      target: %{path: normalize_path(fetch(action, :target))},
      payload: %{mapping: fetch(action, :transform, %{})},
      metadata: fetch(action, :metadata, %{})
    })
  end

  defp merge_converted_prop(acc, :style, value) when is_binary(value) and value != "" do
    Map.put(acc, :style, %{extra: %{css: value}})
  end

  defp merge_converted_prop(acc, key, value) do
    Map.put(acc, key, convert_prop_value(value))
  end

  # Convert prop names from camelCase to snake_case
  defp convert_prop_name(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> convert_camel_to_snake()
    |> safe_existing_atom()
  end

  defp convert_prop_name(key) when is_binary(key) do
    key
    |> convert_camel_to_snake()
    |> safe_existing_atom()
  end

  defp convert_prop_name(key), do: to_string(key)

  defp convert_camel_to_snake(name) do
    Regex.replace(~r/([A-Z])/, name, "_\\1")
    |> String.downcase()
    |> String.trim_leading("_")
  end

  defp convert_prop_value(value), do: value

  defp convert_metadata(%IUR{} = iur) do
    Metadata.new(%{
      authored_ref: iur.id || iur.name,
      annotations: compact_map(%{ash_ui_type: iur.type, ash_ui_name: iur.name}),
      tags: [:ash_ui],
      extra: %{
        "ash_ui" => iur.metadata || %{},
        "ash_ui_version" => iur.version
      }
    })
  end

  defp emit_conversion_error(ash_iur, telemetry?, error) do
    if telemetry? do
      Telemetry.execute(
        [:ash_ui, :rendering, :convert_error],
        %{count: 1},
        %{
          resource_id: ash_iur.id,
          resource_type: ash_iur.type,
          status: :error,
          error: inspect(error)
        }
      )
    end

    {:error, {:conversion_failed, error}}
  end

  defp convert_layout(nil), do: :column
  defp convert_layout(:row), do: :row
  defp convert_layout(:column), do: :column
  defp convert_layout(:grid), do: :grid
  defp convert_layout(:stack), do: :stack
  defp convert_layout(other) when is_binary(other), do: safe_existing_atom(other)
  defp convert_layout(other), do: other

  defp convert_binding(binding) when is_map(binding) do
    binding_type = map_binding_type(fetch(binding, :binding_type))

    Binding.new(%{
      name: fetch(binding, :id, fetch(binding, :target)),
      path: normalize_path(fetch(binding, :target)),
      source: binding_type,
      collection?: binding_type == :collection,
      metadata:
        binding
        |> Map.new()
        |> Map.put(:ash_ui_source, convert_binding_source(fetch(binding, :source)))
        |> Map.put(:ash_ui_transform, fetch(binding, :transform, %{}))
    })
  end

  defp convert_binding(binding), do: Binding.new(%{metadata: %{ash_ui_binding: inspect(binding)}})

  defp map_binding_type("value"), do: :bidirectional
  defp map_binding_type("list"), do: :collection
  defp map_binding_type("action"), do: :event
  defp map_binding_type(:value), do: :bidirectional
  defp map_binding_type(:list), do: :collection
  defp map_binding_type(:action), do: :event
  defp map_binding_type(other) when is_binary(other), do: safe_existing_atom(other)
  defp map_binding_type(other), do: other

  defp convert_binding_source(source) when is_map(source), do: source
  defp convert_binding_source(source), do: %{"path" => to_string(source)}

  defp normalize_path(nil), do: []
  defp normalize_path(path) when is_atom(path) or is_binary(path), do: [path]
  defp normalize_path(path) when is_list(path), do: path

  defp component_attributes(kind, family, kind_attributes, props) do
    %{component: %{family: family, kind: kind}}
    |> Map.merge(kind_attributes)
    |> maybe_put(:accessibility, component_accessibility(props))
  end

  defp component_accessibility(props) do
    props
    |> fetch(:accessibility, %{})
    |> normalize_map()
    |> maybe_put(:label, first_present(props, [:accessibility_label, :aria_label]))
    |> maybe_put(
      :description,
      first_present(props, [:accessibility_description, :aria_description])
    )
    |> maybe_put(:decorative?, first_present(props, [:decorative?]))
  end

  defp common_row_attrs(props) do
    %{}
    |> maybe_put(:row_identity, first_present(props, [:row_identity, :id]))
    |> maybe_put(:active?, first_present(props, [:active?, :active]))
    |> maybe_put(:link_target, first_present(props, [:link_target, :href, :target]))
    |> maybe_put(:action_intent, first_present(props, [:action_intent, :intent]))
  end

  defp thread_card_opts(props) do
    thread = props |> fetch(:thread, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      thread_id:
        first_present(thread, [:thread_id]) || first_present(props, [:thread_id, :row_identity]),
      title: first_present(thread, [:title]) || first_present(props, [:title, :label, :name]),
      reply_count:
        first_present(thread, [:reply_count]) || first_present(props, [:reply_count, :replies]) ||
          0,
      seed_quote:
        first_present(thread, [:seed_quote]) ||
          first_present(props, [:seed_quote, :quote, :excerpt]),
      participants: fetch(props, :participants, []),
      progress_pct:
        first_present(thread, [:progress_pct]) || first_present(props, [:progress_pct]),
      last_activity_at:
        first_present(thread, [:last_activity_at]) ||
          first_present(props, [:last_activity_at, :updated_at]),
      open_intent: first_present(props, [:open_intent, :intent]) || :open_thread,
      open_interaction: fetch(props, :open_interaction)
    }
    |> compact_map()
  end

  defp tool_call_card_opts(props) do
    tool_call = props |> fetch(:tool_call, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      tool_name:
        first_present(tool_call, [:tool_name]) ||
          first_present(props, [:tool_name, :name, :label]),
      tool_kind:
        normalize_existing_atom(
          first_present(tool_call, [:tool_kind]) || first_present(props, [:tool_kind]) || :other
        ),
      target: first_present(tool_call, [:target]) || first_present(props, [:target, :path]),
      summary:
        first_present(tool_call, [:summary]) || first_present(props, [:summary, :description]),
      status:
        normalize_existing_atom(
          first_present(tool_call, [:status]) || first_present(props, [:status]) || :pending
        ),
      args: tool_call_args_value(tool_call, props),
      expanded?:
        boolean_present(tool_call, [:expanded?], boolean_present(props, [:expanded?], false)),
      actor_handle:
        first_present(tool_call, [:actor_handle]) || first_present(props, [:actor_handle]),
      started_at: first_present(tool_call, [:started_at]) || first_present(props, [:started_at]),
      duration_ms:
        first_present(tool_call, [:duration_ms]) || first_present(props, [:duration_ms]),
      approval_event_id:
        first_present(tool_call, [:approval_event_id]) ||
          first_present(props, [:approval_event_id]),
      paired_result_event_id:
        first_present(tool_call, [:paired_result_event_id]) ||
          first_present(props, [:paired_result_event_id]),
      expand_intent: first_present(props, [:expand_intent]) || :expand_toggled,
      expand_interaction: fetch(props, :expand_interaction),
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp composer_query_preview_opts(props) do
    preview = props |> fetch(:query_preview, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      composer_id: first_present(preview, [:composer_id]) || first_present(props, [:composer_id]),
      query:
        first_present(preview, [:query]) || first_present(props, [:query, :ask_query, :value]),
      preview_state:
        normalize_existing_atom(
          first_present(preview, [:preview_state]) ||
            first_present(props, [:preview_state]) ||
            :empty
        ),
      explanation:
        first_present(preview, [:explanation]) ||
          first_present(props, [:explanation, :explain, :summary]),
      metrics:
        normalize_optional_map(
          first_present(preview, [:metrics]) || first_present(props, [:metrics, :meta])
        ),
      findings:
        first_present(preview, [:findings]) ||
          first_present(props, [:findings, :preview_findings]) ||
          [],
      max_findings_shown:
        first_present(preview, [:max_findings_shown]) ||
          first_present(props, [:max_findings_shown]) ||
          2,
      error_message:
        first_present(preview, [:error_message]) || first_present(props, [:error_message]),
      loading_label:
        first_present(preview, [:loading_label]) || first_present(props, [:loading_label]),
      empty_label: first_present(preview, [:empty_label]) || first_present(props, [:empty_label]),
      open_label: first_present(preview, [:open_label]) || first_present(props, [:open_label]),
      save_label: first_present(preview, [:save_label]) || first_present(props, [:save_label]),
      dismiss_intent: first_present(props, [:dismiss_intent]),
      open_intent: first_present(props, [:open_intent]),
      save_intent: first_present(props, [:save_intent]),
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp propose_new_doc_card_opts(props) do
    proposal = props |> fetch(:propose_new_doc, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      target_path:
        first_present(proposal, [:target_path]) || first_present(props, [:target_path]),
      title: first_present(proposal, [:title]) || first_present(props, [:title, :label, :name]),
      body_md_preview:
        first_present(proposal, [:body_md_preview]) ||
          first_present(props, [:body_md_preview, :preview, :summary]),
      body_md: first_present(proposal, [:body_md]) || first_present(props, [:body_md, :body]),
      status:
        normalize_existing_atom(
          first_present(proposal, [:status]) || first_present(props, [:status]) || :pending
        ),
      conversation_seed_md:
        first_present(proposal, [:conversation_seed_md]) ||
          first_present(props, [:conversation_seed_md]),
      actor_handle:
        first_present(proposal, [:actor_handle]) || first_present(props, [:actor_handle]),
      proposed_at:
        first_present(proposal, [:proposed_at]) || first_present(props, [:proposed_at]),
      actions:
        first_present(proposal, [:actions]) ||
          first_present(props, [:actions]) ||
          [:accept, :reject, :preview],
      accept_intent: first_present(props, [:accept_intent]),
      reject_intent: first_present(props, [:reject_intent]),
      preview_intent: first_present(props, [:preview_intent]),
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp escalation_card_opts(props) do
    escalation = props |> fetch(:escalation, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      target_project_id:
        first_present(escalation, [:target_project_id]) ||
          first_present(props, [:target_project_id, :project_id, :project]),
      text:
        first_present(escalation, [:text]) ||
          first_present(props, [:text, :description, :message]),
      severity:
        normalize_existing_atom(
          first_present(escalation, [:severity]) ||
            first_present(props, [:severity]) ||
            :p2
        ),
      related_finding_id:
        first_present(escalation, [:related_finding_id]) ||
          first_present(props, [:related_finding_id]),
      proposed_action:
        first_present(escalation, [:proposed_action]) ||
          first_present(props, [:proposed_action]),
      target_finding_id:
        first_present(escalation, [:target_finding_id]) ||
          first_present(props, [:target_finding_id]),
      target_severity:
        normalize_existing_atom(
          first_present(escalation, [:target_severity]) ||
            first_present(props, [:target_severity])
        ),
      originating_severity:
        normalize_existing_atom(
          first_present(escalation, [:originating_severity]) ||
            first_present(props, [:originating_severity])
        ),
      actor_handle:
        first_present(escalation, [:actor_handle]) ||
          first_present(props, [:actor_handle]),
      escalated_at:
        first_present(escalation, [:escalated_at]) ||
          first_present(props, [:escalated_at]),
      acknowledge_intent: first_present(props, [:acknowledge_intent]),
      route_intent: first_present(props, [:route_intent]),
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp collection_picker_opts(props) do
    picker = props |> fetch(:collection_picker, %{}) |> normalize_map()

    %{
      id: first_present(props, [:_element_id, :id]),
      picker_id:
        string_identifier(
          first_present(picker, [:picker_id]) ||
            first_present(props, [
              :picker_id,
              :collection_id,
              :bundle_id,
              :rail_id,
              :id,
              :_element_id
            ])
        ),
      title: first_present(picker, [:title]) || first_present(props, [:title, :label]),
      query:
        first_present(picker, [:query]) ||
          first_present(props, [:query, :search_query, :value]) ||
          "",
      placeholder:
        first_present(picker, [:placeholder]) ||
          first_present(props, [:placeholder, :search_placeholder]),
      filters:
        collection_picker_entries(
          first_present(picker, [:filters]) ||
            first_present(props, [:filters, :filter_chips]) ||
            [],
          :filter
        ),
      items:
        collection_picker_entries(
          first_present(picker, [:items]) || first_present(props, [:items]) || [],
          :item
        ),
      suggestions:
        collection_picker_entries(
          first_present(picker, [:suggestions]) ||
            first_present(props, [:suggestions, :agent_suggestions]) ||
            [],
          :suggestion
        ),
      empty_label:
        first_present(picker, [:empty_label]) ||
          first_present(props, [:empty_label, :empty_state_message]),
      loading?: first_present(picker, [:loading?]) || first_present(props, [:loading?]),
      density:
        normalize_existing_atom(first_present(picker, [:density]) || fetch(props, :density)),
      change_intent: first_present(props, [:change_intent]),
      selection_intent: first_present(props, [:selection_intent, :select_intent]),
      filter_toggle_intent: first_present(props, [:filter_toggle_intent]),
      suggestion_accept_intent: first_present(props, [:suggestion_accept_intent]),
      suggestion_dismiss_intent: first_present(props, [:suggestion_dismiss_intent]),
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp collection_picker_entries(entries, kind) when is_list(entries) do
    Enum.map(entries, &collection_picker_entry(&1, kind))
  end

  defp collection_picker_entries(_entries, _kind), do: []

  defp collection_picker_entry(entry, kind) when is_map(entry) or is_list(entry) do
    entry = normalize_map(entry)
    id = collection_picker_entry_id(entry, kind)

    %{
      id: id,
      label: collection_picker_entry_label(entry, id)
    }
    |> maybe_put(:description, first_present(entry, [:description, :subtitle, :body]))
    |> maybe_put(:meta, normalize_optional_map(first_present(entry, [:meta, :metadata])))
    |> maybe_put(:selected?, first_present(entry, [:selected?, :selected, :active?]))
    |> maybe_put(:disabled?, first_present(entry, [:disabled?, :disabled]))
    |> maybe_put(:draggable?, first_present(entry, [:draggable?]))
    |> maybe_put(:count, first_present(entry, [:count]))
    |> maybe_put(:source, first_present(entry, [:source, :agent]))
    |> maybe_put(:confidence, first_present(entry, [:confidence]))
    |> compact_map()
  end

  defp collection_picker_entry(entry, kind) do
    id = string_identifier(entry) || Atom.to_string(kind)
    %{id: id, label: id}
  end

  defp collection_picker_entry_id(entry, :filter) do
    string_identifier(first_present(entry, [:id, :filter_id, :value, :key]))
  end

  defp collection_picker_entry_id(entry, :item) do
    string_identifier(first_present(entry, [:id, :item_id, :value, :key]))
  end

  defp collection_picker_entry_id(entry, :suggestion) do
    string_identifier(first_present(entry, [:id, :suggestion_id, :value, :key]))
  end

  defp collection_picker_entry_label(entry, fallback) do
    case first_present(entry, [:label, :title, :name, :text]) do
      nil -> fallback
      value -> to_string(value)
    end
  end

  defp workflow_progress_status_card_opts(props) do
    %{
      subject_id: first_present(props, [:subject_id]),
      name: first_present(props, [:name, :label]),
      path: first_present(props, [:subject_path, :path]),
      progress: first_present(props, [:progress]),
      progress_pct: first_present(props, [:progress_pct, :progress_percent]),
      status_counts: normalize_optional_map(fetch(props, :status_counts)),
      active_count: first_present(props, [:active_count]),
      blocked_count: first_present(props, [:blocked_count]),
      done_count: first_present(props, [:done_count]),
      failed_count: first_present(props, [:failed_count]),
      custom_counts: first_present(props, [:custom_counts]),
      activity: normalize_optional_map(fetch(props, :activity)),
      last_activity_at: first_present(props, [:last_activity_at, :updated_at]),
      depends_on: fetch(props, :depends_on, []),
      depended_by: fetch(props, :depended_by, []),
      selected?: first_present(props, [:selected?]) || false,
      focus_intent: first_present(props, [:focus_intent]) || "focus_subject",
      focus_interaction: first_present(props, [:focus_interaction]),
      dependency_select_intent: first_present(props, [:dependency_select_intent]),
      dependency_select_interaction: first_present(props, [:dependency_select_interaction]),
      open_action: normalize_optional_map(first_present(props, [:open_action]))
    }
    |> compact_map()
  end

  defp live_session_card_opts(props) do
    live_session = props |> fetch(:live_session, %{}) |> normalize_map()

    %{
      session_id:
        first_present(live_session, [:session_id]) ||
          first_present(props, [:session_id]),
      actor_handle:
        first_present(live_session, [:actor_handle]) ||
          first_present(props, [:actor_handle]),
      status:
        normalize_existing_atom(
          first_present(live_session, [:status]) ||
            first_present(props, [:status]) ||
            :running
        ),
      status_version:
        first_present(live_session, [:status_version]) ||
          first_present(props, [:status_version]),
      tools_count:
        first_present(live_session, [:tools_count]) ||
          first_present(props, [:tools_count]),
      edits_count:
        first_present(live_session, [:edits_count]) ||
          first_present(props, [:edits_count]),
      tokens_consumed:
        first_present(live_session, [:tokens_consumed]) ||
          first_present(props, [:tokens_consumed]),
      started_at:
        first_present(live_session, [:started_at]) ||
          first_present(props, [:started_at]),
      current_step:
        first_present(live_session, [:current_step]) ||
          first_present(props, [:current_step]),
      current_task_title:
        first_present(live_session, [:current_task_title]) ||
          first_present(props, [:current_task_title]),
      now_streaming:
        first_present(live_session, [:now_streaming]) ||
          first_present(props, [:now_streaming]),
      recent_events:
        first_present(live_session, [:recent_events]) ||
          fetch(props, :recent_events, []),
      pinned?:
        boolean_present(live_session, [:pinned?], boolean_present(props, [:pinned?], false)),
      pin_intent: first_present(props, [:pin_intent]) || :pin_toggled,
      interrupt_intent: first_present(props, [:interrupt_intent]) || :interrupted,
      expanded_recent_intent: first_present(props, [:expanded_recent_intent]) || :expanded_recent,
      interactions: fetch(props, :interactions),
      interaction: fetch(props, :interaction)
    }
    |> compact_map()
  end

  defp normalize_heading_segments(props) do
    case fetch(props, :segments) do
      segments when is_list(segments) ->
        normalize_maps(segments)

      _other ->
        case first_present(props, [:content, :text, :label, :value]) do
          nil -> []
          text -> [%{type: :text, value: text}]
        end
    end
  end

  defp normalize_string_list(nil), do: []
  defp normalize_string_list(value) when is_binary(value), do: [value]
  defp normalize_string_list(value) when is_list(value), do: value
  defp normalize_string_list(value), do: [to_string(value)]

  defp normalize_options(options) when is_list(options) do
    Enum.map(options, fn option ->
      option
      |> normalize_map()
      |> Map.update(:disabled?, nil, & &1)
    end)
  end

  defp normalize_options(options), do: options

  defp normalize_maps(values) when is_list(values) do
    Enum.map(values, &normalize_map/1)
  end

  defp normalize_maps(values), do: values

  defp normalize_context_selector_groups(groups) when is_list(groups) do
    Enum.map(groups, fn group ->
      group = normalize_map(group)

      group
      |> Map.drop(["items"])
      |> Map.put(:items, group |> fetch(:items, []) |> normalize_maps())
    end)
  end

  defp normalize_context_selector_groups(groups), do: groups

  defp context_selector_multiple?(:unlimited), do: true
  defp context_selector_multiple?("unlimited"), do: true
  defp context_selector_multiple?(value) when is_integer(value), do: value > 1
  defp context_selector_multiple?(_value), do: false

  defp normalize_count(value) when is_integer(value) and value >= 0, do: value
  defp normalize_count(value) when is_float(value) and value >= 0, do: round(value)

  defp normalize_count(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 0 -> parsed
      _other -> 0
    end
  end

  defp normalize_count(_value), do: 0

  defp normalize_optional_map(nil), do: nil

  defp normalize_optional_map(value) do
    normalize_map(value)
  end

  defp tool_call_args_value(tool_call, props) do
    cond do
      not is_nil(first_present(tool_call, [:args])) -> first_present(tool_call, [:args])
      not is_nil(fetch(props, :args)) -> fetch(props, :args)
      true -> %{}
    end
  end

  defp normalize_redline_segments(segments) when is_list(segments) do
    Enum.map(segments, fn segment ->
      segment
      |> normalize_map()
      |> update_existing_atom_value(:state)
    end)
  end

  defp normalize_redline_segments(segments), do: segments

  defp normalize_code_tokens(tokens) when is_list(tokens) do
    Enum.map(tokens, fn token ->
      token
      |> normalize_map()
      |> update_existing_atom_value(:type)
    end)
  end

  defp normalize_code_tokens(tokens), do: tokens

  defp normalize_artifact_kind(nil), do: :generic
  defp normalize_artifact_kind(value), do: normalize_existing_atom(value)

  defp normalize_artifact_status_badges(nil), do: nil

  defp normalize_artifact_status_badges(badges) when is_list(badges) do
    badges
    |> normalize_maps()
    |> empty_to_nil()
  end

  defp normalize_artifact_status_badges(_badges), do: nil

  defp normalize_artifact_counts(nil), do: nil

  defp normalize_artifact_counts(counts) when is_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> %{key: key, value: value} end)
    |> empty_to_nil()
  end

  defp normalize_artifact_counts(counts) when is_list(counts) do
    counts
    |> Enum.map(fn
      {key, value} -> %{key: key, value: value}
      count -> normalize_map(count)
    end)
    |> empty_to_nil()
  end

  defp normalize_artifact_counts(_counts), do: nil

  defp empty_to_nil([]), do: nil
  defp empty_to_nil(value), do: value

  defp update_existing_atom_value(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> Map.put(map, key, normalize_existing_atom(value))
      :error -> map
    end
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(value) when is_map(value), do: Map.new(value)
  defp normalize_map(value) when is_list(value), do: Enum.into(value, %{})
  defp normalize_map(value), do: %{value: value}

  defp normalize_existing_atom(nil), do: nil
  defp normalize_existing_atom(value) when is_atom(value), do: value

  defp normalize_existing_atom(value) when is_binary(value) do
    safe_existing_atom(value)
  end

  defp normalize_existing_atom(value), do: value

  defp string_identifier(nil), do: nil
  defp string_identifier(value) when is_binary(value) and value != "", do: value

  defp string_identifier(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp string_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp string_identifier(value) when is_float(value), do: :erlang.float_to_binary(value)
  defp string_identifier(value), do: to_string(value)

  defp first_present(map, keys) do
    keys
    |> Enum.find_value(fn key ->
      value = fetch(map, key)

      if value in [nil, ""], do: nil, else: value
    end)
  end

  defp boolean_present(map, keys, default) do
    Enum.reduce_while(keys, default, fn key, _acc ->
      case fetch(map, key) do
        value when value in [nil, ""] -> {:cont, default}
        value -> {:halt, value}
      end
    end)
  end

  defp merge_style_extra(style, extra) do
    extra =
      extra
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> Map.new()

    style =
      case style do
        nil -> %{}
        "" -> %{}
        value when is_binary(value) -> %{extra: %{css: value}}
        value when is_list(value) -> Enum.into(value, %{})
        value when is_map(value) -> Map.new(value)
        value -> value
      end

    cond do
      extra == %{} ->
        style

      is_map(style) ->
        Map.update(style, :extra, extra, fn existing ->
          existing
          |> normalize_map()
          |> Map.merge(extra)
        end)

      true ->
        style
    end
  end

  defp attachment_prop_keys do
    [
      :style,
      :theme,
      :theme_id,
      :style_refs,
      :token_refs,
      :variant,
      :state,
      :tone,
      :bindings,
      :binding,
      :interactions,
      :interaction,
      :_element_id
    ]
  end

  defp fetch(map, key, default \\ nil)

  defp fetch(map, key, default) when is_map(map),
    do: Map.get(map, key, Map.get(map, to_string(key), default))

  defp fetch(_other, _key, default), do: default

  defp safe_existing_atom(value) when is_atom(value), do: value

  defp safe_existing_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> value
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  defp generate_id do
    UUID.uuid4()
  end

  defp normalize_with_unified_iur(canonical) do
    with {:ok, normalized} <- Normalize.element(canonical),
         :ok <- Validate.element(normalized) do
      {:ok, normalized}
    end
  end
end
