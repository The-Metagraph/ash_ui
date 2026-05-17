defmodule LiveUi.Tooling do
  @moduledoc """
  Package-facing entrypoint for inspection and validation helpers.
  """

  import Phoenix.LiveViewTest

  alias LiveUi.Examples
  alias LiveUi.Runtime.State
  alias UnifiedIUR.Element

  @required_example_paths [:aligned]
  @required_example_families [
    :content,
    :input,
    :navigation,
    :data,
    :feedback,
    :operational,
    :overlay,
    :display,
    :layout
  ]
  @required_docs [
    "README.md",
    "guides/runtime_backbone.md",
    "guides/native_runtime_and_examples.md",
    "guides/canonical_rendering_and_transport.md",
    "guides/maintainer_workflows.md"
  ]
  @required_doc_snippets %{
    "README.md" => [
      "same focused example ids",
      "mix live_ui.preview button --format html",
      "mix live_ui.inspect button --format comparison",
      "mix live_ui.export button --format diagnostics"
    ],
    "guides/runtime_backbone.md" => [
      "same aligned example ids"
    ],
    "guides/native_runtime_and_examples.md" => [
      "same widget-focused example ids",
      "package-specialized live_ui screen"
    ],
    "guides/canonical_rendering_and_transport.md" => [
      "same aligned example ids",
      "canonical review path"
    ],
    "guides/maintainer_workflows.md" => [
      "mix live_ui.preview button --format html",
      "mix live_ui.inspect button --format comparison",
      "mix live_ui.export button --format diagnostics"
    ]
  }
  @prohibited_doc_patterns [
    {"mix live_ui.demo", ~r/\bmix live_ui\.demo\b/},
    {"demo workbench", ~r/\bdemo workbench\b/i},
    {"package-local demo", ~r/\bpackage-local demo\b/i},
    {"native canonical mixed taxonomy", ~r/\bnative,\s+canonical,\s+and\s+mixed\b/i},
    {"maintained mixed examples", ~r/\bmaintained mixed examples\b/i}
  ]
  @browser_style_approximation_rules [
    %{
      id: :metadata_only_difference,
      description:
        "Treat native and canonical output as approximated when the emitted CSS variables match but browser-style metadata differs."
    },
    %{
      id: :stateful_fallback_alignment,
      description:
        "Allow approximated parity when both paths preserve the same visible style output while using different fallback modes."
    }
  ]

  @type workflow ::
          :preview
          | :reference_examples
          | :inspection
          | :styling_inspection
          | :continuity_comparison
          | :export
          | :validation
          | :documentation

  @spec workflows() :: [workflow()]
  def workflows do
    [
      :preview,
      :reference_examples,
      :inspection,
      :styling_inspection,
      :continuity_comparison,
      :export,
      :validation,
      :documentation
    ]
  end

  @spec mix_tasks() :: [String.t()]
  def mix_tasks do
    [
      "mix live_ui.preview",
      "mix live_ui.inspect",
      "mix live_ui.export",
      "mix live_ui.validate"
    ]
  end

  @spec examples() :: [map()]
  def examples do
    Examples.catalog()
  end

  @spec governance_gates() :: map()
  def governance_gates do
    %{
      required_paths: @required_example_paths,
      required_example_families: @required_example_families,
      change_review_expectations: [
        :aligned_focused_example_review,
        :canonical_review_on_aligned_ids,
        :server_authority_review
      ],
      release_readiness_focus: [:example_health, :aligned_inventory, :canonical_review]
    }
  end

  @spec documentation_surface(keyword()) :: map()
  def documentation_surface(opts \\ []) do
    root = Keyword.get(opts, :root, File.cwd!())
    doc_contents = Keyword.get(opts, :doc_contents, %{})

    present_paths =
      @required_docs
      |> Enum.filter(&File.exists?(Path.join(root, &1)))
      |> Enum.sort()

    missing_snippets = missing_doc_snippets(root, doc_contents)
    prohibited_mentions = prohibited_doc_mentions(root, doc_contents)

    %{
      required_paths: @required_docs,
      required_snippets: @required_doc_snippets,
      present_paths: present_paths,
      missing_paths: @required_docs -- present_paths,
      missing_snippets: missing_snippets,
      prohibited_mentions: prohibited_mentions,
      complete?:
        length(present_paths) == length(@required_docs) and
          map_size(missing_snippets) == 0 and prohibited_mentions == []
    }
  end

  @spec validation_report(keyword()) :: map()
  def validation_report(opts \\ []) do
    catalog = Keyword.get(opts, :catalog, examples())
    example_health = example_health_report(catalog)
    example_coverage = example_coverage_report(catalog)
    continuity = continuity_report(catalog)
    transport = transport_report(catalog)
    runtime_authority = runtime_authority_report(catalog)
    documentation_surface = documentation_surface(Keyword.get(opts, :documentation_opts, []))

    report = %{
      example_health: example_health,
      example_coverage: example_coverage,
      continuity: continuity,
      transport: transport,
      runtime_authority: runtime_authority,
      documentation_surface: documentation_surface,
      governance_gates: governance_gates()
    }

    Map.put(report, :release_readiness, release_readiness_report(report))
  end

  @spec validation_summary(map()) :: String.t()
  def validation_summary(report) when is_map(report) do
    [
      "LiveUi validation summary",
      "  examples passing?: #{report.example_health.all_passing?}",
      "  example coverage complete?: #{report.example_coverage.complete?}",
      "  continuity aligned?: #{report.continuity.aligned?}",
      "  browser style aligned?: #{report.continuity.browser_style_aligned?}",
      "  transport sound?: #{report.transport.sound?}",
      "  server authoritative?: #{report.runtime_authority.server_authoritative?}",
      "  documentation complete?: #{report.documentation_surface.complete?}",
      "  release ready?: #{report.release_readiness.ready?}",
      "  failing examples: #{inspect(report.example_health.failing_ids)}",
      "  missing paths: #{inspect(report.example_coverage.missing_paths)}",
      "  missing families: #{inspect(report.example_coverage.missing_families)}",
      "  missing root ids: #{inspect(report.example_coverage.missing_root_example_ids)}",
      "  unexpected ids: #{inspect(report.example_coverage.unexpected_example_ids)}",
      "  continuity failures: #{inspect(report.continuity.failing_ids)}",
      "  transport issues: #{inspect(report.transport.issues)}",
      "  doc snippet gaps: #{inspect(report.documentation_surface.missing_snippets)}",
      "  prohibited doc mentions: #{inspect(report.documentation_surface.prohibited_mentions)}"
    ]
    |> Enum.join("\n")
  end

  @spec preview_example(atom() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def preview_example(id, opts \\ []) do
    inspect_example(id, opts)
  end

  @spec inspect_example(atom() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def inspect_example(id, opts \\ []) do
    with {:ok, example} <- resolve_example(id),
         {:ok, result} <- inspect_example_output(example, opts) do
      {:ok, %{example: example, result: result}}
    end
  end

  @spec compare_example_pair(atom() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def compare_example_pair(id, opts \\ []) do
    with {:ok, example} <- resolve_example(id),
         {:ok, canonical_example, element} <- canonical_review_surface(example),
         {:ok, report} <-
           compare_native_and_canonical(
             example.module,
             element,
             opts
           ) do
      {:ok,
       %{
         example: example,
         native_example: example,
         canonical_example: canonical_example,
         report: report,
         diagnostics:
           Enum.map(report.diagnostics, fn diagnostic ->
             Map.merge(diagnostic, %{
               native_example: example.id,
               canonical_example: canonical_example.id,
               native_families: example.families,
               canonical_families: canonical_example.families
             })
           end)
       }}
    end
  end

  @spec inspect_native(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def inspect_native(screen, opts \\ []) do
    with {:ok, runtime_state} <- LiveUi.Runtime.mount(screen, opts) do
      {:ok, snapshot(runtime_state, :native)}
    end
  end

  @spec inspect_canonical(Element.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def inspect_canonical(%Element{} = element, opts \\ []) do
    with {:ok, runtime_state} <- LiveUi.Runtime.mount_iur(element, opts) do
      {:ok, snapshot(runtime_state, :canonical)}
    end
  end

  @spec compare_native_and_canonical(module(), Element.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def compare_native_and_canonical(screen, %Element{} = element, opts \\ []) do
    native_opts = Keyword.get(opts, :native_opts, [])
    canonical_opts = Keyword.get(opts, :canonical_opts, [])

    with {:ok, native} <- inspect_native(screen, native_opts),
         {:ok, canonical} <- inspect_canonical(element, canonical_opts) do
      native_widgets = MapSet.new(native.widgets)
      canonical_widgets = MapSet.new(canonical.widgets)
      native_tones = MapSet.new(native.tones)
      canonical_tones = MapSet.new(canonical.tones)
      browser_style = compare_browser_style_entries(native.entries, canonical.entries)

      native_only_widgets =
        MapSet.difference(native_widgets, canonical_widgets) |> MapSet.to_list() |> Enum.sort()

      canonical_only_widgets =
        MapSet.difference(canonical_widgets, native_widgets) |> MapSet.to_list() |> Enum.sort()

      shared_widgets =
        MapSet.intersection(native_widgets, canonical_widgets) |> MapSet.to_list() |> Enum.sort()

      shared_tones =
        MapSet.intersection(native_tones, canonical_tones) |> MapSet.to_list() |> Enum.sort()

      diagnostics =
        []
        |> maybe_add_diagnostic(:native_only_behavior, native_only_widgets)
        |> maybe_add_diagnostic(:canonical_only_behavior, canonical_only_widgets)
        |> maybe_add_browser_style_diagnostics(browser_style)

      {:ok,
       %{
         native: native,
         canonical: canonical,
         shared_widgets: shared_widgets,
         native_only_widgets: native_only_widgets,
         canonical_only_widgets: canonical_only_widgets,
         shared_tones: shared_tones,
         browser_style: browser_style,
         diagnostics: diagnostics,
         continuity: %{
           widgets_aligned?: native_only_widgets == [] and canonical_only_widgets == [],
           tone_overlap?: shared_tones != [],
           runtime_model_aligned?:
             native.server_authoritative? and canonical.server_authoritative?,
           browser_style_aligned?: browser_style.aligned?,
           browser_style_approximated?: browser_style.approximated_ids != []
         }
       }}
    end
  end

  @spec namespace() :: module()
  def namespace, do: __MODULE__

  defp snapshot(%State{} = runtime_state, path) do
    html =
      runtime_state
      |> render_runtime()
      |> case do
        rendered when is_binary(rendered) -> rendered
        rendered -> Phoenix.HTML.Safe.to_iodata(rendered) |> IO.iodata_to_binary()
      end

    entries = widget_entries(html)
    browser_style_nodes = browser_style_entry_reports(entries)

    %{
      path: path,
      mode: runtime_state.mode,
      screen: State.screen_id(runtime_state),
      event_routes: Map.keys(runtime_state.event_routes) |> Enum.sort(),
      bridge_hooks: Enum.sort(runtime_state.bridge_hooks),
      widgets: Enum.map(entries, & &1.widget) |> Enum.uniq(),
      tones:
        entries |> Enum.map(& &1.tone) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      variants:
        entries |> Enum.map(& &1.variant) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      states:
        entries |> Enum.map(& &1.state) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      entries: entries,
      browser_style_nodes: browser_style_nodes,
      browser_style: browser_style_summary(browser_style_nodes),
      html: html,
      server_authoritative?: true
    }
  end

  defp render_runtime(%State{} = runtime_state) do
    # Use render_component/3 from LiveViewTest to properly handle LiveComponents
    # The direct .render/1 approach doesn't work when the rendered content
    # contains nested LiveComponents (our widget components)
    runtime_id = "tooling-runtime-#{System.unique_integer([:positive, :monotonic])}"

    render_component(LiveUi.Runtime.component(), %{
      id: runtime_id,
      runtime_state: runtime_state
    })
  end

  defp widget_entries(html) do
    ~r/<[^>]*data-live-ui-widget="[^"]+"[^>]*>/
    |> Regex.scan(html)
    |> Enum.map(fn [tag] ->
      %{
        id: attribute(tag, "id"),
        widget: attribute(tag, "data-live-ui-widget"),
        tone: attribute(tag, "data-live-ui-tone"),
        variant: attribute(tag, "data-live-ui-variant"),
        state: attribute(tag, "data-live-ui-state"),
        class: attribute(tag, "class"),
        browser_style: browser_style_payload(tag)
      }
    end)
  end

  defp browser_style_payload(tag) do
    %{
      mode: attribute(tag, "data-live-ui-browser-style"),
      fallback: attribute(tag, "data-live-ui-browser-fallback"),
      realized_fields: csv_attribute(tag, "data-live-ui-realized-style-fields"),
      semantic_fields: csv_attribute(tag, "data-live-ui-semantic-style-fields"),
      unsupported_fields: csv_attribute(tag, "data-live-ui-unsupported-style-fields"),
      ignored_fields: csv_attribute(tag, "data-live-ui-ignored-style-fields"),
      unresolved_token_refs: csv_attribute(tag, "data-live-ui-unresolved-token-refs"),
      unresolved_roles: csv_attribute(tag, "data-live-ui-unresolved-style-roles"),
      css_vars: css_var_map(attribute(tag, "style"))
    }
  end

  defp browser_style_entry_reports(entries) do
    Enum.map(entries, fn entry ->
      browser_style = Map.get(entry, :browser_style, %{})

      %{
        id: entry.id,
        widget: entry.widget,
        tone: entry.tone,
        variant: entry.variant,
        state: entry.state,
        class: entry.class,
        mode: Map.get(browser_style, :mode),
        fallback: Map.get(browser_style, :fallback),
        realized_fields: Map.get(browser_style, :realized_fields, []),
        semantic_fields: Map.get(browser_style, :semantic_fields, []),
        unsupported_fields: Map.get(browser_style, :unsupported_fields, []),
        ignored_fields: Map.get(browser_style, :ignored_fields, []),
        unresolved_token_refs: Map.get(browser_style, :unresolved_token_refs, []),
        unresolved_roles: Map.get(browser_style, :unresolved_roles, []),
        css_vars: Map.get(browser_style, :css_vars, %{}),
        css_var_keys:
          browser_style
          |> Map.get(:css_vars, %{})
          |> Map.keys()
          |> Enum.sort()
      }
    end)
  end

  defp browser_style_summary(entry_reports) do
    unresolved_reference_entry_ids =
      entry_reports
      |> Enum.filter(&(&1.unresolved_token_refs != [] or &1.unresolved_roles != []))
      |> Enum.map(& &1.id)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    %{
      modes:
        entry_reports
        |> Enum.map(& &1.mode)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort(),
      fallbacks:
        entry_reports
        |> Enum.map(& &1.fallback)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort(),
      realized_fields:
        entry_reports
        |> Enum.flat_map(& &1.realized_fields)
        |> Enum.uniq()
        |> Enum.sort(),
      semantic_fields:
        entry_reports
        |> Enum.flat_map(& &1.semantic_fields)
        |> Enum.uniq()
        |> Enum.sort(),
      unsupported_fields:
        entry_reports
        |> Enum.flat_map(& &1.unsupported_fields)
        |> Enum.uniq()
        |> Enum.sort(),
      ignored_fields:
        entry_reports
        |> Enum.flat_map(& &1.ignored_fields)
        |> Enum.uniq()
        |> Enum.sort(),
      unresolved_token_refs:
        entry_reports
        |> Enum.flat_map(& &1.unresolved_token_refs)
        |> Enum.uniq()
        |> Enum.sort(),
      unresolved_roles:
        entry_reports
        |> Enum.flat_map(& &1.unresolved_roles)
        |> Enum.uniq()
        |> Enum.sort(),
      css_var_keys:
        entry_reports
        |> Enum.flat_map(& &1.css_var_keys)
        |> Enum.uniq()
        |> Enum.sort(),
      mode_counts: count_values(entry_reports, & &1.mode),
      fallback_counts: count_values(entry_reports, & &1.fallback),
      unsupported_entry_ids:
        entry_reports
        |> Enum.filter(&(&1.unsupported_fields != []))
        |> Enum.map(& &1.id)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort(),
      ignored_entry_ids:
        entry_reports
        |> Enum.filter(&(&1.ignored_fields != []))
        |> Enum.map(& &1.id)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort(),
      unresolved_reference_entry_ids: unresolved_reference_entry_ids,
      semantic_only_entry_ids:
        entry_reports
        |> Enum.filter(&(&1.mode == "semantic_only"))
        |> Enum.map(& &1.id)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort(),
      mixed_entry_ids:
        entry_reports
        |> Enum.filter(&(&1.mode == "mixed"))
        |> Enum.map(& &1.id)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort(),
      realized_entry_ids:
        entry_reports
        |> Enum.filter(&(&1.mode == "realized"))
        |> Enum.map(& &1.id)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort(),
      entry_reports: entry_reports
    }
  end

  defp compare_browser_style_entries(native_entries, canonical_entries) do
    native_by_id = entries_by_id(native_entries)
    canonical_by_id = entries_by_id(canonical_entries)

    native_ids = Map.keys(native_by_id) |> Enum.sort()
    canonical_ids = Map.keys(canonical_by_id) |> Enum.sort()

    shared_ids =
      MapSet.intersection(MapSet.new(native_ids), MapSet.new(canonical_ids))
      |> MapSet.to_list()
      |> Enum.sort()

    {entry_reports, shape_mismatches} =
      Enum.reduce(shared_ids, {[], []}, fn id, {reports, mismatches} ->
        native_entry = Map.fetch!(native_by_id, id)
        canonical_entry = Map.fetch!(canonical_by_id, id)

        if native_entry.widget == canonical_entry.widget do
          {[compare_browser_entry(native_entry, canonical_entry) | reports], mismatches}
        else
          {reports,
           [
             %{
               id: id,
               native_widget: native_entry.widget,
               canonical_widget: canonical_entry.widget
             }
             | mismatches
           ]}
        end
      end)

    entry_reports = Enum.sort_by(entry_reports, & &1.id)
    shape_mismatches = Enum.sort_by(shape_mismatches, & &1.id)
    drift_ids = entry_reports |> Enum.filter(&(&1.status == :drift)) |> Enum.map(& &1.id)

    approximated_ids =
      entry_reports |> Enum.filter(&(&1.status == :approximated)) |> Enum.map(& &1.id)

    %{
      aligned?: drift_ids == [] and shape_mismatches == [],
      matched_entry_ids: Enum.map(entry_reports, & &1.id),
      native_only_entry_ids: native_ids -- shared_ids,
      canonical_only_entry_ids: canonical_ids -- shared_ids,
      approximated_ids: approximated_ids,
      drift_ids: drift_ids,
      shape_mismatches: shape_mismatches,
      entry_reports: entry_reports,
      approximation_rules: @browser_style_approximation_rules
    }
  end

  defp compare_browser_entry(native_entry, canonical_entry) do
    native_browser = Map.get(native_entry, :browser_style, %{})
    canonical_browser = Map.get(canonical_entry, :browser_style, %{})

    native_css_vars = Map.get(native_browser, :css_vars, %{})
    canonical_css_vars = Map.get(canonical_browser, :css_vars, %{})

    shared_css_keys =
      Map.keys(native_css_vars)
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(Map.keys(canonical_css_vars)))
      |> MapSet.to_list()
      |> Enum.sort()

    conflicting_css_vars =
      Enum.reduce(shared_css_keys, [], fn key, acc ->
        native_value = Map.get(native_css_vars, key)
        canonical_value = Map.get(canonical_css_vars, key)

        if native_value == canonical_value do
          acc
        else
          [%{key: key, native: native_value, canonical: canonical_value} | acc]
        end
      end)
      |> Enum.reverse()

    native_only_css_vars = Map.keys(native_css_vars) -- shared_css_keys
    canonical_only_css_vars = Map.keys(canonical_css_vars) -- shared_css_keys

    realized_field_drift =
      symmetric_difference(
        Map.get(native_browser, :realized_fields, []),
        Map.get(canonical_browser, :realized_fields, [])
      )

    semantic_field_drift =
      symmetric_difference(
        Map.get(native_browser, :semantic_fields, []),
        Map.get(canonical_browser, :semantic_fields, [])
      )

    unsupported_field_drift =
      symmetric_difference(
        Map.get(native_browser, :unsupported_fields, []),
        Map.get(canonical_browser, :unsupported_fields, [])
      )

    ignored_field_drift =
      symmetric_difference(
        Map.get(native_browser, :ignored_fields, []),
        Map.get(canonical_browser, :ignored_fields, [])
      )

    unresolved_token_ref_drift =
      symmetric_difference(
        Map.get(native_browser, :unresolved_token_refs, []),
        Map.get(canonical_browser, :unresolved_token_refs, [])
      )

    unresolved_role_drift =
      symmetric_difference(
        Map.get(native_browser, :unresolved_roles, []),
        Map.get(canonical_browser, :unresolved_roles, [])
      )

    fallback_mismatch? =
      Map.get(native_browser, :fallback) != Map.get(canonical_browser, :fallback)

    mode_mismatch? = Map.get(native_browser, :mode) != Map.get(canonical_browser, :mode)

    status =
      cond do
        conflicting_css_vars != [] or native_only_css_vars != [] or canonical_only_css_vars != [] or
          unsupported_field_drift != [] or ignored_field_drift != [] or fallback_mismatch? ->
          :drift

        mode_mismatch? or realized_field_drift != [] or semantic_field_drift != [] ->
          :approximated

        true ->
          :aligned
      end

    %{
      id: native_entry.id,
      widget: native_entry.widget,
      status: status,
      native: browser_entry_summary(native_browser),
      canonical: browser_entry_summary(canonical_browser),
      conflicting_css_vars: conflicting_css_vars,
      native_only_css_vars: Enum.sort(native_only_css_vars),
      canonical_only_css_vars: Enum.sort(canonical_only_css_vars),
      realized_field_drift: realized_field_drift,
      semantic_field_drift: semantic_field_drift,
      unsupported_field_drift: unsupported_field_drift,
      ignored_field_drift: ignored_field_drift,
      unresolved_token_ref_drift: unresolved_token_ref_drift,
      unresolved_role_drift: unresolved_role_drift,
      fallback_mismatch?: fallback_mismatch?,
      mode_mismatch?: mode_mismatch?
    }
  end

  defp entries_by_id(entries) do
    entries
    |> Enum.reject(&is_nil(&1.id))
    |> Map.new(fn entry -> {entry.id, entry} end)
  end

  defp browser_entry_summary(browser_style) do
    %{
      mode: Map.get(browser_style, :mode),
      fallback: Map.get(browser_style, :fallback),
      realized_fields: Map.get(browser_style, :realized_fields, []),
      semantic_fields: Map.get(browser_style, :semantic_fields, []),
      unsupported_fields: Map.get(browser_style, :unsupported_fields, []),
      ignored_fields: Map.get(browser_style, :ignored_fields, []),
      unresolved_token_refs: Map.get(browser_style, :unresolved_token_refs, []),
      unresolved_roles: Map.get(browser_style, :unresolved_roles, []),
      css_vars: Map.get(browser_style, :css_vars, %{})
    }
  end

  defp csv_attribute(tag, name) do
    case attribute(tag, name) do
      nil -> []
      value -> String.split(value, ",", trim: true) |> Enum.sort()
    end
  end

  defp css_var_map(nil), do: %{}

  defp css_var_map(style) do
    style
    |> String.split(";", trim: true)
    |> Enum.reduce(%{}, fn declaration, acc ->
      case String.split(declaration, ":", parts: 2) do
        [key, value] ->
          key = String.trim(key)
          value = String.trim(value)

          if String.starts_with?(key, "--live-ui-") and value != "" do
            Map.put(acc, key, value)
          else
            acc
          end

        _other ->
          acc
      end
    end)
  end

  defp attribute(tag, name) do
    case Regex.run(~r/(?:^|\s)#{Regex.escape(name)}="([^"]+)"/, tag, capture: :all_but_first) do
      [value] -> value
      _ -> nil
    end
  end

  defp symmetric_difference(left, right) do
    left = MapSet.new(left)
    right = MapSet.new(right)

    left
    |> MapSet.symmetric_difference(right)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp count_values(values, mapper) do
    values
    |> Enum.map(mapper)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
  end

  defp maybe_add_diagnostic(diagnostics, _reason, []), do: diagnostics

  defp maybe_add_diagnostic(diagnostics, reason, widgets) do
    diagnostics ++ [%{reason: reason, widgets: widgets}]
  end

  defp maybe_add_browser_style_diagnostics(diagnostics, %{
         drift_ids: [],
         shape_mismatches: [],
         approximated_ids: []
       }) do
    diagnostics
  end

  defp maybe_add_browser_style_diagnostics(diagnostics, browser_style) do
    diagnostics
    |> maybe_add_browser_style_drift(browser_style)
    |> maybe_add_browser_style_approximation(browser_style)
  end

  defp maybe_add_browser_style_drift(diagnostics, %{drift_ids: [], shape_mismatches: []}),
    do: diagnostics

  defp maybe_add_browser_style_drift(diagnostics, browser_style) do
    diagnostics ++
      [
        %{
          reason: :browser_style_drift,
          entry_ids: browser_style.drift_ids,
          shape_mismatches: browser_style.shape_mismatches
        }
      ]
  end

  defp maybe_add_browser_style_approximation(diagnostics, %{approximated_ids: []}),
    do: diagnostics

  defp maybe_add_browser_style_approximation(diagnostics, browser_style) do
    diagnostics ++
      [
        %{
          reason: :browser_style_approximation,
          entry_ids: browser_style.approximated_ids,
          rules: browser_style.approximation_rules
        }
      ]
  end

  defp example_health_report(catalog) do
    results =
      Enum.map(catalog, fn example ->
        case inspect_example(example.id) do
          {:ok, inspection} ->
            %{id: example.id, path: example.path, ok?: true, result: inspection.result}

          {:error, reason} ->
            %{id: example.id, path: example.path, ok?: false, reason: reason}
        end
      end)

    failing_ids =
      results
      |> Enum.reject(& &1.ok?)
      |> Enum.map(& &1.id)

    %{
      total: length(results),
      results: results,
      failing_ids: failing_ids,
      all_passing?: failing_ids == []
    }
  end

  defp example_coverage_report(catalog) do
    repository_example_ids = Examples.repository_example_ids()
    aligned_ids = Enum.map(catalog, & &1.id) |> Enum.sort()

    present_paths =
      catalog
      |> Enum.map(& &1.path)
      |> Enum.uniq()
      |> Enum.sort()

    present_families =
      catalog
      |> Enum.flat_map(& &1.families)
      |> Enum.uniq()
      |> Enum.sort()

    missing_paths = @required_example_paths -- present_paths
    missing_families = @required_example_families -- present_families
    missing_root_example_ids = repository_example_ids -- aligned_ids
    unexpected_example_ids = aligned_ids -- repository_example_ids

    %{
      present_paths: present_paths,
      missing_paths: missing_paths,
      present_families: present_families,
      missing_families: missing_families,
      repository_example_ids: repository_example_ids,
      aligned_ids: aligned_ids,
      missing_root_example_ids: missing_root_example_ids,
      unexpected_example_ids: unexpected_example_ids,
      canonical_review_ids:
        catalog
        |> Enum.filter(&get_in(&1, [:runtime_obligations, :canonical_review?]))
        |> Enum.map(& &1.id)
        |> Enum.sort(),
      complete?:
        missing_paths == [] and
          missing_families == [] and
          missing_root_example_ids == [] and
          unexpected_example_ids == []
    }
  end

  defp continuity_report(catalog) do
    targets =
      Enum.filter(catalog, fn example ->
        get_in(example, [:runtime_obligations, :canonical_review?])
      end)

    results =
      Enum.map(targets, fn example ->
        case compare_example_pair(example.id) do
          {:ok, comparison} ->
            %{
              id: example.id,
              ok?: true,
              report: comparison.report,
              diagnostics: comparison.diagnostics
            }

          {:error, reason} ->
            %{id: example.id, ok?: false, reason: reason, diagnostics: [%{reason: reason}]}
        end
      end)

    failing_ids =
      results
      |> Enum.reject(& &1.ok?)
      |> Enum.map(& &1.id)

    %{
      total: length(results),
      results: results,
      failing_ids: failing_ids,
      browser_style_aligned?: Enum.all?(results, & &1.ok?),
      aligned?: failing_ids == []
    }
  end

  defp transport_report(catalog) do
    targets =
      Enum.filter(catalog, fn example ->
        get_in(example, [:runtime_obligations, :transport_review?]) and
          Examples.canonical_review_supported?(example.id)
      end)

    results =
      Enum.map(targets, fn example ->
        case compare_example_pair(example.id) do
          {:ok, comparison} ->
            %{
              id: example.id,
              sound?: true,
              diagnostics: comparison.diagnostics
            }

          {:error, reason} ->
            %{id: example.id, sound?: false, diagnostics: [%{reason: reason}]}
        end
      end)

    issues =
      results
      |> Enum.reject(& &1.sound?)
      |> Enum.map(& &1.id)

    %{
      sound?: issues == [],
      issues: issues,
      results: results
    }
  end

  defp runtime_authority_report(catalog) do
    results =
      Enum.map(catalog, fn example ->
        case inspect_example(example.id) do
          {:ok, inspection} ->
            %{
              id: example.id,
              server_authoritative?: Map.get(inspection.result, :server_authoritative?, false)
            }

          {:error, _reason} ->
            %{id: example.id, server_authoritative?: false}
        end
      end)

    %{
      results: results,
      server_authoritative?: Enum.all?(results, & &1.server_authoritative?)
    }
  end

  defp release_readiness_report(report) do
    criteria = [
      gate(
        :example_health,
        "All maintained examples inspect successfully.",
        report.example_health.all_passing?
      ),
      gate(
        :example_coverage,
        "Maintained examples cover the repository inventory, required families, and aligned example path.",
        report.example_coverage.complete?
      ),
      gate(
        :continuity,
        "Canonical comparison remains available on aligned example ids where review requires it.",
        report.continuity.aligned?
      ),
      gate(
        :transport,
        "Transport-facing aligned examples still expose reviewable canonical diagnostics.",
        report.transport.sound?
      ),
      gate(
        :runtime_authority,
        "Inspectable native and canonical paths remain server-authoritative.",
        report.runtime_authority.server_authoritative?
      ),
      gate(
        :documentation,
        "Maintainer-facing docs describe aligned example review and omit the retired demo/workbench.",
        report.documentation_surface.complete?
      )
    ]

    %{
      ready?: Enum.all?(criteria, & &1.passed?),
      criteria: criteria,
      required_change_review: governance_gates().change_review_expectations
    }
  end

  defp gate(id, description, passed?) do
    %{id: id, description: description, passed?: passed?}
  end

  defp resolve_example(id) do
    case Examples.find(id) do
      {:ok, example} -> {:ok, example}
      :error -> {:error, :unknown_example}
    end
  end

  defp inspect_example_output(example, opts) do
    case Keyword.get(opts, :review_mode, :native) do
      :native ->
        inspect_native(example.module, opts)

      :canonical ->
        with {:ok, element} <- Examples.canonical_element(example.id) do
          inspect_canonical(element, opts)
        end

      :comparison ->
        with {:ok, comparison} <- compare_example_pair(example.id, opts) do
          {:ok, comparison.report}
        end

      mode ->
        {:error, {:unsupported_review_mode, mode}}
    end
  end

  defp canonical_review_surface(example) do
    with {:ok, canonical_example} <- Examples.canonical_metadata(example.id),
         {:ok, element} <- Examples.canonical_element(example.id) do
      {:ok,
       Map.merge(canonical_example, %{
         id: example.id,
         title: "#{example.title} Canonical Review",
         families: example.families
       }), element}
    end
  end

  defp missing_doc_snippets(root, doc_contents) do
    Enum.reduce(@required_doc_snippets, %{}, fn {path, snippets}, acc ->
      content = doc_content(root, path, doc_contents)

      missing = Enum.reject(snippets, &String.contains?(content, &1))

      if missing == [] do
        acc
      else
        Map.put(acc, path, missing)
      end
    end)
  end

  defp prohibited_doc_mentions(root, doc_contents) do
    for path <- @required_docs,
        {label, pattern} <- @prohibited_doc_patterns,
        content = doc_content(root, path, doc_contents),
        Regex.match?(pattern, content) do
      %{path: path, label: label}
    end
  end

  defp doc_content(_root, path, doc_contents) when is_map_key(doc_contents, path) do
    Map.fetch!(doc_contents, path)
  end

  defp doc_content(root, path, _doc_contents) do
    root
    |> Path.join(path)
    |> File.read!()
  end
end
