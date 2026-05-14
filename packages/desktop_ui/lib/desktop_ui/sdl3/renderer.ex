defmodule DesktopUi.Sdl3.Renderer do
  @moduledoc """
  SDL_Renderer-first presentation boundary for SDL3 render plans.
  """

  alias DesktopUi.Runtime.State
  alias DesktopUi.Sdl3.{FrameEncoder, RenderPlan}

  @spec contract() :: map()
  def contract do
    %{
      first_backend: :sdl_renderer,
      future_backend: :sdl_gpu,
      preserves_render_plan_semantics: true,
      frame_encoder: :host_protocol_payload,
      logical_presentation: :letterbox,
      widget_complete_draw_operations: true,
      interactive_visible_execution: true,
      placeholder_draw_operations_allowed: false
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :presented_frame_ready

  @spec prepare_frame(State.t()) :: {:ok, RenderPlan.t()} | {:error, term()}
  def prepare_frame(%State{} = runtime_state) do
    RenderPlan.build(runtime_state)
  end

  @spec encode_frame(RenderPlan.t()) :: {:ok, map()}
  def encode_frame(%RenderPlan{} = plan) do
    FrameEncoder.encode(plan)
  end

  @spec present(RenderPlan.t(), keyword()) :: {:ok, map()}
  def present(%RenderPlan{} = plan, opts \\ []) do
    with {:ok, frame_payload} <- encode_frame(plan) do
      present_payload(frame_payload, opts)
    end
  end

  @spec present_payload(map(), keyword()) :: {:ok, map()}
  def present_payload(frame_payload, opts \\ []) when is_map(frame_payload) do
    windows = Map.get(frame_payload, :windows, [])
    draw_operations = Enum.flat_map(windows, &Map.get(&1, :draw_operations, []))
    redraw_status = Keyword.get(opts, :redraw_status, :requested)

    {:ok,
     %{
       backend: :sdl_renderer,
       redraw_status: redraw_status,
       logical_presentation: get_in(frame_payload, [:presentation, :logical_presentation]),
       window_count: length(windows),
       presented_frame?: windows != [],
       widget_complete_draw_operations?:
         get_in(frame_payload, [:presentation, :widget_complete_draw_operations]) || false,
       draw_operation_count: length(draw_operations),
       draw_kind_counts: Enum.frequencies_by(draw_operations, & &1.draw_kind),
       presented_windows:
         Enum.map(windows, fn window ->
           %{
             window_id: window.window_id,
             render_target: :native_window,
             presented?: true,
             draw_operations: length(window.draw_operations),
             draw_kind_counts: Enum.frequencies_by(window.draw_operations, & &1.draw_kind),
             clip_regions: length(window.clip_regions),
             transient_layers: Enum.map(window.transient_layers, & &1.widget_id),
             clear_color: clear_color(window),
             logical_bounds: window.logical_bounds
           }
         end),
       validation_state: validation_state()
     }}
  end

  defp clear_color(window) do
    styles =
      window.draw_operations
      |> Enum.find_value(%{}, fn operation ->
        resolved = Map.get(operation, :resolved_styles, %{})
        if map_size(resolved) > 0, do: resolved
      end)

    Map.get(styles, :bg, :canvas)
  end
end
