defmodule DesktopUi.Inspection do
  @moduledoc """
  Package and runtime inspection helpers for `desktop_ui`.
  """

  alias DesktopUi.Runtime.State

  @spec helpers() :: [atom()]
  def helpers do
    [
      :package_overview,
      :runtime_snapshot,
      :style_nodes,
      :manual_review_workflow,
      :platform_profiles,
      :continuity_contract,
      :shared_runtime_contract,
      :packaging_contract,
      :sdl3_adapter_surface,
      :platform_contract,
      :transport_contract,
      :layering_contract,
      :validation_surface
    ]
  end

  @spec package_overview() :: map()
  def package_overview do
    %{
      runtime_foundation: :sdl3,
      runtime_binding: :sdl,
      platform_targets: DesktopUi.Platform.targets(),
      package_areas: DesktopUi.package_areas(),
      sdl3_adapter: sdl3_adapter_surface(),
      style: %{
        primitives: Map.keys(DesktopUi.Style.primitives()),
        hooks: DesktopUi.Style.widget_style_hooks(),
        responsibilities: DesktopUi.Style.responsibilities()
      },
      theme: %{
        catalog: DesktopUi.Theme.catalog_ids(),
        default: DesktopUi.Theme.default_theme().id,
        continuity_rules: DesktopUi.Theme.continuity_rules()
      },
      artifacts: %{
        target_platforms: DesktopUi.Artifacts.target_platforms(),
        boundary_policy: DesktopUi.Artifacts.boundary_policy()
      },
      layout: %{
        kinds: DesktopUi.Layout.kinds(),
        validation_state: DesktopUi.Layout.validation_state()
      },
      layer: %{
        kinds: DesktopUi.Layer.kinds(),
        validation_state: DesktopUi.Layer.validation_state()
      },
      examples: %{
        native_ids: DesktopUi.Examples.native_ids(),
        canonical_ids: DesktopUi.Examples.canonical_ids(),
        comparison_ids: DesktopUi.Examples.comparison_ids()
      },
      build: %{
        contract: DesktopUi.Build.contract(),
        targets: DesktopUi.Build.targets(),
        validation_state: DesktopUi.Build.validation_state()
      },
      packaging: %{
        contract: DesktopUi.Package.contract(),
        targets: DesktopUi.Package.targets(),
        diagnostics: DesktopUi.Package.diagnostics(),
        validation_state: DesktopUi.Package.validation_state()
      },
      manual_review_workflow: manual_review_workflow(),
      transport: transport_contract(),
      platform_profiles: platform_profiles(),
      continuity: continuity_contract(),
      shared_runtime_contract: shared_runtime_contract(),
      validation: validation_surface()
    }
  end

  @spec runtime_snapshot(State.t()) :: map()
  def runtime_snapshot(%State{} = state) do
    style_nodes = style_nodes(state.realization.tree)

    %{
      runtime: %{
        runtime_id: state.runtime_id,
        screen_id: state.screen_id,
        source_kind: state.source_kind,
        platform_target: state.platform_target,
        theme: state.realization.theme,
        validation_state: state.validation_state
      },
      style: %{
        theme: state.realization.theme,
        node_count: length(style_nodes),
        style_nodes: style_nodes,
        diagnostics: get_in(state.realization, [:diagnostics, :style_warnings]) || []
      },
      platform: %{
        target: state.platform_target,
        profile: DesktopUi.Platform.Integration.target_profile(state.platform_target),
        artifacts: DesktopUi.Artifacts.workflow(state.platform_target)
      }
    }
  end

  @spec style_nodes(map()) :: [map()]
  def style_nodes(tree) when is_map(tree) do
    collect_style_nodes(tree)
  end

  @spec platform_profiles() :: [map()]
  def platform_profiles do
    DesktopUi.Platform.Integration.diagnostics().target_profiles
  end

  @spec continuity_contract() :: map()
  def continuity_contract do
    DesktopUi.Continuity.contract()
  end

  @spec shared_runtime_contract() :: map()
  def shared_runtime_contract do
    %{
      assumptions: DesktopUi.Runtime.assumptions(),
      runtime_modules: DesktopUi.Runtime.modules(),
      sdl3_modules: DesktopUi.Sdl3.modules(),
      platform_targets: DesktopUi.Platform.targets(),
      layout_kinds: DesktopUi.Layout.kinds(),
      layer_kinds: DesktopUi.Layer.kinds(),
      transport_modes: DesktopUi.Transport.modes(),
      lifecycle_model: DesktopUi.Sdl3.foundation().lifecycle_model,
      shared_style_model: true,
      direct_native_and_canonical_share_runtime: true
    }
  end

  @spec manual_review_workflow() :: map()
  def manual_review_workflow do
    %{
      compiled_visible_review: [
        "mix desktop_ui.build_host --dry-run",
        "mix desktop_ui.build_host",
        "mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000",
        "mix desktop_ui.run native_advanced_operations --backend compiled --linger-ms 3000",
        "mix desktop_ui.run native_transport_review --backend compiled --linger-ms 3000",
        "mix desktop_ui.run native_styled_review --backend compiled --linger-ms 3000"
      ],
      fallback_review: [
        "mix desktop_ui.run native_foundational --backend fallback",
        "mix desktop_ui.inspect native_foundational --format host"
      ],
      expectations: [
        :widget_complete_rendering,
        :native_text_and_image_diagnostics,
        :interactive_keyboard_and_pointer_review,
        :multiwindow_and_overlay_review,
        :explicit_fallback_when_sdl3_unavailable
      ]
    }
  end

  @spec sdl3_adapter_surface() :: map()
  def sdl3_adapter_surface do
    capabilities = DesktopUi.Sdl3.Capabilities.detect()

    %{
      foundation: DesktopUi.Sdl3.foundation(),
      modules: DesktopUi.Sdl3.modules(),
      scope: DesktopUi.Sdl3.adapter_scope(),
      lifecycle: DesktopUi.Sdl3.App.lifecycle_contract(),
      handoff: DesktopUi.Sdl3.App.handoff_contract(),
      host: DesktopUi.Sdl3.PortHost.contract(),
      native_build: DesktopUi.Sdl3.NativeBuild.contract(),
      capabilities: capabilities,
      protocol: DesktopUi.Sdl3.Protocol.contract(),
      frame_encoder: DesktopUi.Sdl3.FrameEncoder.contract(),
      frame_script: DesktopUi.Sdl3.FrameScript.contract(),
      interaction_script: DesktopUi.Sdl3.InteractionScript.contract(),
      visible_runner: DesktopUi.Sdl3.VisibleRunner.contract(),
      renderer: DesktopUi.Sdl3.Renderer.contract(),
      events: DesktopUi.Sdl3.Events.contract(),
      text: DesktopUi.Sdl3.Text.contract(),
      images: DesktopUi.Sdl3.Images.contract(),
      text_support: DesktopUi.Sdl3.Text.native_support(capabilities),
      image_support: DesktopUi.Sdl3.Images.native_support(capabilities),
      manual_review_workflow: manual_review_workflow(),
      renderer_completeness: :widget_complete_interactive,
      validation_state: %{
        adapter: DesktopUi.Sdl3.validation_state(),
        host: DesktopUi.Sdl3.PortHost.validation_state(),
        native_build: DesktopUi.Sdl3.NativeBuild.validation_state(),
        capabilities: DesktopUi.Sdl3.Capabilities.validation_state(),
        protocol: DesktopUi.Sdl3.Protocol.validation_state(),
        frame_encoder: DesktopUi.Sdl3.FrameEncoder.validation_state(),
        frame_script: DesktopUi.Sdl3.FrameScript.validation_state(),
        interaction_script: DesktopUi.Sdl3.InteractionScript.validation_state(),
        visible_runner: DesktopUi.Sdl3.VisibleRunner.validation_state(),
        renderer: DesktopUi.Sdl3.Renderer.validation_state(),
        text: DesktopUi.Sdl3.Text.validation_state(),
        images: DesktopUi.Sdl3.Images.validation_state()
      }
    }
  end

  @spec layering_contract() :: map()
  def layering_contract do
    %{
      layout: DesktopUi.Layout.validation_state(),
      layer: DesktopUi.Layer.validation_state(),
      multiwindow_runtime: true,
      advanced_display_shared_runtime: true
    }
  end

  @spec transport_contract() :: map()
  def transport_contract do
    %{
      modes: DesktopUi.Transport.modes(),
      families: DesktopUi.Transport.families(),
      input_families: DesktopUi.Transport.input_families(),
      local_default_families: DesktopUi.Transport.local_default_families(),
      boundary_crossing_families: DesktopUi.Transport.boundary_crossing_families(),
      diagnostics: DesktopUi.Transport.diagnostics(),
      no_platform_leakage_guarantee: true
    }
  end

  @spec validation_surface() :: map()
  def validation_surface do
    %{
      widgets: DesktopUi.Widgets.validation_state(),
      runtime: DesktopUi.Runtime.validation_state(),
      platform: DesktopUi.Platform.validation_state(),
      style: DesktopUi.Style.validation_state(),
      theme: DesktopUi.Theme.validation_state(),
      layout: DesktopUi.Layout.validation_state(),
      layer: DesktopUi.Layer.validation_state(),
      renderer: DesktopUi.Renderer.validation_state(),
      transport: DesktopUi.Transport.validation_state(),
      artifacts: DesktopUi.Artifacts.validation_state(),
      packaging: DesktopUi.Package.validation_state(),
      sdl3: DesktopUi.Sdl3.validation_state()
    }
  end

  defp collect_style_nodes(node) do
    [
      %{
        id: node.id,
        family: node.family,
        kind: node.kind,
        theme: get_in(node, [:resolved_styles, :theme]),
        resolved_styles: Map.get(node, :resolved_styles, %{}),
        active_states: Map.get(node, :active_style_states, []),
        style_diagnostics: Map.get(node, :style_diagnostics, [])
      }
    ] ++ Enum.flat_map(Map.get(node, :children, []), &collect_style_nodes/1)
  end
end
