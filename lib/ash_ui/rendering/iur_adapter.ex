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

    Element.new(type, kind,
      id: element.id || generate_id(),
      metadata: convert_metadata(element),
      attributes: convert_attributes(kind, props, element.id),
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

  defp normalize_optional_map(nil), do: nil

  defp normalize_optional_map(value) do
    normalize_map(value)
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

  defp first_present(map, keys) do
    keys
    |> Enum.find_value(fn key ->
      value = fetch(map, key)

      if value in [nil, ""], do: nil, else: value
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
