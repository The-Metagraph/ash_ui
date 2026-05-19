defmodule DesktopUi.Validate do
  @moduledoc """
  Coverage, runtime, transport, artifact, and release-readiness validation
  workflows for `desktop_ui`.
  """

  @type mode :: :summary | :strict
  @required_guides [
    "README.md",
    "guides/runtime_backbone.md",
    "guides/native_runtime_and_examples.md",
    "guides/canonical_rendering_and_transport.md",
    "guides/styling_platforms_and_artifacts.md",
    "guides/maintainer_workflows.md"
  ]
  @required_traceability_targets [
    ".spec/specs/architecture.spec.md",
    ".spec/specs/platform_runtimes.spec.md",
    ".spec/specs/signal_transport.spec.md",
    ".spec/specs/desktop_ui/package.spec.md",
    ".spec/specs/desktop_ui/structure.spec.md",
    ".spec/specs/desktop_ui/native_widgets.spec.md",
    ".spec/specs/desktop_ui/runtime.spec.md",
    ".spec/specs/desktop_ui/sdl3_runtime_rendering.spec.md",
    ".spec/specs/desktop_ui/iur_renderer.spec.md",
    ".spec/specs/desktop_ui/transport.spec.md",
    ".spec/specs/desktop_ui/platform_artifacts.spec.md",
    ".spec/specs/desktop_ui/tooling.spec.md",
    ".spec/planning/desktop_ui/spec-traceability.json",
    ".spec/planning/desktop_ui/spec-traceability.md"
  ]
  @required_root_subjects [
    ".spec/specs/architecture.spec.md",
    ".spec/specs/platform_runtimes.spec.md",
    ".spec/specs/signal_transport.spec.md"
  ]
  @required_package_subjects [
    ".spec/specs/desktop_ui/package.spec.md",
    ".spec/specs/desktop_ui/structure.spec.md",
    ".spec/specs/desktop_ui/native_widgets.spec.md",
    ".spec/specs/desktop_ui/runtime.spec.md",
    ".spec/specs/desktop_ui/sdl3_runtime_rendering.spec.md",
    ".spec/specs/desktop_ui/iur_renderer.spec.md",
    ".spec/specs/desktop_ui/transport.spec.md",
    ".spec/specs/desktop_ui/platform_artifacts.spec.md",
    ".spec/specs/desktop_ui/tooling.spec.md"
  ]

  @spec example_coverage() :: map()
  def example_coverage do
    matrix = DesktopUi.Examples.coverage_matrix()

    checks = [
      check(:native_examples_present, DesktopUi.Examples.native_examples() != [], []),
      check(:canonical_examples_present, DesktopUi.Examples.canonical_examples() != [], []),
      check(:mixed_examples_present, DesktopUi.Examples.mixed_examples() != [], []),
      check(
        :foundational_review_present,
        Map.has_key?(matrix.workflows, :foundational_review),
        []
      ),
      check(:advanced_review_present, Map.has_key?(matrix.workflows, :advanced_review), []),
      check(:transport_review_present, Map.has_key?(matrix.workflows, :transport_review), []),
      check(:style_review_present, Map.has_key?(matrix.workflows, :style_review), []),
      check(
        :native_widget_families_present,
        Enum.all?(
          [:action, :content, :data, :input, :navigation, :operational, :visualization, :window],
          &(&1 in DesktopUi.Widgets.families())
        ),
        %{families: DesktopUi.Widgets.families()}
      ),
      check(
        :renderer_supports_key_canonical_kinds,
        Enum.all?(
          [:window, :table, :command_palette, :text_input, :button],
          &(&1 in DesktopUi.Renderer.supported_kinds())
        ),
        %{supported_kinds: DesktopUi.Renderer.supported_kinds()}
      ),
      check(
        :renderer_supports_all_iur_kinds,
        iur_widget_coverage_complete?(),
        %{
          expected_count: 47,
          actual_count: length(DesktopUi.Renderer.supported_kinds()),
          supported_kinds: DesktopUi.Renderer.supported_kinds()
        }
      )
    ]

    report(:example_coverage, checks)
  end

  @spec runtime_behavior() :: map()
  def runtime_behavior do
    foundational = DesktopUi.Examples.foundational_comparison()
    advanced = DesktopUi.Examples.advanced_comparison()
    transport = DesktopUi.Examples.transport_comparison()
    normalized = DesktopUi.Examples.normalized_input_comparison()
    styled = DesktopUi.Examples.styled_comparison()

    checks = [
      check(
        :foundational_continuity,
        foundational.parity.focus_order_match?,
        foundational.parity
      ),
      check(:advanced_continuity, advanced.parity.shared_runtime_backbone?, advanced.parity),
      check(
        :transport_meaning_preserved,
        transport.parity.boundary_signal_types_match?,
        transport.parity
      ),
      check(
        :normalized_inputs_bounded,
        normalized.parity.platform_variation_bounded?,
        normalized.parity
      ),
      check(
        :styled_continuity_preserved,
        styled.parity.widget_identity_match? and styled.parity.style_resolution_match? and
          styled.parity.platform_semantics_match?,
        styled.parity
      )
    ]

    report(:runtime_behavior, checks)
  end

  @spec transport_validation() :: map()
  def transport_validation do
    native_event = [
      platform_target: :linux,
      input_family: :shortcut,
      shortcut: "ctrl-r",
      intent: :refresh_workspace,
      widget_id: "refresh-command",
      runtime_id: "desktop-ui:transport",
      screen: "transport-review"
    ]

    {:ok, translation} = DesktopUi.Transport.from_native_event(native_event)

    checks = [
      check(
        :native_event_validation,
        DesktopUi.Transport.validate_native_event(native_event) == :ok,
        []
      ),
      check(
        :translation_validation,
        DesktopUi.Transport.validate_translation(translation) == :ok,
        []
      ),
      check(
        :boundary_signal_validation,
        DesktopUi.Transport.validate_boundary_signal(translation.signal) == :ok,
        []
      ),
      check(
        :no_platform_leakage,
        DesktopUi.Transport.Diagnostics.validate_translation(translation) == :ok,
        []
      )
    ]

    report(:transport_validation, checks)
  end

  @spec artifact_validation() :: map()
  def artifact_validation do
    diagnostics = DesktopUi.Artifacts.diagnostics()
    boundary_policy = DesktopUi.Artifacts.boundary_policy()
    packaging = DesktopUi.Package.diagnostics()

    checks = [
      check(:all_targets_present, diagnostics.targets == [:windows, :macos, :linux], diagnostics),
      check(:no_invalid_targets, diagnostics.invalid_targets == [], diagnostics.invalid_targets),
      check(
        :boundary_policy_preserves_runtime_semantics,
        diagnostics.boundary_policy == boundary_policy and
          boundary_policy.transport_semantics_preserved,
        %{expected: boundary_policy, actual: diagnostics.boundary_policy}
      ),
      check(
        :explicit_packaging_per_target,
        Enum.all?(diagnostics.targets, &(DesktopUi.Artifacts.workflow(&1).packaging != [])),
        diagnostics.workflows
      ),
      check(
        :package_surface_present,
        packaging.validation_state == :target_packaging_surface_ready,
        packaging
      ),
      check(
        :package_artifact_paths_present,
        Enum.all?(packaging.target_packages, fn target ->
          is_binary(target.archive_path) and
            (is_binary(target.bundle_path) or is_binary(target.payload_root))
        end),
        packaging.target_packages
      ),
      check(
        :fallback_warnings_explicit,
        Enum.all?(packaging.target_packages, fn target ->
          target.compiled_host_included? or
            (:compiled_host_missing in target.warnings and :review_bundle_only in target.warnings)
        end),
        packaging.target_packages
      )
    ]

    report(:artifact_validation, checks)
  end

  @spec tooling_surface() :: map()
  def tooling_surface do
    run_catalog = DesktopUi.Tooling.run_catalog()

    checks = [
      check(
        :inspect_surface_present,
        DesktopUi.Inspect in DesktopUi.Tooling.preview_surfaces(),
        []
      ),
      check(:validate_surface_present, exported?(DesktopUi.Validate, :release_readiness, 1), []),
      check(
        :example_preview_workflow_present,
        :example_preview in DesktopUi.Tooling.workflows(),
        %{workflows: DesktopUi.Tooling.workflows()}
      ),
      check(
        :package_validation_workflow_present,
        :package_validation in DesktopUi.Tooling.workflows(),
        %{workflows: DesktopUi.Tooling.workflows()}
      ),
      check(
        :artifact_packaging_workflow_present,
        :artifact_packaging_review in DesktopUi.Tooling.workflows(),
        %{workflows: DesktopUi.Tooling.workflows()}
      ),
      check(
        :host_execution_workflow_present,
        :host_execution_review in DesktopUi.Tooling.workflows(),
        %{workflows: DesktopUi.Tooling.workflows()}
      ),
      check(
        :interactive_native_review_workflow_present,
        :interactive_native_review in DesktopUi.Tooling.workflows(),
        %{workflows: DesktopUi.Tooling.workflows()}
      ),
      check(
        :mix_task_surface_present,
        Enum.all?(
          [
            "mix desktop_ui.inspect",
            "mix desktop_ui.build",
            "mix desktop_ui.package",
            "mix desktop_ui.build_host",
            "mix desktop_ui.run",
            "mix desktop_ui.validate"
          ],
          &Enum.any?(DesktopUi.Tooling.mix_tasks(), fn task -> String.starts_with?(task, &1) end)
        ),
        %{mix_tasks: DesktopUi.Tooling.mix_tasks()}
      ),
      check(
        :run_catalog_reports_backend_diagnostics,
        is_map(run_catalog.execution) and
          is_boolean(run_catalog.execution.visible_runner_ready?) and
          is_boolean(run_catalog.execution.protocol_launch_ready?) and
          run_catalog.execution.renderer_completeness == :widget_complete_interactive and
          is_boolean(run_catalog.execution.interactive_visible_execution_ready?) and
          is_map(run_catalog.execution.manual_review_workflow) and
          is_atom(run_catalog.execution.text.active_mode) and
          is_atom(run_catalog.execution.images.active_mode) and
          run_catalog.execution.fallback_backend == :elixir_host and
          is_list(run_catalog.execution.target_packages),
        %{execution: run_catalog.execution}
      )
    ]

    report(:tooling_surface, checks)
  end

  @spec host_execution_surface() :: map()
  def host_execution_surface do
    native_launch = DesktopUi.Inspect.host_execution(:native_foundational)
    canonical_launch = DesktopUi.Inspect.host_execution(:canonical_foundational)
    run_execution = DesktopUi.Inspect.run_execution(:native_foundational, linger_ms: 1)
    text_contract = DesktopUi.Sdl3.Text.contract()
    image_contract = DesktopUi.Sdl3.Images.contract()
    capabilities = DesktopUi.Sdl3.Capabilities.detect()
    text_support = DesktopUi.Sdl3.Text.native_support(capabilities)
    image_support = DesktopUi.Sdl3.Images.native_support(capabilities)

    checks = [
      check(
        :native_host_execution_ready,
        host_execution_ok?(native_launch),
        %{native: host_execution_details(native_launch)}
      ),
      check(
        :canonical_host_execution_ready,
        host_execution_ok?(canonical_launch),
        %{canonical: host_execution_details(canonical_launch)}
      ),
      check(
        :resource_contracts_report_cache_boundaries,
        Enum.all?([text_contract, image_contract], &Map.get(&1, :host_caching, false)),
        %{text: text_contract, images: image_contract}
      ),
      check(
        :event_roundtrip_surface_present,
        exported?(DesktopUi.Sdl3.App, :dispatch_native_events, 4) and
          exported?(DesktopUi.Sdl3.App, :prepare_text_resource, 3) and
          exported?(DesktopUi.Sdl3.App, :prepare_image_resource, 3),
        %{
          app_module: DesktopUi.Sdl3.App,
          event_contract: DesktopUi.Sdl3.Events.contract()
        }
      ),
      check(
        :run_execution_surface_present,
        run_execution_ok?(run_execution),
        %{run_execution: run_execution_details(run_execution)}
      ),
      check(
        :run_execution_reports_interaction_diagnostics,
        run_execution_interaction_ok?(run_execution),
        %{run_execution: run_execution_details(run_execution)}
      ),
      check(
        :native_resource_support_reported,
        Map.get(text_support, :requests_bounded_when_missing?, false) and
          Map.get(image_support, :requests_bounded_when_missing?, false) and
          is_atom(Map.get(text_support, :active_mode)) and
          is_atom(Map.get(image_support, :active_mode)),
        %{
          text: text_support,
          images: image_support
        }
      )
    ]

    report(:host_execution_surface, checks)
  end

  @spec sdl3_adapter_surface() :: map()
  def sdl3_adapter_surface do
    adapter_surface = DesktopUi.Inspection.sdl3_adapter_surface()

    checks = [
      check(
        :sdl3_modules_present,
        Enum.all?(
          [
            DesktopUi.Sdl3,
            DesktopUi.Sdl3.App,
            DesktopUi.Sdl3.Host,
            DesktopUi.Sdl3.PortHost,
            DesktopUi.Sdl3.NativeBuild,
            DesktopUi.Sdl3.Capabilities,
            DesktopUi.Sdl3.Protocol,
            DesktopUi.Sdl3.Lifecycle,
            DesktopUi.Sdl3.Window,
            DesktopUi.Sdl3.RenderPlan,
            DesktopUi.Sdl3.FrameEncoder,
            DesktopUi.Sdl3.FrameScript,
            DesktopUi.Sdl3.InteractionScript,
            DesktopUi.Sdl3.VisibleRunner,
            DesktopUi.Sdl3.Renderer,
            DesktopUi.Sdl3.Events,
            DesktopUi.Sdl3.Text,
            DesktopUi.Sdl3.Images
          ],
          &Code.ensure_loaded?/1
        ),
        %{modules: DesktopUi.Sdl3.modules()}
      ),
      check(
        :host_boundary_present,
        adapter_surface.validation_state.host == :port_host_ready and
          adapter_surface.host.transport == :port,
        %{host: adapter_surface.host, validation_state: adapter_surface.validation_state}
      ),
      check(
        :native_build_surface_present,
        adapter_surface.validation_state.native_build == :native_build_surface_ready and
          is_binary(adapter_surface.native_build.executable_path),
        %{native_build: adapter_surface.native_build}
      ),
      check(
        :capability_detection_surface_present,
        adapter_surface.validation_state.capabilities == :capability_detection_ready and
          adapter_surface.capabilities.backend.fallback == :elixir_host,
        %{capabilities: adapter_surface.capabilities}
      ),
      check(
        :framed_protocol_present,
        adapter_surface.validation_state.protocol == :framed_protocol_ready and
          adapter_surface.protocol.framing == :desktop_ui_sdl3_frame,
        %{protocol: adapter_surface.protocol, validation_state: adapter_surface.validation_state}
      ),
      check(
        :frame_encoding_present,
        adapter_surface.validation_state.frame_encoder == :frame_encoding_ready and
          adapter_surface.frame_encoder.payload_family == :frame,
        %{
          frame_encoder: adapter_surface.frame_encoder,
          validation_state: adapter_surface.validation_state
        }
      ),
      check(
        :frame_script_present,
        adapter_surface.validation_state.frame_script == :frame_script_ready and
          adapter_surface.frame_script.format == :tab_separated_key_values,
        %{frame_script: adapter_surface.frame_script}
      ),
      check(
        :interaction_script_present,
        adapter_surface.validation_state.interaction_script == :interaction_script_ready and
          adapter_surface.interaction_script.format == :tab_separated_key_values,
        %{interaction_script: adapter_surface.interaction_script}
      ),
      check(
        :visible_runner_present,
        adapter_surface.validation_state.visible_runner == :visible_window_runner_ready and
          adapter_surface.visible_runner.execution_target == :compiled_visible_window and
          adapter_surface.visible_runner.interactive_execution,
        %{visible_runner: adapter_surface.visible_runner}
      ),
      check(
        :renderer_first_backend_bounded,
        adapter_surface.renderer.first_backend == :sdl_renderer and
          adapter_surface.renderer.future_backend == :sdl_gpu and
          adapter_surface.validation_state.renderer == :presented_frame_ready,
        %{renderer: adapter_surface.renderer}
      ),
      check(
        :adapter_execution_scope_bounded,
        adapter_surface.renderer_completeness == :widget_complete_interactive and
          adapter_surface.renderer.widget_complete_draw_operations and
          adapter_surface.renderer.interactive_visible_execution and
          not adapter_surface.renderer.placeholder_draw_operations_allowed,
        %{renderer: adapter_surface.renderer, completeness: adapter_surface.renderer_completeness}
      ),
      check(
        :resource_seams_present,
        adapter_surface.validation_state.text == :text_resource_ready and
          adapter_surface.validation_state.images == :image_resource_ready and
          is_atom(adapter_surface.text_support.active_mode) and
          is_atom(adapter_surface.image_support.active_mode) and
          is_map(adapter_surface.manual_review_workflow),
        %{
          validation_state: adapter_surface.validation_state,
          text_support: adapter_surface.text_support,
          image_support: adapter_surface.image_support,
          manual_review_workflow: adapter_surface.manual_review_workflow
        }
      )
    ]

    report(:sdl3_adapter_surface, checks)
  end

  @spec documentation_surface() :: map()
  def documentation_surface do
    missing_docs =
      @required_guides
      |> Enum.reject(&File.exists?(Path.join(package_root(), &1)))

    undocumented_guides = @required_guides -- DesktopUi.Tooling.documentation_surface()

    checks = [
      check(:guide_files_present, missing_docs == [], %{missing: missing_docs}),
      check(:tooling_docs_surface_complete, undocumented_guides == [], %{
        missing: undocumented_guides
      }),
      check(:readme_present, File.exists?(Path.join(package_root(), "README.md")), [])
    ]

    report(:documentation_surface, checks)
  end

  @spec traceability_targets() :: [String.t()]
  def traceability_targets do
    @required_traceability_targets
  end

  @spec traceability_alignment() :: map()
  def traceability_alignment do
    manifest_path =
      Path.join(workspace_root(), ".spec/planning/desktop_ui/spec-traceability.json")

    markdown_path = Path.join(workspace_root(), ".spec/planning/desktop_ui/spec-traceability.md")

    manifest_result = read_traceability_manifest(manifest_path)

    checks = [
      check(
        :traceability_files_present,
        Enum.all?(@required_traceability_targets, &File.exists?(Path.join(workspace_root(), &1))),
        %{
          missing:
            Enum.reject(
              @required_traceability_targets,
              &File.exists?(Path.join(workspace_root(), &1))
            )
        }
      ),
      check(:traceability_manifest_parses, match?({:ok, _}, manifest_result), %{
        manifest_path: manifest_path
      }),
      check(
        :traceability_package_identity,
        traceability_package_identity?(manifest_result),
        %{expected_package: "desktop_ui"}
      ),
      check(
        :root_subjects_referenced,
        traceability_includes_sources?(manifest_result, @required_root_subjects),
        %{missing: traceability_missing_sources(manifest_result, @required_root_subjects)}
      ),
      check(
        :package_subjects_referenced,
        traceability_includes_sources?(manifest_result, @required_package_subjects),
        %{missing: traceability_missing_sources(manifest_result, @required_package_subjects)}
      ),
      check(
        :traceability_direct_prefix_present,
        traceability_includes_direct_prefix?(manifest_result, "desktop_ui."),
        %{expected_prefix: "desktop_ui."}
      ),
      check(:traceability_markdown_present, File.exists?(markdown_path), %{path: markdown_path})
    ]

    report(:traceability_alignment, checks)
  end

  @spec validation_report() :: map()
  def validation_report do
    sections = default_sections()
    Map.put(sections, :release_readiness, build_release_readiness(sections, :summary))
  end

  @spec surface_validation_report() :: map()
  def surface_validation_report do
    sections = default_sections(skip_host_execution: true)
    Map.put(sections, :release_readiness, build_release_readiness(sections, :summary))
  end

  @spec surface_release_readiness() :: map()
  def surface_release_readiness do
    surface_validation_report().release_readiness
  end

  @spec validation_summary(map()) :: String.t()
  def validation_summary(report) when is_map(report) do
    [
      "DesktopUi validation summary",
      "  example coverage passing?: #{report.example_coverage.status == :pass}",
      "  runtime behavior passing?: #{report.runtime_behavior.status == :pass}",
      "  transport validation passing?: #{report.transport_validation.status == :pass}",
      "  artifact validation passing?: #{report.artifact_validation.status == :pass}",
      "  SDL3 adapter surface passing?: #{report.sdl3_adapter_surface.status == :pass}",
      "  host execution surface passing?: #{report.host_execution_surface.status == :pass}",
      "  widget-complete native rendering?: #{report.sdl3_adapter_surface.status == :pass}",
      "  interactive native execution?: #{report.host_execution_surface.status == :pass}",
      "  tooling surface passing?: #{report.tooling_surface.status == :pass}",
      "  documentation surface passing?: #{report.documentation_surface.status == :pass}",
      "  traceability alignment passing?: #{report.traceability_alignment.status == :pass}",
      "  release ready?: #{report.release_readiness.status == :pass}",
      "  failing sections: #{inspect(report.release_readiness.failing_sections)}"
    ]
    |> Enum.join("\n")
  end

  @spec release_gates() :: [map()]
  def release_gates do
    [
      gate(
        :example_coverage,
        "Maintain native, canonical, and mixed desktop example coverage.",
        :example_coverage
      ),
      gate(
        :runtime_behavior,
        "Keep shared runtime and continuity behavior reviewable and healthy.",
        :runtime_behavior
      ),
      gate(
        :transport_validation,
        "Keep transport translation and no-leakage guarantees explicit.",
        :transport_validation
      ),
      gate(
        :artifact_validation,
        "Keep platform artifact workflows explicit and bounded.",
        :artifact_validation
      ),
      gate(
        :sdl3_adapter_surface,
        "Keep the SDL3 adapter seam explicit, discoverable, and aligned with widget-complete interactive SDL3 rendering.",
        :sdl3_adapter_surface
      ),
      gate(
        :host_execution_surface,
        "Keep the host-backed execution path runnable, inspectable, event/resource aware, and interaction-diagnostic rich.",
        :host_execution_surface
      ),
      gate(
        :tooling_surface,
        "Keep inspect and validate maintainer workflows available together.",
        :tooling_surface
      ),
      gate(
        :documentation_surface,
        "Keep README and package guides aligned with the implemented desktop runtime surface.",
        :documentation_surface
      ),
      gate(
        :traceability_alignment,
        "Keep root and package traceability aligned with desktop_ui planning and release checks.",
        :traceability_alignment
      )
    ]
  end

  @spec evolution_rules() :: [map()]
  def evolution_rules do
    [
      %{
        id: :sdl3_renderer_first_backend,
        description:
          "SDL_Renderer remains the first concrete backend while future SDL_GPU work must preserve the same render-plan, event, and runtime semantics."
      },
      %{
        id: :desktop_ui_not_dsl_or_iur_owner,
        description:
          "`desktop_ui` consumes authored DSL output and canonical IUR input, but does not own either contract."
      },
      %{
        id: :upstream_changes_require_traceability_review,
        description:
          "When UnifiedUi or UnifiedIUR behavior changes, planning traceability, renderer behavior, and validation should move in the same change set."
      },
      %{
        id: :runtime_transport_and_artifacts_stay_aligned,
        description:
          "Desktop runtime, transport translation, and artifact policies should evolve together so target-specific behavior stays bounded."
      },
      %{
        id: :tooling_docs_and_traceability_move_with_surface,
        description:
          "When the package surface changes, examples, inspection, validation, docs, and traceability should stay synchronized."
      }
    ]
  end

  @spec release_readiness(mode()) :: {:ok, map()} | {:error, map()}
  def release_readiness(mode \\ :summary) do
    sections = default_sections()
    report = build_release_readiness(sections, mode)

    case {mode, report.findings} do
      {:strict, [_ | _]} -> {:error, report}
      _ -> {:ok, report}
    end
  end

  defp report(kind, checks) do
    findings =
      checks
      |> Enum.reject(& &1.ok?)
      |> Enum.map(fn check -> %{check: check.name, details: check.details} end)

    %{
      kind: kind,
      status: if(findings == [], do: :pass, else: :fail),
      checks: checks,
      findings: findings
    }
  end

  defp check(name, ok?, details) do
    %{name: name, ok?: ok?, details: details}
  end

  defp gate(id, description, section) do
    %{id: id, description: description, section: section}
  end

  defp exported?(module, function, arity) do
    Code.ensure_loaded?(module) and Enum.member?(module.__info__(:functions), {function, arity})
  end

  defp default_sections(opts \\ []) do
    sections = %{
      example_coverage: example_coverage(),
      runtime_behavior: runtime_behavior(),
      transport_validation: transport_validation(),
      artifact_validation: artifact_validation(),
      sdl3_adapter_surface: sdl3_adapter_surface(),
      tooling_surface: tooling_surface(),
      documentation_surface: documentation_surface(),
      traceability_alignment: traceability_alignment()
    }

    if Keyword.get(opts, :skip_host_execution, false) do
      sections
    else
      Map.put(sections, :host_execution_surface, host_execution_surface())
    end
  end

  defp build_release_readiness(sections, mode) do
    findings = sections |> Map.values() |> Enum.flat_map(& &1.findings)

    gates =
      release_gates()
      |> Enum.filter(&Map.has_key?(sections, &1.section))
      |> Enum.map(fn gate ->
        section = Map.fetch!(sections, gate.section)
        Map.put(gate, :status, section.status)
      end)

    %{
      mode: mode,
      status: if(findings == [], do: :pass, else: :fail),
      gates: gates,
      findings: findings,
      evolution_rules: evolution_rules(),
      failing_sections:
        sections
        |> Enum.filter(fn {_name, report} -> report.status != :pass end)
        |> Enum.map(fn {name, _report} -> name end)
        |> Enum.sort()
    }
  end

  defp host_execution_ok?(
         {:ok, %{status: :ok, frame: %{payload: %{presentation: %{presented_frame?: true}}}}}
       ),
       do: true

  defp host_execution_ok?(_result), do: false

  defp host_execution_details({:ok, execution}), do: execution
  defp host_execution_details({:error, reason}), do: %{error: reason}

  defp run_execution_ok?(
         {:ok,
          %{
            backend: backend,
            execution_mode: execution_mode,
            visible_window?: visible_window?,
            fallback_used?: fallback_used?
          }}
       )
       when backend in [:compiled_sdl3_host, :elixir_host] and
              execution_mode in [:visible_window, :protocol_fallback] and
              is_boolean(visible_window?) and is_boolean(fallback_used?),
       do: true

  defp run_execution_ok?(_result), do: false

  defp run_execution_interaction_ok?(
         {:ok, %{backend: :compiled_sdl3_host, details: %{interaction_summary: summary}}}
       )
       when is_map(summary),
       do:
         is_integer(Map.get(summary, "total_events")) and
           is_integer(Map.get(summary, "focus_changes")) and
           is_integer(Map.get(summary, "window_activations"))

  defp run_execution_interaction_ok?(
         {:ok,
          %{backend: :elixir_host, fallback_used?: true, details: %{frame: %{payload: payload}}}}
       )
       when is_map(payload),
       do: true

  defp run_execution_interaction_ok?(_result), do: false

  defp run_execution_details({:ok, execution}), do: execution
  defp run_execution_details({:error, reason}), do: %{error: reason}

  defp read_traceability_manifest(path) do
    with {:ok, body} <- File.read(path),
         {:ok, manifest} <- JSON.decode(body) do
      {:ok, manifest}
    end
  end

  defp traceability_package_identity?({:ok, %{"package" => package}}), do: package == "desktop_ui"
  defp traceability_package_identity?(_result), do: false

  defp traceability_includes_sources?({:ok, manifest}, expected_sources) do
    traceability_missing_sources({:ok, manifest}, expected_sources) == []
  end

  defp traceability_includes_sources?(_result, _expected_sources), do: false

  defp traceability_missing_sources({:ok, %{"mappings" => mappings}}, expected_sources) do
    source_files =
      mappings
      |> Enum.map(& &1["source_file"])
      |> Enum.uniq()

    expected_sources -- source_files
  end

  defp traceability_missing_sources(_result, expected_sources), do: expected_sources

  defp traceability_includes_direct_prefix?({:ok, %{"applicability" => applicability}}, prefix) do
    applicability
    |> Map.get("direct_prefixes", [])
    |> Enum.member?(prefix)
  end

  defp traceability_includes_direct_prefix?(_result, _prefix), do: false

  # Verifies that all 47 canonical IUR widget kinds are supported by the renderer.
  # Returns true when the renderer supports the complete set of IUR widget kinds.
  defp iur_widget_coverage_complete? do
    expected_count = 47
    actual_count = length(DesktopUi.Renderer.supported_kinds())

    actual_count >= expected_count and
      Enum.all?(
        DesktopUi.Widgets.kinds(),
        &(&1 in DesktopUi.Renderer.supported_kinds())
      )
  end

  defp package_root do
    Path.expand("../..", __DIR__)
  end

  defp workspace_root do
    Path.expand("../../../..", __DIR__)
  end
end
