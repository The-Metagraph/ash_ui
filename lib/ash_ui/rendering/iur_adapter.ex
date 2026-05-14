defmodule AshUI.Rendering.IURAdapter do
  @moduledoc """
  Adapter for converting Ash IUR to canonical unified_iur format.

  This module handles the conversion from Ash-internal IUR structures
  to the canonical IUR format that renderer packages consume.
  """

  alias AshUI.Compilation.IUR
  alias AshUI.Telemetry
  alias UnifiedIUR.{Binding, Element, Metadata, Normalize, Validate}

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
      children: Enum.map(iur.children, &convert_element/1)
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
      attributes: convert_attributes(kind, props),
      children: Enum.map(element.children, &convert_element/1)
    )
  end

  defp map_element_kind(:textinput), do: :text_input
  defp map_element_kind(:textarea), do: :text_input
  defp map_element_kind(:radio), do: :radio_group
  defp map_element_kind(:switch), do: :toggle
  defp map_element_kind(:divider), do: :separator
  defp map_element_kind(:container), do: :content
  defp map_element_kind(kind) when is_atom(kind), do: kind

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

  defp convert_attributes(kind, props) do
    props = convert_props(props)

    kind
    |> base_attributes(props)
    |> Map.merge(style_attributes(props))
    |> Map.merge(theme_attributes(props))
    |> Map.merge(binding_attributes(props))
    |> Map.merge(interaction_attributes(props))
    |> compact_map()
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
    case fetch(props, :style) do
      nil -> %{}
      style when is_binary(style) -> %{style: %{extra: %{css: style}}}
      style -> %{style: style}
    end
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

  defp first_present(map, keys) do
    keys
    |> Enum.find_value(fn key ->
      value = fetch(map, key)

      if value in [nil, ""], do: nil, else: value
    end)
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
      :interaction
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
