defmodule UnifiedUi.WidgetComponents do
  @moduledoc """
  Reference catalog for the canonical widget-component expansion.

  The catalog records the AshUi PR 79-98 source mapping, portable canonical
  names, semantic families, and compatibility aliases before the DSL entities
  are implemented.
  """

  @type family ::
          :content_identity_and_disclosure
          | :form_control_and_composer
          | :row_and_artifact
          | :workflow_progress_and_status
          | :layer_shell_and_callout
          | :redline_and_code
          | :composition_behavior

  @type component :: %{
          required(:kind) => atom(),
          required(:family) => family(),
          required(:source) => source(),
          required(:summary) => String.t(),
          required(:aliases) => [atom()]
        }

  @type source :: %{
          required(:system) => :ash_ui,
          required(:pr) => pos_integer(),
          required(:name) => atom()
        }

  @type name_diagnostic :: %{
          required(:status) => :canonical | :alias | :unknown,
          required(:name) => atom() | String.t(),
          optional(:canonical) => atom(),
          optional(:family) => family(),
          required(:message) => String.t()
        }

  @families [
    :content_identity_and_disclosure,
    :form_control_and_composer,
    :row_and_artifact,
    :workflow_progress_and_status,
    :layer_shell_and_callout,
    :redline_and_code,
    :composition_behavior
  ]

  @components [
    %{
      kind: :inline_rich_text_heading,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 79, name: :inline_rich_text_heading},
      summary: "Semantic heading with inline text and emphasis segments.",
      aliases: []
    },
    %{
      kind: :disclosure,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 80, name: :disclosure},
      summary: "Progressive disclosure region with summary, open state, and body children.",
      aliases: []
    },
    %{
      kind: :runtime_form_shell,
      family: :form_control_and_composer,
      source: %{system: :ash_ui, pr: 81, name: :phoenix_form},
      summary: "Portable form shell whose runtime-owned form state is supplied by the host.",
      aliases: [:phoenix_form]
    },
    %{
      kind: :kicker,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 82, name: :kicker},
      summary: "Eyebrow label cluster with ordered items and separator behavior.",
      aliases: []
    },
    %{
      kind: :avatar,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 83, name: :avatar},
      summary: "Identity display using initials or image source with size, shape, and variant.",
      aliases: []
    },
    %{
      kind: :presence_dot,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 84, name: :presence_dot},
      summary: "Small state-driven status indicator with size and accessibility metadata.",
      aliases: []
    },
    %{
      kind: :unread_badge,
      family: :content_identity_and_disclosure,
      source: %{system: :ash_ui, pr: 100, name: :unread_badge},
      summary: "Compact unread-count pill with default and critical tones.",
      aliases: []
    },
    %{
      kind: :segmented_button_group,
      family: :form_control_and_composer,
      source: %{system: :ash_ui, pr: 85, name: :segmented_button_group},
      summary: "Single-selection segmented control with option values and labels.",
      aliases: []
    },
    %{
      kind: :list_item_multi_column,
      family: :row_and_artifact,
      source: %{system: :ash_ui, pr: 86, name: :list_item_multi_column},
      summary: "Selectable or linkable multi-column row with child cell content.",
      aliases: []
    },
    %{
      kind: :artifact_row,
      family: :row_and_artifact,
      source: %{system: :ash_ui, pr: 87, name: :artifact_row},
      summary: "Artifact row with title, meta text, row identity, and trailing content.",
      aliases: []
    },
    %{
      kind: :sticky_frosted_header,
      family: :layer_shell_and_callout,
      source: %{system: :ash_ui, pr: 88, name: :sticky_frosted_header},
      summary: "Sticky shell header with leading, title, and trailing child positions.",
      aliases: []
    },
    %{
      kind: :pipeline_stepper_horizontal,
      family: :workflow_progress_and_status,
      source: %{system: :ash_ui, pr: 89, name: :pipeline_stepper_horizontal},
      summary: "Horizontal workflow stepper with done, active, and pending step state.",
      aliases: []
    },
    %{
      kind: :segmented_progress_bar,
      family: :workflow_progress_and_status,
      source: %{system: :ash_ui, pr: 90, name: :segmented_progress_bar},
      summary: "Weighted multi-segment progress bar with per-segment state.",
      aliases: []
    },
    %{
      kind: :workflow_stage_list_vertical,
      family: :workflow_progress_and_status,
      source: %{system: :ash_ui, pr: 91, name: :workflow_stage_list_vertical},
      summary: "Vertical numbered workflow stage list with connector state.",
      aliases: []
    },
    %{
      kind: :meter_thin,
      family: :workflow_progress_and_status,
      source: %{system: :ash_ui, pr: 92, name: :meter_thin},
      summary: "Compact progress meter with normalized value and optional label.",
      aliases: []
    },
    %{
      kind: :slide_over_panel,
      family: :layer_shell_and_callout,
      source: %{system: :ash_ui, pr: 93, name: :slide_over_panel},
      summary: "Non-modal contextual side panel with open state, size, and children.",
      aliases: []
    },
    %{
      kind: :event_callout,
      family: :layer_shell_and_callout,
      source: %{system: :ash_ui, pr: 94, name: :event_callout},
      summary: "Inline stream or status callout with tone, eyebrow, body, and action content.",
      aliases: []
    },
    %{
      kind: :redline_inline,
      family: :redline_and_code,
      source: %{system: :ash_ui, pr: 95, name: :redline_inline},
      summary:
        "Inline redline text display with keep, insert, delete, accepted, and rejected state.",
      aliases: []
    },
    %{
      kind: :code_block_syntax_highlighted,
      family: :redline_and_code,
      source: %{system: :ash_ui, pr: 96, name: :code_block_syntax_highlighted},
      summary: "Pre-tokenized code block display with language and semantic token types.",
      aliases: []
    },
    %{
      kind: :chat_composer,
      family: :form_control_and_composer,
      source: %{system: :ash_ui, pr: 97, name: :chat_composer},
      summary: "Multi-line composer with tool area, send intent, and change intent.",
      aliases: []
    },
    %{
      kind: :list_repeat,
      family: :composition_behavior,
      source: %{system: :ash_ui, pr: 98, name: :ui_relationship_repeat},
      summary:
        "Composition behavior that repeats a child template over rows from a list binding.",
      aliases: [:ui_relationship_repeat, :repeat]
    }
  ]

  @component_by_kind Map.new(@components, &{&1.kind, &1})

  @alias_to_kind Map.new(
                   for component <- @components,
                       alias_name <- component.aliases,
                       do: {alias_name, component.kind}
                 )

  @known_binary_names MapSet.new(
                        Enum.map(
                          Map.keys(@component_by_kind) ++ Map.keys(@alias_to_kind),
                          &to_string/1
                        )
                      )

  @spec families() :: [family()]
  def families do
    @families
  end

  @spec catalog() :: [component()]
  def catalog do
    @components
  end

  @spec kinds() :: [atom()]
  def kinds do
    Enum.map(@components, & &1.kind)
  end

  @spec aliases() :: %{atom() => atom()}
  def aliases do
    @alias_to_kind
  end

  @spec component(atom() | String.t()) :: {:ok, component()} | {:error, name_diagnostic()}
  def component(name) do
    with {:ok, kind} <- canonical_kind(name) do
      {:ok, Map.fetch!(@component_by_kind, kind)}
    end
  end

  @spec component!(atom() | String.t()) :: component()
  def component!(name) do
    case component(name) do
      {:ok, component} ->
        component

      {:error, diagnostic} ->
        raise ArgumentError, diagnostic.message
    end
  end

  @spec canonical_kind(atom() | String.t()) :: {:ok, atom()} | {:error, name_diagnostic()}
  def canonical_kind(name) do
    normalized = normalize_name(name)

    cond do
      Map.has_key?(@component_by_kind, normalized) ->
        {:ok, normalized}

      Map.has_key?(@alias_to_kind, normalized) ->
        {:ok, Map.fetch!(@alias_to_kind, normalized)}

      true ->
        {:error, name_diagnostic(name)}
    end
  end

  @spec canonical_kind!(atom() | String.t()) :: atom()
  def canonical_kind!(name) do
    case canonical_kind(name) do
      {:ok, kind} ->
        kind

      {:error, diagnostic} ->
        raise ArgumentError, diagnostic.message
    end
  end

  @spec name_diagnostic(atom() | String.t()) :: name_diagnostic()
  def name_diagnostic(name) do
    normalized = normalize_name(name)

    cond do
      Map.has_key?(@component_by_kind, normalized) ->
        component = Map.fetch!(@component_by_kind, normalized)

        %{
          status: :canonical,
          name: normalized,
          canonical: normalized,
          family: component.family,
          message: "#{inspect(normalized)} is a canonical widget-component name."
        }

      Map.has_key?(@alias_to_kind, normalized) ->
        canonical = Map.fetch!(@alias_to_kind, normalized)
        component = Map.fetch!(@component_by_kind, canonical)

        %{
          status: :alias,
          name: normalized,
          canonical: canonical,
          family: component.family,
          message:
            "#{inspect(normalized)} is an AshUi compatibility alias; use #{inspect(canonical)} for canonical UnifiedUi authoring."
        }

      true ->
        %{
          status: :unknown,
          name: normalized,
          message:
            "#{inspect(name)} is not part of the canonical widget-component catalog or AshUi compatibility aliases."
        }
    end
  end

  @spec component_families() :: %{family() => [atom()]}
  def component_families do
    Map.new(@families, fn family ->
      kinds =
        @components
        |> Enum.filter(&(&1.family == family))
        |> Enum.map(& &1.kind)

      {family, kinds}
    end)
  end

  @spec components_for_family(family()) :: [component()]
  def components_for_family(family) do
    Enum.filter(@components, &(&1.family == family))
  end

  @spec source_mapping() :: %{pos_integer() => map()}
  def source_mapping do
    Map.new(@components, fn component ->
      source = component.source

      {source.pr,
       %{
         source_name: source.name,
         canonical_kind: component.kind,
         family: component.family,
         aliases: component.aliases
       }}
    end)
  end

  defp normalize_name(name) when is_atom(name), do: name

  defp normalize_name(name) when is_binary(name) do
    if MapSet.member?(@known_binary_names, name) do
      String.to_existing_atom(name)
    else
      name
    end
  end
end
