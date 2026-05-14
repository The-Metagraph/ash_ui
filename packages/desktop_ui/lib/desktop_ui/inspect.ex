defmodule DesktopUi.Inspect do
  @moduledoc """
  Maintainer-facing preview and inspection workflows for `desktop_ui` examples.
  """

  alias DesktopUi.Runtime.State
  alias DesktopUi.Sdl3.{Capabilities, RenderPlan, VisibleRunner}

  @spec preview(atom() | String.t()) :: {:ok, map()} | {:error, :unknown_example}
  def preview(id) do
    with {:ok, metadata} <- fetch_metadata(id) do
      {:ok,
       %{
         id: metadata.id,
         metadata: metadata,
         surface: preview_surface(metadata)
       }}
    end
  end

  @spec catalog() :: map()
  def catalog do
    %{
      examples: DesktopUi.Examples.catalog(),
      preview_surfaces: DesktopUi.Tooling.preview_surfaces(),
      package_overview: DesktopUi.Inspection.package_overview(),
      sdl3_adapter_surface: DesktopUi.Inspection.sdl3_adapter_surface(),
      tooling_workflows: DesktopUi.Tooling.workflows()
    }
  end

  @spec host_execution(atom() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def host_execution(id, opts \\ []) do
    capabilities = Capabilities.detect()

    with {:ok, metadata} <- fetch_metadata(id),
         {:ok, launched} <- launch_host(metadata, opts),
         host_status = DesktopUi.Sdl3.PortHost.status(launched.host),
         {:ok, shutdown_ack, host} <- DesktopUi.Sdl3.App.shutdown_host(launched.host) do
      {:ok,
       %{
         id: metadata.id,
         metadata: metadata,
         status: :ok,
         host_status: host_status,
         boot: launched.acknowledgement,
         frame: launched.frame_acknowledgement,
         shutdown: %{acknowledgement: shutdown_ack, final_state: host.state},
         resource_contracts: %{
           text: DesktopUi.Sdl3.Text.contract(),
            images: DesktopUi.Sdl3.Images.contract()
         },
         resource_support: %{
           text: DesktopUi.Sdl3.Text.native_support(capabilities),
           images: DesktopUi.Sdl3.Images.native_support(capabilities)
         },
         event_contract: DesktopUi.Sdl3.Events.contract()
       }}
    end
  end

  @spec run_execution(atom() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run_execution(id, opts \\ []) do
    with {:ok, metadata} <- fetch_metadata(id),
         capabilities <- Keyword.get(opts, :capabilities, Capabilities.detect()),
         {:ok, execution_backend} <-
           select_run_backend(capabilities, Keyword.get(opts, :backend, :auto)),
         {:ok, execution} <- execute_run(metadata, execution_backend, capabilities, opts) do
      {:ok, execution}
    end
  end

  @spec render(atom() | String.t(), atom()) :: {:ok, String.t()} | {:error, term()}
  def render(id, format \\ :report) do
    case format do
      :host ->
        with {:ok, execution} <- host_execution(id) do
          {:ok,
           Kernel.inspect(execution, pretty: true, width: 100, limit: :infinity, sort_maps: true)}
        end

      _other ->
        with {:ok, preview} <- preview(id) do
          {:ok, format_preview(preview, format)}
        end
    end
  end

  defp preview_surface(%{category: :native, id: :native_foundational}) do
    preview_native(DesktopUi.Examples.native_foundational_screen(), platform_target: :linux)
  end

  defp preview_surface(%{category: :native, id: :native_advanced_operations}) do
    preview_native(DesktopUi.Examples.native_advanced_operations_screen(),
      platform_target: :linux
    )
  end

  defp preview_surface(%{category: :native, id: :native_transport_review}) do
    preview_native(DesktopUi.Examples.native_transport_review(), platform_target: :linux)
  end

  defp preview_surface(%{category: :native, id: :native_styled_review}) do
    preview_native(DesktopUi.Examples.native_styled_review(),
      platform_target: :linux,
      theme: :high_contrast
    )
  end

  defp preview_surface(%{category: :canonical, id: :canonical_foundational}) do
    preview_canonical(DesktopUi.Examples.canonical_foundational_screen(), platform_target: :linux)
  end

  defp preview_surface(%{category: :canonical, id: :canonical_advanced_operations}) do
    preview_canonical(DesktopUi.Examples.canonical_advanced_operations_screen(),
      platform_target: :linux
    )
  end

  defp preview_surface(%{category: :canonical, id: :canonical_transport_review}) do
    preview_canonical(DesktopUi.Examples.canonical_transport_review(), platform_target: :linux)
  end

  defp preview_surface(%{category: :canonical, id: :canonical_styled_review}) do
    preview_canonical(DesktopUi.Examples.canonical_styled_review(),
      platform_target: :linux,
      theme: :high_contrast
    )
  end

  defp preview_surface(%{category: :mixed, id: :foundational_continuity}) do
    DesktopUi.Examples.foundational_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :advanced_continuity}) do
    DesktopUi.Examples.advanced_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :transport_flow_review}) do
    DesktopUi.Examples.transport_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :normalized_input_profiles}) do
    DesktopUi.Examples.normalized_input_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :styled_continuity_review}) do
    DesktopUi.Examples.styled_comparison()
  end

  defp launch_host(%{category: :native, id: :native_foundational}, opts) do
    DesktopUi.Sdl3.App.launch_native_screen(
      DesktopUi.Examples.native_foundational_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :native, id: :native_advanced_operations}, opts) do
    DesktopUi.Sdl3.App.launch_native_screen(
      DesktopUi.Examples.native_advanced_operations_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :native, id: :native_transport_review}, opts) do
    DesktopUi.Sdl3.App.launch_native_screen(
      DesktopUi.Examples.native_transport_review(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :native, id: :native_styled_review}, opts) do
    DesktopUi.Sdl3.App.launch_native_screen(
      DesktopUi.Examples.native_styled_review(),
      Keyword.merge([platform_target: :linux, theme: :high_contrast], opts)
    )
  end

  defp launch_host(%{category: :canonical, id: :canonical_foundational}, opts) do
    DesktopUi.Sdl3.App.launch_iur_screen(
      DesktopUi.Examples.canonical_foundational_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :canonical, id: :canonical_advanced_operations}, opts) do
    DesktopUi.Sdl3.App.launch_iur_screen(
      DesktopUi.Examples.canonical_advanced_operations_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :canonical, id: :canonical_transport_review}, opts) do
    DesktopUi.Sdl3.App.launch_iur_screen(
      DesktopUi.Examples.canonical_transport_review(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp launch_host(%{category: :canonical, id: :canonical_styled_review}, opts) do
    DesktopUi.Sdl3.App.launch_iur_screen(
      DesktopUi.Examples.canonical_styled_review(),
      Keyword.merge([platform_target: :linux, theme: :high_contrast], opts)
    )
  end

  defp launch_host(%{category: :mixed}, _opts),
    do: {:error, :mixed_examples_do_not_boot_native_hosts}

  defp execute_run(metadata, :compiled_sdl3_host, capabilities, opts) do
    with {:ok, %RenderPlan{} = plan} <- render_plan_for(metadata, opts),
         {:ok, execution} <-
           VisibleRunner.run(plan, Keyword.put(opts, :capabilities, capabilities)) do
      {:ok,
       %{
         id: metadata.id,
         metadata: metadata,
         status: :ok,
         backend: :compiled_sdl3_host,
         execution_mode: :visible_window,
         visible_window?: true,
         presented_frame?: execution.presented_frame?,
         fallback_used?: false,
         capabilities: capabilities,
         resource_support: resource_support(capabilities),
         details: execution
       }}
    end
  end

  defp execute_run(metadata, :elixir_host, capabilities, opts) do
    with {:ok, host_execution} <-
           host_execution(metadata.id, Keyword.put(opts, :backend, :elixir_host)) do
      {:ok,
       %{
         id: metadata.id,
         metadata: metadata,
         status: :ok,
         backend: :elixir_host,
         execution_mode: :protocol_fallback,
         visible_window?: false,
         presented_frame?: host_execution.frame.payload.presentation.presented_frame?,
         fallback_used?: true,
         fallback_reason: fallback_reason(capabilities),
         capabilities: capabilities,
         resource_support: resource_support(capabilities),
         details: host_execution
       }}
    end
  end

  defp render_plan_for(metadata, opts) do
    with {:ok, %State{} = runtime_state} <- runtime_state_for(metadata, opts),
         {:ok, %RenderPlan{} = plan} <- RenderPlan.build(runtime_state) do
      {:ok, plan}
    end
  end

  defp runtime_state_for(%{category: :native, id: :native_foundational}, opts) do
    DesktopUi.Runtime.mount_native_screen(
      DesktopUi.Examples.native_foundational_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :native, id: :native_advanced_operations}, opts) do
    DesktopUi.Runtime.mount_native_screen(
      DesktopUi.Examples.native_advanced_operations_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :native, id: :native_transport_review}, opts) do
    DesktopUi.Runtime.mount_native_screen(
      DesktopUi.Examples.native_transport_review(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :native, id: :native_styled_review}, opts) do
    DesktopUi.Runtime.mount_native_screen(
      DesktopUi.Examples.native_styled_review(),
      Keyword.merge([platform_target: :linux, theme: :high_contrast], opts)
    )
  end

  defp runtime_state_for(%{category: :canonical, id: :canonical_foundational}, opts) do
    DesktopUi.Runtime.mount_iur_screen(
      DesktopUi.Examples.canonical_foundational_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :canonical, id: :canonical_advanced_operations}, opts) do
    DesktopUi.Runtime.mount_iur_screen(
      DesktopUi.Examples.canonical_advanced_operations_screen(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :canonical, id: :canonical_transport_review}, opts) do
    DesktopUi.Runtime.mount_iur_screen(
      DesktopUi.Examples.canonical_transport_review(),
      Keyword.merge([platform_target: :linux], opts)
    )
  end

  defp runtime_state_for(%{category: :canonical, id: :canonical_styled_review}, opts) do
    DesktopUi.Runtime.mount_iur_screen(
      DesktopUi.Examples.canonical_styled_review(),
      Keyword.merge([platform_target: :linux, theme: :high_contrast], opts)
    )
  end

  defp runtime_state_for(%{category: :mixed}, _opts),
    do: {:error, :mixed_examples_do_not_mount_runtime_state}

  defp select_run_backend(capabilities, :auto) do
    if capabilities.build.visible_runner_ready? do
      {:ok, :compiled_sdl3_host}
    else
      {:ok, :elixir_host}
    end
  end

  defp select_run_backend(capabilities, :compiled) do
    if capabilities.build.visible_runner_ready? do
      {:ok, :compiled_sdl3_host}
    else
      {:error,
       DesktopUi.Runtime.Error.new(
         :compiled_visible_runner_not_ready,
         %{capabilities: capabilities.build},
         :sdl3_visible_runner
       )}
    end
  end

  defp select_run_backend(_capabilities, :fallback), do: {:ok, :elixir_host}

  defp resource_support(capabilities) do
    %{
      text: DesktopUi.Sdl3.Text.native_support(capabilities),
      images: DesktopUi.Sdl3.Images.native_support(capabilities)
    }
  end

  defp fallback_reason(capabilities) do
    %{
      visible_runner_ready?: capabilities.build.visible_runner_ready?,
      protocol_launch_ready?: capabilities.build.launch_ready?,
      executable_probe: capabilities.build.executable_probe
    }
  end

  defp preview_native(screen, opts) do
    {:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, opts)
    DesktopUi.Inspection.runtime_snapshot(state)
  end

  defp preview_canonical(element, opts) do
    {:ok, state} = DesktopUi.Runtime.mount_iur_screen(element, opts)
    DesktopUi.Inspection.runtime_snapshot(state)
  end

  defp fetch_metadata(id) do
    case resolve_metadata(id) do
      nil -> {:error, :unknown_example}
      metadata -> {:ok, metadata}
    end
  end

  defp resolve_metadata(id) when is_atom(id), do: DesktopUi.Examples.metadata(id)

  defp resolve_metadata(id) when is_binary(id) do
    Enum.find(DesktopUi.Examples.catalog(), &(Atom.to_string(&1.id) == id))
  end

  defp resolve_metadata(_id), do: nil

  defp format_preview(preview, :report) do
    Kernel.inspect(preview, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :metadata) do
    Kernel.inspect(preview.metadata, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :comparison) do
    payload =
      case preview.metadata.category do
        :mixed ->
          %{id: preview.id, metadata: preview.metadata, surface: preview.surface}

        _other ->
          %{
            id: preview.id,
            metadata: preview.metadata,
            direct_native_and_canonical_runtime_behavior: preview.surface
          }
      end

    Kernel.inspect(payload, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :diagnostics) do
    diagnostics =
      case preview.metadata.category do
        :mixed ->
          %{
            id: preview.id,
            category: preview.metadata.category,
            parity: Map.get(preview.surface, :parity, %{}),
            coverage: Map.get(preview.surface, :coverage, %{}),
            tooling_workflows: DesktopUi.Tooling.workflows(),
            transport_mappings: DesktopUi.Transport.diagnostics(),
            artifact_workflows: DesktopUi.Artifacts.diagnostics()
          }

        _other ->
          %{
            id: preview.id,
            category: preview.metadata.category,
            runtime: preview.surface.runtime,
            style: preview.surface.style,
            platform: preview.surface.platform,
            sdl3_adapter: DesktopUi.Inspection.sdl3_adapter_surface(),
            artifact_workflows: DesktopUi.Artifacts.workflow(preview.surface.platform.target)
          }
      end

    Kernel.inspect(diagnostics, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end
end
