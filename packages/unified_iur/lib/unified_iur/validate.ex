defmodule UnifiedIUR.Validate do
  @moduledoc """
  Canonical validation helpers for normalized `UnifiedIUR` values.
  """

  alias UnifiedIUR.{Binding, Element, Interaction, Metadata, Style}
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Validate.Error

  @runtime_local_prefixes [
    "DesktopUi",
    "LiveUi",
    "ElmUi",
    "UnifiedUi",
    "Phoenix.LiveView",
    "Jido.Signal"
  ]

  @guidance_by_code %{
    invalid_element: %{
      construct_family: :core_model,
      guidance:
        "Validate values through UnifiedIUR.Normalize and ensure the root is a UnifiedIUR.Element."
    },
    missing_type: %{
      construct_family: :core_model,
      guidance:
        "Create elements through package constructors so canonical type values stay explicit."
    },
    missing_kind: %{
      construct_family: :core_model,
      guidance:
        "Use a known canonical kind from UnifiedIUR.Core, Widgets, Layout, Layer, Forms, or Canvas."
    },
    invalid_metadata: %{
      construct_family: :core_model,
      guidance:
        "Attach metadata through UnifiedIUR.Metadata so description, tags, and annotations stay portable."
    },
    invalid_children: %{
      construct_family: :display_systems,
      guidance: "Represent children as UnifiedIUR.Element.Child values with stable slot names."
    },
    invalid_child: %{
      construct_family: :display_systems,
      guidance:
        "Wrap nested elements with UnifiedIUR.Element.Child.new/2 or package constructors that do so for you."
    },
    invalid_style_attachment: %{
      construct_family: :theming,
      guidance: "Attach styles as UnifiedIUR.Style structs and keep style references portable."
    },
    invalid_theme_attachment: %{
      construct_family: :theming,
      guidance:
        "Attach themes as canonical maps or token references rather than runtime-local theme structs."
    },
    invalid_interaction_attachment: %{
      construct_family: :interactions,
      guidance: "Populate :interactions with UnifiedIUR.Interaction structs only."
    },
    invalid_interactions_attachment: %{
      construct_family: :interactions,
      guidance: "Keep the :interactions attachment as a list of UnifiedIUR.Interaction structs."
    },
    invalid_binding_attachment: %{
      construct_family: :interactions,
      guidance: "Populate :bindings with UnifiedIUR.Binding structs only."
    },
    invalid_bindings_attachment: %{
      construct_family: :interactions,
      guidance: "Keep the :bindings attachment as a list of UnifiedIUR.Binding structs."
    },
    invalid_interaction_scope: %{
      construct_family: :interactions,
      guidance:
        "Represent interaction_scope as a canonical map describing portable routing context."
    },
    runtime_local_escape_hatch: %{
      construct_family: :interoperability,
      guidance:
        "Keep runtime-native structs out of canonical IUR and translate them at runtime-library boundaries."
    },
    invalid_text_segment: %{
      construct_family: :widget_components,
      guidance: "Represent redline content as plain text segments with supported semantic states."
    },
    invalid_code_token: %{
      construct_family: :widget_components,
      guidance:
        "Represent code content as plain text tokens with supported token types or the :text fallback."
    },
    missing_accessible_name: %{
      construct_family: :accessibility,
      guidance:
        "Provide a portable label or accessibility label for component surfaces that need an accessible name."
    },
    invalid_progress_value: %{
      construct_family: :widget_components,
      guidance:
        "Keep progress and meter values numeric and within the canonical minimum and maximum range."
    },
    invalid_selection_option: %{
      construct_family: :widget_components,
      guidance:
        "Represent segmented controls with a non-empty list of options that each include a value and label."
    },
    invalid_repeat_binding: %{
      construct_family: :widget_components,
      guidance:
        "Represent list_repeat with a list binding id, row scope, row field list, and template metadata."
    },
    invalid_artifact_kind: %{
      construct_family: :widget_components,
      guidance:
        "Represent artifact_row kind with the canonical artifact enum: pr, doc, spec, file, grain, or generic."
    },
    invalid_artifact_status_badge: %{
      construct_family: :widget_components,
      guidance:
        "Represent artifact status badges as maps with a text label and optional canonical tone."
    },
    invalid_artifact_count: %{
      construct_family: :widget_components,
      guidance: "Represent artifact counts as a list of maps with key, value, and optional label."
    },
    invalid_rail_contract: %{
      construct_family: :widget_components,
      guidance:
        "Represent right_rail with a rail id, semantic side, ordered panels, active panel, and boolean collapse state."
    },
    invalid_rail_panel: %{
      construct_family: :widget_components,
      guidance:
        "Represent right_rail panels as maps with stable id, label, and optional semantic badge, disabled, empty-state, or slot metadata."
    },
    invalid_rail_active_panel: %{
      construct_family: :widget_components,
      guidance: "Set right_rail active_panel to one of the declared panel ids."
    },
    invalid_rail_interaction: %{
      construct_family: :interactions,
      guidance:
        "Represent rail panel selection and collapse as UnifiedIUR.Interaction structs, not renderer event names."
    },
    invalid_query_preview: %{
      construct_family: :widget_components,
      guidance:
        "Represent composer_query_preview with generic composer, query, preview state, metrics, and renderer-independent action intent."
    },
    invalid_query_preview_finding: %{
      construct_family: :widget_components,
      guidance:
        "Represent composer_query_preview findings as opaque result descriptors with id, ordinal, snippet, and confidence."
    },
    invalid_workflow_progress_status_card: %{
      construct_family: :widget_components,
      guidance:
        "Represent workflow_progress_status_card with subject id, name, progress, status_counts, dependencies, and renderer-independent metadata."
    },
    invalid_workflow_status_count: %{
      construct_family: :widget_components,
      guidance:
        "Represent workflow status counts as non-negative integer counts with optional custom count descriptors."
    },
    invalid_workflow_dependency: %{
      construct_family: :widget_components,
      guidance:
        "Represent workflow dependencies as ordered edge descriptor maps with stable ids and semantic metadata."
    },
    invalid_workflow_action: %{
      construct_family: :interactions,
      guidance:
        "Represent workflow card actions as semantic action maps and omit unavailable actions instead of using nil sentinels."
    },
    invalid_workflow_interaction: %{
      construct_family: :interactions,
      guidance:
        "Represent workflow card focus, open, and dependency selection interactions as UnifiedIUR.Interaction structs without renderer event fields."
    }
  }

  @redline_states [:keep, :insert, :delete, :accepted, :rejected]
  @artifact_kinds [:pr, :doc, :spec, :file, :grain, :generic]
  @artifact_badge_tones [:positive, :warning, :danger, :info, :neutral]
  @rail_sides [:right]
  @query_preview_states [:loading, :ready, :empty, :error]
  @query_preview_forbidden_keys ~w[
    ask_query
    event
    event_target
    helper
    live_action
    mgql
    module
    on_click
    on_dismiss
    on_open_in_ask
    on_save_query
    path
    phx-click
    phx_click
    phx_event
    route
    runtime_module
    url
  ]
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
  @progress_status_card_forbidden_keys ~w[
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
  @code_token_types [
    :text,
    :keyword,
    :identifier,
    :string,
    :number,
    :comment,
    :operator,
    :punctuation,
    :function,
    :module,
    :attribute
  ]

  @spec element(Element.t()) :: :ok | {:error, [Error.t()]}
  def element(%Element{} = element) do
    errors =
      []
      |> Kernel.++(validate_element_shape(element))
      |> Kernel.++(validate_metadata(element.metadata))
      |> Kernel.++(validate_attachments(element.attributes))
      |> Kernel.++(validate_component_contracts(element))
      |> Kernel.++(validate_runtime_local_values(element.attributes, [:attributes]))
      |> Kernel.++(validate_children(element.children))

    if errors == [], do: :ok, else: {:error, errors}
  end

  def element(other) do
    {:error,
     [
       Error.new(
         :invalid_element,
         "validation expects a canonical UnifiedIUR.Element struct",
         details: %{value: inspect(other)}
       )
     ]}
  end

  defp validate_element_shape(%Element{type: type, kind: kind}) do
    []
    |> maybe_add(
      is_nil(type),
      Error.new(:missing_type, "element type is required", path: [:type])
    )
    |> maybe_add(
      is_nil(kind),
      Error.new(:missing_kind, "element kind is required", path: [:kind])
    )
  end

  defp validate_metadata(%Metadata{}), do: []

  defp validate_metadata(other) do
    [
      Error.new(
        :invalid_metadata,
        "element metadata must be a UnifiedIUR.Metadata struct",
        path: [:metadata],
        details: %{value: inspect(other)}
      )
    ]
  end

  @spec diagnostics(Element.t() | map() | keyword()) :: map()
  def diagnostics(input) do
    case UnifiedIUR.Normalize.element(input) do
      {:ok, element} ->
        case element(element) do
          :ok ->
            %{
              valid?: true,
              identity: %{id: element.id, type: element.type, kind: element.kind},
              errors: [],
              construct_families: []
            }

          {:error, errors} ->
            %{
              valid?: false,
              identity: %{id: element.id, type: element.type, kind: element.kind},
              errors: Enum.map(errors, &diagnostic_entry/1),
              construct_families:
                errors
                |> Enum.map(&guidance_for_error/1)
                |> Enum.map(& &1.construct_family)
                |> Enum.uniq()
                |> Enum.sort()
            }
        end

      {:error, errors} ->
        %{
          valid?: false,
          identity: nil,
          errors: Enum.map(errors, &diagnostic_entry/1),
          construct_families:
            errors
            |> Enum.map(&guidance_for_error/1)
            |> Enum.map(& &1.construct_family)
            |> Enum.uniq()
            |> Enum.sort()
        }
    end
  end

  @spec guidance_for_error(Error.t() | atom()) :: %{
          construct_family: atom(),
          guidance: String.t()
        }
  def guidance_for_error(%Error{code: code}), do: guidance_for_error(code)

  def guidance_for_error(code) when is_atom(code) do
    Map.get(@guidance_by_code, code, %{
      construct_family: :unknown,
      guidance:
        "Review the canonical construct family and normalize the value before export or validation."
    })
  end

  defp validate_children(children) when is_list(children) do
    Enum.flat_map(Enum.with_index(children), fn {child, index} ->
      validate_child(child, [:children, index])
    end)
  end

  defp validate_children(other) do
    [
      Error.new(
        :invalid_children,
        "element children must be a list",
        path: [:children],
        details: %{value: inspect(other)}
      )
    ]
  end

  defp validate_child(%Child{slot: slot, element: nil}, _path)
       when is_atom(slot) or is_binary(slot),
       do: []

  defp validate_child(%Child{slot: slot, element: %Element{} = element}, path)
       when is_atom(slot) or is_binary(slot) do
    case element(element) do
      :ok -> []
      {:error, errors} -> Enum.map(errors, &prepend_path(&1, path))
    end
  end

  defp validate_child(%Child{}, path) do
    [
      Error.new(:invalid_child, "child slot must be an atom or string", path: path)
    ]
  end

  defp validate_child(other, path) do
    [
      Error.new(
        :invalid_child,
        "children must be UnifiedIUR.Element.Child structs",
        path: path,
        details: %{value: inspect(other)}
      )
    ]
  end

  defp validate_attachments(attributes) when is_map(attributes) do
    []
    |> validate_style(attributes)
    |> validate_theme(attributes)
    |> validate_interactions(attributes)
    |> validate_bindings(attributes)
    |> validate_interaction_scope(attributes)
  end

  defp validate_attachments(_other), do: []

  defp validate_style(errors, %{style: %Style{}}), do: errors

  defp validate_style(errors, %{style: style}) do
    errors ++
      [
        Error.new(
          :invalid_style_attachment,
          "style attachment must be a UnifiedIUR.Style struct",
          path: [:attributes, :style],
          details: %{value: inspect(style)}
        )
      ]
  end

  defp validate_style(errors, _attributes), do: errors

  defp validate_theme(errors, %{theme: theme}) when is_map(theme), do: errors

  defp validate_theme(errors, %{theme: theme}) do
    errors ++
      [
        Error.new(
          :invalid_theme_attachment,
          "theme attachment must be a map",
          path: [:attributes, :theme],
          details: %{value: inspect(theme)}
        )
      ]
  end

  defp validate_theme(errors, _attributes), do: errors

  defp validate_interactions(errors, %{interactions: interactions}) when is_list(interactions) do
    interaction_errors =
      interactions
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%Interaction{}, _index} ->
          []

        {interaction, index} ->
          [
            Error.new(
              :invalid_interaction_attachment,
              "interactions attachment must contain UnifiedIUR.Interaction structs",
              path: [:attributes, :interactions, index],
              details: %{value: inspect(interaction)}
            )
          ]
      end)

    errors ++ interaction_errors
  end

  defp validate_interactions(errors, %{interactions: value}) do
    errors ++
      [
        Error.new(
          :invalid_interactions_attachment,
          "interactions attachment must be a list",
          path: [:attributes, :interactions],
          details: %{value: inspect(value)}
        )
      ]
  end

  defp validate_interactions(errors, _attributes), do: errors

  defp validate_bindings(errors, %{bindings: bindings}) when is_list(bindings) do
    binding_errors =
      bindings
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%Binding{}, _index} ->
          []

        {binding, index} ->
          [
            Error.new(
              :invalid_binding_attachment,
              "bindings attachment must contain UnifiedIUR.Binding structs",
              path: [:attributes, :bindings, index],
              details: %{value: inspect(binding)}
            )
          ]
      end)

    errors ++ binding_errors
  end

  defp validate_bindings(errors, %{bindings: value}) do
    errors ++
      [
        Error.new(
          :invalid_bindings_attachment,
          "bindings attachment must be a list",
          path: [:attributes, :bindings],
          details: %{value: inspect(value)}
        )
      ]
  end

  defp validate_bindings(errors, _attributes), do: errors

  defp validate_interaction_scope(errors, %{interaction_scope: scope}) when is_map(scope),
    do: errors

  defp validate_interaction_scope(errors, %{interaction_scope: scope}) do
    errors ++
      [
        Error.new(
          :invalid_interaction_scope,
          "interaction_scope attachment must be a map",
          path: [:attributes, :interaction_scope],
          details: %{value: inspect(scope)}
        )
      ]
  end

  defp validate_interaction_scope(errors, _attributes), do: errors

  defp validate_component_contracts(%Element{kind: :redline_inline, attributes: attributes}) do
    attributes
    |> get_in([:redline, :segments])
    |> validate_redline_segments([:attributes, :redline, :segments])
  end

  defp validate_component_contracts(%Element{
         kind: :code_block_syntax_highlighted,
         attributes: attributes
       }) do
    attributes
    |> get_in([:code, :tokens])
    |> validate_code_tokens([:attributes, :code, :tokens])
  end

  defp validate_component_contracts(%Element{kind: :slide_over_panel, attributes: attributes}) do
    label = get_in(attributes, [:panel, :label]) || get_in(attributes, [:accessibility, :label])

    maybe_add(
      [],
      blank?(label),
      Error.new(
        :missing_accessible_name,
        "slide_over_panel requires a label or accessibility label",
        path: [:attributes, :panel, :label]
      )
    )
  end

  defp validate_component_contracts(%Element{
         kind: :segmented_button_group,
         attributes: attributes
       }) do
    attributes
    |> get_in([:selection, :options])
    |> validate_selection_options([:attributes, :selection, :options])
  end

  defp validate_component_contracts(%Element{kind: :artifact_row, attributes: attributes}) do
    artifact = Map.get(attributes, :artifact, %{})

    []
    |> Kernel.++(validate_artifact_kind(fetch(artifact, :kind), [:attributes, :artifact, :kind]))
    |> Kernel.++(
      validate_artifact_status_badges(
        fetch(artifact, :status_badges, []),
        [:attributes, :artifact, :status_badges]
      )
    )
    |> Kernel.++(
      validate_artifact_counts(fetch(artifact, :counts, []), [:attributes, :artifact, :counts])
    )
  end

  defp validate_component_contracts(%Element{kind: :meter_thin, attributes: attributes}) do
    meter = Map.get(attributes, :meter, %{})
    current = fetch(meter, :current)
    minimum = fetch(meter, :minimum, 0)
    maximum = fetch(meter, :maximum, 100)

    valid? =
      is_number(current) and is_number(minimum) and is_number(maximum) and minimum <= current and
        current <= maximum

    maybe_add(
      [],
      not valid?,
      Error.new(
        :invalid_progress_value,
        "meter_thin current, minimum, and maximum must be numeric and in range",
        path: [:attributes, :meter],
        details: %{current: current, minimum: minimum, maximum: maximum}
      )
    )
  end

  defp validate_component_contracts(%Element{kind: :list_repeat, attributes: attributes}) do
    repeat = Map.get(attributes, :repeat, %{})
    binding_id = fetch(repeat, :binding_id)
    row_scope = fetch(repeat, :row_scope)
    row_fields = fetch(repeat, :row_fields)

    maybe_add(
      [],
      blank?(binding_id) or blank?(row_scope) or not is_list(row_fields),
      Error.new(
        :invalid_repeat_binding,
        "list_repeat requires binding_id, row_scope, and row_fields list",
        path: [:attributes, :repeat],
        details: %{binding_id: binding_id, row_scope: row_scope, row_fields: inspect(row_fields)}
      )
    )
  end

  defp validate_component_contracts(%Element{kind: :right_rail, attributes: attributes}) do
    rail = Map.get(attributes, :rail, %{})

    []
    |> Kernel.++(validate_rail_shape(rail))
    |> Kernel.++(validate_rail_panels(fetch(rail, :panels), [:attributes, :rail, :panels]))
    |> Kernel.++(validate_rail_active_panel(rail))
    |> Kernel.++(validate_rail_interactions(Map.get(attributes, :interactions, [])))
  end

  defp validate_component_contracts(%Element{
         kind: :composer_query_preview,
         attributes: attributes
       }) do
    attributes
    |> Map.get(:query_preview, %{})
    |> validate_query_preview_shape()
  end

  defp validate_component_contracts(%Element{
         kind: :workflow_progress_status_card,
         attributes: attributes
       }) do
    attributes
    |> Map.get(:subject, %{})
    |> validate_subject_shape()
  end

  defp validate_component_contracts(_element), do: []

  defp validate_subject_shape(subject) when is_map(subject) do
    []
    |> maybe_add(
      blank?(fetch(subject, :id)) or not is_binary(fetch(subject, :id)),
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card requires subject.id as a non-empty string",
        path: [:attributes, :subject, :id],
        details: %{id: inspect(fetch(subject, :id))}
      )
    )
    |> maybe_add(
      blank?(fetch(subject, :name)) or not is_binary(fetch(subject, :name)),
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card requires subject.name as a non-empty string",
        path: [:attributes, :subject, :name],
        details: %{name: inspect(fetch(subject, :name))}
      )
    )
    |> maybe_add(
      invalid_subject_progress?(fetch(subject, :progress)),
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card subject.progress must be numeric and in 0.0..100.0",
        path: [:attributes, :subject, :progress],
        details: %{progress: inspect(fetch(subject, :progress))}
      )
    )
    |> Kernel.++(
      validate_subject_status_counts(fetch(subject, :status_counts), [
        :attributes,
        :subject,
        :status_counts
      ])
    )
    |> Kernel.++(
      validate_subject_activity(fetch(subject, :activity), [:attributes, :subject, :activity])
    )
    |> Kernel.++(validate_subject_state(fetch(subject, :state), [:attributes, :subject, :state]))
    |> Kernel.++(
      validate_subject_dependencies(fetch(subject, :dependencies), [
        :attributes,
        :subject,
        :dependencies
      ])
    )
    |> Kernel.++(
      validate_subject_actions(fetch(subject, :actions), [:attributes, :subject, :actions])
    )
    |> Kernel.++(
      validate_subject_interactions(fetch(subject, :interactions), [
        :attributes,
        :subject,
        :interactions
      ])
    )
  end

  defp validate_subject_shape(_subject) do
    [
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card attributes.subject must be a map",
        path: [:attributes, :subject]
      )
    ]
  end

  defp validate_subject_status_counts(counts, path) when is_map(counts) do
    []
    |> maybe_add(
      not non_negative_integer?(fetch(counts, :active)),
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card status_counts.active must be a non-negative integer",
        path: path ++ [:active],
        details: %{active: inspect(fetch(counts, :active))}
      )
    )
    |> maybe_add(
      not non_negative_integer?(fetch(counts, :blocked)),
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card status_counts.blocked must be a non-negative integer",
        path: path ++ [:blocked],
        details: %{blocked: inspect(fetch(counts, :blocked))}
      )
    )
    |> Kernel.++(validate_optional_count(fetch(counts, :done), path ++ [:done]))
    |> Kernel.++(validate_optional_count(fetch(counts, :failed), path ++ [:failed]))
    |> Kernel.++(validate_subject_custom_counts(fetch(counts, :custom), path ++ [:custom]))
  end

  defp validate_subject_status_counts(_counts, path) do
    [
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card status_counts must be a map",
        path: path
      )
    ]
  end

  defp validate_optional_count(nil, _path), do: []

  defp validate_optional_count(value, path) do
    maybe_add(
      [],
      not non_negative_integer?(value),
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card optional status counts must be non-negative integers",
        path: path,
        details: %{value: inspect(value)}
      )
    )
  end

  defp validate_subject_custom_counts(nil, _path), do: []

  defp validate_subject_custom_counts(counts, path) when is_list(counts) do
    counts
    |> Enum.with_index()
    |> Enum.flat_map(fn {count, index} ->
      validate_subject_custom_count(count, path ++ [index])
    end)
  end

  defp validate_subject_custom_counts(_counts, path) do
    [
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card status_counts.custom must be a list",
        path: path
      )
    ]
  end

  defp validate_subject_custom_count(count, path) when is_map(count) or is_list(count) do
    count = normalize_map(count)

    maybe_add(
      [],
      blank?(fetch(count, :key)) or not non_negative_integer?(fetch(count, :value)),
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card custom counts require key and non-negative value",
        path: path,
        details: %{key: inspect(fetch(count, :key)), value: inspect(fetch(count, :value))}
      )
    )
  end

  defp validate_subject_custom_count(_count, path) do
    [
      Error.new(
        :invalid_workflow_status_count,
        "workflow_progress_status_card custom counts must be maps",
        path: path
      )
    ]
  end

  defp validate_subject_activity(nil, _path), do: []

  defp validate_subject_activity(activity, path) when is_map(activity) do
    maybe_add(
      [],
      has_forbidden_progress_card_key?(activity),
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card activity must not include renderer event or host route fields",
        path: path
      )
    )
  end

  defp validate_subject_activity(_activity, path) do
    [
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card activity must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_state(nil, _path), do: []

  defp validate_subject_state(state, path) when is_map(state) do
    selected? = fetch(state, :selected?)

    maybe_add(
      [],
      not is_nil(selected?) and not is_boolean(selected?),
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card state.selected? must be boolean when present",
        path: path ++ [:selected?],
        details: %{selected?: inspect(selected?)}
      )
    )
  end

  defp validate_subject_state(_state, path) do
    [
      Error.new(
        :invalid_workflow_progress_status_card,
        "workflow_progress_status_card state must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_dependencies(nil, _path), do: []

  defp validate_subject_dependencies(dependencies, path) when is_map(dependencies) do
    []
    |> Kernel.++(
      validate_subject_dependency_edges(
        fetch(dependencies, :depends_on, []),
        :depends_on,
        path ++ [:depends_on]
      )
    )
    |> Kernel.++(
      validate_subject_dependency_edges(
        fetch(dependencies, :depended_by, []),
        :depended_by,
        path ++ [:depended_by]
      )
    )
  end

  defp validate_subject_dependencies(_dependencies, path) do
    [
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependencies must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_dependency_edges(edges, direction, path) when is_list(edges) do
    edges
    |> Enum.with_index()
    |> Enum.flat_map(fn {edge, index} ->
      validate_subject_dependency_edge(edge, direction, path ++ [index])
    end)
  end

  defp validate_subject_dependency_edges(_edges, _direction, path) do
    [
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edges must be lists",
        path: path
      )
    ]
  end

  defp validate_subject_dependency_edge(edge, direction, path)
       when is_map(edge) or is_list(edge) do
    edge = normalize_map(edge)

    []
    |> maybe_add(
      blank?(fetch(edge, :id)) or not is_binary(fetch(edge, :id)),
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edge requires a non-empty string id",
        path: path ++ [:id],
        details: %{id: inspect(fetch(edge, :id))}
      )
    )
    |> maybe_add(
      fetch(edge, :direction) != direction,
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency direction must match its dependency list",
        path: path ++ [:direction],
        details: %{direction: inspect(fetch(edge, :direction)), expected: direction}
      )
    )
    |> maybe_add(
      not is_nil(fetch(edge, :label)) and not is_binary(fetch(edge, :label)),
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edge label must be a string when present",
        path: path ++ [:label],
        details: %{label: inspect(fetch(edge, :label))}
      )
    )
    |> maybe_add(
      not is_nil(fetch(edge, :metadata)) and not is_map(fetch(edge, :metadata)),
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edge metadata must be a map when present",
        path: path ++ [:metadata]
      )
    )
    |> maybe_add(
      has_forbidden_progress_card_key?(edge),
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edges must not include renderer event or host route fields",
        path: path
      )
    )
    |> Kernel.++(
      validate_subject_interaction(fetch(edge, :interaction), :selection, path ++ [:interaction])
    )
  end

  defp validate_subject_dependency_edge(_edge, _direction, path) do
    [
      Error.new(
        :invalid_workflow_dependency,
        "workflow_progress_status_card dependency edge must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_actions(nil, _path), do: []

  defp validate_subject_actions(actions, path) when is_map(actions) do
    open_action = fetch(actions, :open)

    []
    |> maybe_add(
      has_key?(actions, :open) and is_nil(open_action),
      Error.new(
        :invalid_workflow_action,
        "workflow_progress_status_card actions.open must be omitted when unavailable",
        path: path ++ [:open]
      )
    )
    |> Kernel.++(validate_subject_open_action(open_action, path ++ [:open]))
  end

  defp validate_subject_actions(_actions, path) do
    [
      Error.new(
        :invalid_workflow_action,
        "workflow_progress_status_card actions must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_open_action(nil, _path), do: []

  defp validate_subject_open_action(action, path) when is_map(action) or is_list(action) do
    action = normalize_map(action)

    []
    |> maybe_add(
      blank?(fetch(action, :label)) or blank?(fetch(action, :intent)),
      Error.new(
        :invalid_workflow_action,
        "workflow_progress_status_card actions.open requires label and intent",
        path: path,
        details: %{label: inspect(fetch(action, :label)), intent: inspect(fetch(action, :intent))}
      )
    )
    |> maybe_add(
      has_forbidden_progress_card_key?(action),
      Error.new(
        :invalid_workflow_action,
        "workflow_progress_status_card actions.open must not include renderer event or host route fields",
        path: path
      )
    )
    |> Kernel.++(
      validate_subject_interaction(fetch(action, :interaction), :open, path ++ [:interaction])
    )
  end

  defp validate_subject_open_action(_action, path) do
    [
      Error.new(
        :invalid_workflow_action,
        "workflow_progress_status_card actions.open must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_interactions(nil, _path), do: []

  defp validate_subject_interactions(interactions, path) when is_map(interactions) do
    []
    |> Kernel.++(
      validate_subject_interaction(fetch(interactions, :focus), :focus, path ++ [:focus])
    )
    |> Kernel.++(
      validate_subject_interaction(
        fetch(interactions, :dependency_select),
        :selection,
        path ++ [:dependency_select]
      )
    )
  end

  defp validate_subject_interactions(_interactions, path) do
    [
      Error.new(
        :invalid_workflow_interaction,
        "workflow_progress_status_card interactions must be a map",
        path: path
      )
    ]
  end

  defp validate_subject_interaction(nil, _expected_family, _path), do: []

  defp validate_subject_interaction(%Interaction{} = interaction, expected_family, path) do
    []
    |> maybe_add(
      interaction.family != expected_family,
      Error.new(
        :invalid_workflow_interaction,
        "workflow_progress_status_card interaction family must match the canonical interaction slot",
        path: path ++ [:family],
        details: %{family: inspect(interaction.family), expected: expected_family}
      )
    )
    |> maybe_add(
      has_forbidden_progress_card_key_deep?(interaction),
      Error.new(
        :invalid_workflow_interaction,
        "workflow_progress_status_card interactions must not include renderer event or host route fields",
        path: path
      )
    )
  end

  defp validate_subject_interaction(_interaction, _expected_family, path) do
    [
      Error.new(
        :invalid_workflow_interaction,
        "workflow_progress_status_card interactions must be UnifiedIUR.Interaction structs",
        path: path
      )
    ]
  end

  defp validate_rail_shape(rail) when is_map(rail) do
    []
    |> maybe_add(
      blank?(fetch(rail, :id)),
      Error.new(
        :invalid_rail_contract,
        "right_rail requires a rail id",
        path: [:attributes, :rail, :id]
      )
    )
    |> maybe_add(
      fetch(rail, :side) not in @rail_sides,
      Error.new(
        :invalid_rail_contract,
        "right_rail side must be one of #{inspect(@rail_sides)}",
        path: [:attributes, :rail, :side],
        details: %{side: inspect(fetch(rail, :side))}
      )
    )
    |> maybe_add(
      not is_boolean(fetch(rail, :collapsed?)),
      Error.new(
        :invalid_rail_contract,
        "right_rail collapsed? must be boolean",
        path: [:attributes, :rail, :collapsed?],
        details: %{collapsed?: inspect(fetch(rail, :collapsed?))}
      )
    )
    |> maybe_add(
      not is_boolean(fetch(rail, :collapsible?)),
      Error.new(
        :invalid_rail_contract,
        "right_rail collapsible? must be boolean",
        path: [:attributes, :rail, :collapsible?],
        details: %{collapsible?: inspect(fetch(rail, :collapsible?))}
      )
    )
  end

  defp validate_rail_shape(_rail) do
    [
      Error.new(
        :invalid_rail_contract,
        "right_rail attributes.rail must be a map",
        path: [:attributes, :rail]
      )
    ]
  end

  defp validate_rail_panels(panels, path) when is_list(panels) do
    panels
    |> Enum.with_index()
    |> Enum.flat_map(fn {panel, index} ->
      validate_rail_panel(panel, path ++ [index])
    end)
    |> maybe_add(
      panels == [],
      Error.new(
        :invalid_rail_panel,
        "right_rail panels must be a non-empty list",
        path: path
      )
    )
  end

  defp validate_rail_panels(_panels, path) do
    [
      Error.new(
        :invalid_rail_panel,
        "right_rail panels must be a list",
        path: path
      )
    ]
  end

  defp validate_rail_panel(panel, path) when is_map(panel) or is_list(panel) do
    panel = normalize_map(panel)
    id = fetch(panel, :id)
    label = fetch(panel, :label)
    disabled? = fetch(panel, :disabled?)
    content_slot = fetch(panel, :content_slot)

    []
    |> maybe_add(
      blank?(id) or not is_binary(label),
      Error.new(
        :invalid_rail_panel,
        "right_rail panel requires id and label",
        path: path,
        details: %{id: inspect(id), label: inspect(label)}
      )
    )
    |> maybe_add(
      not is_nil(disabled?) and not is_boolean(disabled?),
      Error.new(
        :invalid_rail_panel,
        "right_rail panel disabled? must be boolean when present",
        path: path ++ [:disabled?],
        details: %{disabled?: inspect(disabled?)}
      )
    )
    |> maybe_add(
      not is_nil(content_slot) and blank?(content_slot),
      Error.new(
        :invalid_rail_panel,
        "right_rail panel content_slot must be stable when present",
        path: path ++ [:content_slot]
      )
    )
    |> maybe_add(
      has_forbidden_rail_panel_key?(panel),
      Error.new(
        :invalid_rail_panel,
        "right_rail panel must not include renderer event or host route fields",
        path: path
      )
    )
  end

  defp validate_rail_panel(_panel, path) do
    [
      Error.new(
        :invalid_rail_panel,
        "right_rail panel must be a map",
        path: path
      )
    ]
  end

  defp validate_rail_active_panel(rail) when is_map(rail) do
    panels = fetch(rail, :panels, [])
    active_panel = fetch(rail, :active_panel)

    maybe_add(
      [],
      blank?(active_panel) or not active_panel_in_panels?(active_panel, panels),
      Error.new(
        :invalid_rail_active_panel,
        "right_rail active_panel must reference a declared panel id",
        path: [:attributes, :rail, :active_panel],
        details: %{active_panel: inspect(active_panel)}
      )
    )
  end

  defp validate_rail_active_panel(_rail), do: []

  defp validate_rail_interactions(interactions) when is_list(interactions) do
    interactions
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%Interaction{}, _index} ->
        []

      {interaction, index} ->
        [
          Error.new(
            :invalid_rail_interaction,
            "right_rail interactions must be UnifiedIUR.Interaction structs",
            path: [:attributes, :interactions, index],
            details: %{value: inspect(interaction)}
          )
        ]
    end)
  end

  defp validate_rail_interactions(nil), do: []

  defp validate_rail_interactions(interactions) do
    [
      Error.new(
        :invalid_rail_interaction,
        "right_rail interactions must be a list",
        path: [:attributes, :interactions],
        details: %{value: inspect(interactions)}
      )
    ]
  end

  defp validate_query_preview_shape(preview) when is_map(preview) do
    preview_state = fetch(preview, :preview_state, :empty)
    max_findings_shown = fetch(preview, :max_findings_shown, 2)

    []
    |> maybe_add(
      not non_empty_string?(fetch(preview, :composer_id)),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview requires composer_id as a non-empty string",
        path: [:attributes, :query_preview, :composer_id],
        details: %{composer_id: inspect(fetch(preview, :composer_id))}
      )
    )
    |> maybe_add(
      not non_empty_string?(fetch(preview, :query)),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview requires query as a non-empty string",
        path: [:attributes, :query_preview, :query],
        details: %{query: inspect(fetch(preview, :query))}
      )
    )
    |> maybe_add(
      not valid_query_preview_state?(preview_state),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview preview_state must be one of #{inspect(@query_preview_states)}",
        path: [:attributes, :query_preview, :preview_state],
        details: %{preview_state: inspect(preview_state)}
      )
    )
    |> maybe_add(
      ready_query_preview?(preview_state) and not non_empty_string?(fetch(preview, :explanation)),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview ready previews require explanation as a non-empty string",
        path: [:attributes, :query_preview, :explanation]
      )
    )
    |> maybe_add(
      not positive_integer?(max_findings_shown),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview max_findings_shown must be a positive integer",
        path: [:attributes, :query_preview, :max_findings_shown],
        details: %{max_findings_shown: inspect(max_findings_shown)}
      )
    )
    |> maybe_add(
      has_forbidden_query_preview_key_deep?(preview),
      Error.new(
        :invalid_query_preview,
        "composer_query_preview must not include product-specific, renderer event, or host route fields",
        path: [:attributes, :query_preview]
      )
    )
    |> Kernel.++(validate_query_preview_metrics(fetch(preview, :metrics)))
    |> Kernel.++(
      validate_query_preview_findings(
        fetch(preview, :findings, []),
        [:attributes, :query_preview, :findings]
      )
    )
  end

  defp validate_query_preview_shape(_preview) do
    [
      Error.new(
        :invalid_query_preview,
        "composer_query_preview attributes.query_preview must be a map",
        path: [:attributes, :query_preview]
      )
    ]
  end

  defp validate_query_preview_metrics(nil), do: []

  defp validate_query_preview_metrics(metrics) when is_map(metrics) or is_list(metrics) do
    metrics = normalize_map(metrics)

    [:results_count, :findings_count, :duration_ms, :sources_visited, :grains_visited]
    |> Enum.flat_map(fn key ->
      value = fetch(metrics, key)

      maybe_add(
        [],
        not is_nil(value) and not non_negative_integer?(value),
        Error.new(
          :invalid_query_preview,
          "composer_query_preview metrics must be non-negative integer counts",
          path: [:attributes, :query_preview, :metrics, key],
          details: %{value: inspect(value)}
        )
      )
    end)
  end

  defp validate_query_preview_metrics(_metrics) do
    [
      Error.new(
        :invalid_query_preview,
        "composer_query_preview metrics must be a map when present",
        path: [:attributes, :query_preview, :metrics]
      )
    ]
  end

  defp validate_query_preview_findings(findings, path) when is_list(findings) do
    findings
    |> Enum.with_index()
    |> Enum.flat_map(fn {finding, index} ->
      validate_query_preview_finding(finding, path ++ [index])
    end)
  end

  defp validate_query_preview_findings(_findings, path) do
    [
      Error.new(
        :invalid_query_preview_finding,
        "composer_query_preview findings must be a list",
        path: path
      )
    ]
  end

  defp validate_query_preview_finding(finding, path) when is_map(finding) or is_list(finding) do
    finding = normalize_map(finding)
    id = fetch(finding, :id) || fetch(finding, :finding_id)
    confidence = fetch(finding, :confidence)

    []
    |> maybe_add(
      not non_empty_string?(id) or not positive_integer?(fetch(finding, :n)) or
        not non_empty_string?(fetch(finding, :snippet)),
      Error.new(
        :invalid_query_preview_finding,
        "composer_query_preview finding requires id, positive n, and snippet",
        path: path,
        details: %{
          id: inspect(id),
          n: inspect(fetch(finding, :n)),
          snippet: inspect(fetch(finding, :snippet))
        }
      )
    )
    |> maybe_add(
      not (is_number(confidence) and confidence >= 0.0 and confidence <= 1.0),
      Error.new(
        :invalid_query_preview_finding,
        "composer_query_preview finding confidence must be in 0.0..1.0",
        path: path ++ [:confidence],
        details: %{confidence: inspect(confidence)}
      )
    )
  end

  defp validate_query_preview_finding(_finding, path) do
    [
      Error.new(
        :invalid_query_preview_finding,
        "composer_query_preview findings must be maps",
        path: path
      )
    ]
  end

  defp validate_selection_options(options, path) when is_list(options) do
    options
    |> Enum.with_index()
    |> Enum.flat_map(fn {option, index} ->
      value = fetch(option, :value)
      label = fetch(option, :label)

      maybe_add(
        [],
        blank?(value) or blank?(label),
        Error.new(
          :invalid_selection_option,
          "segmented_button_group options must include value and label",
          path: path ++ [index],
          details: %{value: inspect(value), label: inspect(label)}
        )
      )
    end)
    |> maybe_add(
      options == [],
      Error.new(
        :invalid_selection_option,
        "segmented_button_group options must be a non-empty list",
        path: path
      )
    )
  end

  defp validate_selection_options(_options, path) do
    [
      Error.new(
        :invalid_selection_option,
        "segmented_button_group options must be a list",
        path: path
      )
    ]
  end

  defp validate_artifact_kind(nil, _path), do: []
  defp validate_artifact_kind(kind, _path) when kind in @artifact_kinds, do: []

  defp validate_artifact_kind(kind, path) do
    [
      Error.new(
        :invalid_artifact_kind,
        "artifact_row kind must be one of #{inspect(@artifact_kinds)}",
        path: path,
        details: %{kind: inspect(kind)}
      )
    ]
  end

  defp validate_artifact_status_badges([], _path), do: []

  defp validate_artifact_status_badges(badges, path) when is_list(badges) do
    badges
    |> Enum.with_index()
    |> Enum.flat_map(fn {badge, index} ->
      label = fetch(badge, :label)
      tone = fetch(badge, :tone)

      maybe_add(
        [],
        not is_binary(label) or (not is_nil(tone) and tone not in @artifact_badge_tones),
        Error.new(
          :invalid_artifact_status_badge,
          "artifact_row status_badges must include label and optional supported tone",
          path: path ++ [index],
          details: %{label: inspect(label), tone: inspect(tone)}
        )
      )
    end)
  end

  defp validate_artifact_status_badges(_badges, path) do
    [
      Error.new(
        :invalid_artifact_status_badge,
        "artifact_row status_badges must be a list",
        path: path
      )
    ]
  end

  defp validate_artifact_counts([], _path), do: []

  defp validate_artifact_counts(counts, path) when is_list(counts) do
    counts
    |> Enum.with_index()
    |> Enum.flat_map(fn {count, index} ->
      key = fetch(count, :key)

      maybe_add(
        [],
        blank?(key) or not has_key?(count, :value),
        Error.new(
          :invalid_artifact_count,
          "artifact_row counts must include key and value",
          path: path ++ [index],
          details: %{key: inspect(key)}
        )
      )
    end)
  end

  defp validate_artifact_counts(_counts, path) do
    [
      Error.new(
        :invalid_artifact_count,
        "artifact_row counts must be a list",
        path: path
      )
    ]
  end

  defp validate_redline_segments(segments, path) when is_list(segments) do
    segments
    |> Enum.with_index()
    |> Enum.flat_map(fn {segment, index} ->
      state = fetch(segment, :state)
      text = fetch(segment, :text)

      maybe_add(
        [],
        state not in @redline_states or not is_binary(text),
        Error.new(
          :invalid_text_segment,
          "redline segment must include plain text and a supported state",
          path: path ++ [index],
          details: %{state: state, text: inspect(text)}
        )
      )
    end)
  end

  defp validate_redline_segments(_segments, path) do
    [
      Error.new(
        :invalid_text_segment,
        "redline segments must be a list",
        path: path
      )
    ]
  end

  defp validate_code_tokens(tokens, path) when is_list(tokens) do
    tokens
    |> Enum.with_index()
    |> Enum.flat_map(fn {token, index} ->
      type = fetch(token, :type, :text)
      text = fetch(token, :text)

      maybe_add(
        [],
        type not in @code_token_types or not is_binary(text),
        Error.new(
          :invalid_code_token,
          "code token must include plain text and a supported token type",
          path: path ++ [index],
          details: %{type: type, text: inspect(text)}
        )
      )
    end)
  end

  defp validate_code_tokens(_tokens, path) do
    [
      Error.new(
        :invalid_code_token,
        "code tokens must be a list",
        path: path
      )
    ]
  end

  defp validate_runtime_local_values(value, path) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} -> validate_runtime_local_values(item, path ++ [index]) end)
  end

  defp validate_runtime_local_values(%Element{} = element, path) do
    case element(element) do
      :ok -> []
      {:error, errors} -> Enum.map(errors, &prepend_path(&1, path))
    end
  end

  defp validate_runtime_local_values(%Child{} = child, path) do
    validate_child(child, path)
  end

  defp validate_runtime_local_values(%_{} = struct, path) do
    module = struct.__struct__

    cond do
      runtime_local_struct?(module) ->
        [
          Error.new(
            :runtime_local_escape_hatch,
            "runtime-local structs are not allowed in canonical IUR values",
            path: path,
            details: %{module: inspect(module)}
          )
        ]

      true ->
        struct
        |> Map.from_struct()
        |> validate_runtime_local_values(path)
    end
  end

  defp validate_runtime_local_values(map, path) when is_map(map) do
    Enum.flat_map(map, fn {key, value} -> validate_runtime_local_values(value, path ++ [key]) end)
  end

  defp validate_runtime_local_values(_value, _path), do: []

  defp runtime_local_struct?(module) do
    parts = Module.split(module)
    name = Enum.join(parts, ".")

    Enum.any?(@runtime_local_prefixes, fn prefix ->
      String.starts_with?(name, prefix) or prefix_in_parts?(parts, String.split(prefix, "."))
    end)
  end

  defp prefix_in_parts?(parts, prefix_parts) do
    parts
    |> Enum.chunk_every(length(prefix_parts), 1, :discard)
    |> Enum.any?(&(&1 == prefix_parts))
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp has_forbidden_rail_panel_key?(panel) do
    panel
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @rail_forbidden_panel_keys))
  end

  defp has_forbidden_progress_card_key?(value) when is_map(value) do
    value
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @progress_status_card_forbidden_keys))
  end

  defp has_forbidden_progress_card_key?(_value), do: false

  defp has_forbidden_progress_card_key_deep?(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> has_forbidden_progress_card_key_deep?()
  end

  defp has_forbidden_progress_card_key_deep?(value) when is_map(value) do
    has_forbidden_progress_card_key?(value) or
      Enum.any?(Map.values(value), &has_forbidden_progress_card_key_deep?/1)
  end

  defp has_forbidden_progress_card_key_deep?(value) when is_list(value) do
    Enum.any?(value, &has_forbidden_progress_card_key_deep?/1)
  end

  defp has_forbidden_progress_card_key_deep?(_value), do: false

  defp has_forbidden_query_preview_key?(value) when is_map(value) do
    value
    |> Map.keys()
    |> Enum.any?(&(to_string(&1) in @query_preview_forbidden_keys))
  end

  defp has_forbidden_query_preview_key?(_value), do: false

  defp has_forbidden_query_preview_key_deep?(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> has_forbidden_query_preview_key_deep?()
  end

  defp has_forbidden_query_preview_key_deep?(value) when is_map(value) do
    has_forbidden_query_preview_key?(value) or
      Enum.any?(Map.values(value), &has_forbidden_query_preview_key_deep?/1)
  end

  defp has_forbidden_query_preview_key_deep?(value) when is_list(value) do
    Enum.any?(value, &has_forbidden_query_preview_key_deep?/1)
  end

  defp has_forbidden_query_preview_key_deep?(_value), do: false

  defp valid_query_preview_state?(state) when state in @query_preview_states, do: true

  defp valid_query_preview_state?(state) when is_binary(state) do
    state in Enum.map(@query_preview_states, &Atom.to_string/1)
  end

  defp valid_query_preview_state?(_state), do: false

  defp ready_query_preview?(state), do: state in [:ready, "ready"]

  defp invalid_subject_progress?(value),
    do: not (is_number(value) and value >= 0.0 and value <= 100.0)

  defp non_empty_string?(value), do: is_binary(value) and value != ""
  defp non_negative_integer?(value), do: is_integer(value) and value >= 0
  defp positive_integer?(value), do: is_integer(value) and value > 0

  defp active_panel_in_panels?(active_panel, panels) when is_list(panels) do
    Enum.any?(panels, fn
      panel when is_map(panel) or is_list(panel) ->
        panel = normalize_map(panel)
        to_string(fetch(panel, :id)) == to_string(active_panel)

      _panel ->
        false
    end)
  end

  defp active_panel_in_panels?(_active_panel, _panels), do: false

  defp fetch(source, key, default \\ nil)

  defp fetch(source, key, default) when is_map(source) do
    Map.get(source, key, Map.get(source, Atom.to_string(key), default))
  end

  defp fetch(source, key, default) when is_list(source),
    do: source |> Enum.into(%{}) |> fetch(key, default)

  defp fetch(_source, _key, default), do: default

  defp has_key?(source, key) when is_map(source) do
    Map.has_key?(source, key) or Map.has_key?(source, Atom.to_string(key))
  end

  defp has_key?(source, key) when is_list(source), do: source |> Enum.into(%{}) |> has_key?(key)
  defp has_key?(_source, _key), do: false

  defp blank?(value), do: value in [nil, ""]

  defp maybe_add(errors, true, error), do: errors ++ [error]
  defp maybe_add(errors, false, _error), do: errors

  defp prepend_path(%Error{} = error, prefix) do
    %{error | path: prefix ++ error.path}
  end

  defp diagnostic_entry(%Error{} = error) do
    guidance = guidance_for_error(error)

    %{
      code: error.code,
      message: Error.format(error),
      path: error.path,
      details: error.details,
      construct_family: guidance.construct_family,
      guidance: guidance.guidance
    }
  end
end
