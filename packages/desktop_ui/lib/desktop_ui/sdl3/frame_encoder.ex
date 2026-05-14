defmodule DesktopUi.Sdl3.FrameEncoder do
  @moduledoc """
  Encodes retained render plans into framed host payloads for SDL3 presentation.
  """

  alias DesktopUi.Sdl3.RenderPlan

  @spec contract() :: map()
  def contract do
    %{
      payload_family: :frame,
      preserves: [
        :logical_bounds,
        :clip_regions,
        :transient_layers,
        :resolved_styles,
        :resource_descriptors,
        :interaction_contract,
        :visual_state,
        :metrics,
        :clip_bounds
      ],
      host_drawing_independent: true,
      first_backend: :sdl_renderer
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :frame_encoding_ready

  @spec encode(RenderPlan.t()) :: {:ok, map()}
  def encode(%RenderPlan{} = plan) do
    windows = Enum.map(plan.windows, &encode_window/1)

    {:ok,
     %{
       runtime_id: plan.runtime_id,
       screen_id: plan.screen_id,
       windows: windows,
       presentation: %{
         backend: plan.presentation.backend,
         logical_presentation: %{
           units: :logical,
           mode: :letterbox,
           dpi_policy: :bounded
         },
         clip_regions_preserved: true,
         transient_layers_preserved: true,
         widget_complete_draw_operations: plan.presentation.widget_complete_draw_operations,
         window_count: length(windows)
       },
       diagnostics: %{
         window_count: length(windows),
         draw_operation_count: Enum.sum(Enum.map(windows, &length(&1.draw_operations))),
         clip_region_count: Enum.sum(Enum.map(windows, &length(&1.clip_regions))),
         render_plan_validation_state: plan.presentation.validation_state,
         draw_kind_counts: plan.diagnostics.draw_kind_counts
       },
       validation_state: :frame_payload_ready
     }}
  end

  defp encode_window(window) do
    %{
      window_id: window.window_id,
      window_identity: window.window_identity,
      title: window.title,
      role: window.role,
      native_window?: window.native_window?,
      logical_bounds: window.logical_bounds,
      clip_regions: Enum.map(window.clip_regions, &encode_clip_region/1),
      transient_layers: Enum.map(window.transient_layers, &encode_transient_layer/1),
      draw_operations:
        window.draw_operations
        |> Enum.with_index()
        |> Enum.map(&encode_draw_operation/1),
      validation_state: :frame_window_payload_ready
    }
  end

  defp encode_clip_region(region) do
    %{
      widget_id: region.widget_id,
      kind: region.kind,
      viewport: region.viewport,
      positioned: region.positioned
    }
  end

  defp encode_transient_layer(layer) do
    %{
      widget_id: layer.widget_id,
      kind: layer.kind,
      role: layer.role
    }
  end

  defp encode_draw_operation({operation, order}) do
    %{
      order: order,
      widget_id: operation.widget_id,
      kind: operation.kind,
      family: operation.family,
      draw_kind: operation.draw_kind,
      logical_bounds: operation.logical_bounds,
      clip?: operation.clip?,
      clip_bounds: operation.clip_bounds,
      layer_role: operation.layer_role,
      semantic_role: operation.semantic_role,
      resolved_styles: operation.resolved_styles,
      resource: Map.get(operation, :resource, %{}),
      interaction: Map.get(operation, :interaction, %{}),
      visual_state: operation.visual_state,
      metrics: operation.metrics,
      content: operation.content
    }
  end
end
