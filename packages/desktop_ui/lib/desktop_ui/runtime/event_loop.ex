defmodule DesktopUi.Runtime.EventLoop do
  @moduledoc """
  Shared event-loop scaffold for the `desktop_ui` runtime backbone.
  """

  alias DesktopUi.Runtime.{Dispatch, Frame, Poller, Redraw}

  @spec scaffold(keyword()) :: map()
  def scaffold(opts \\ []) do
    %{
      platform_target: Keyword.get(opts, :platform_target, :linux),
      screen_id: Keyword.get(opts, :screen_id, "screen"),
      local_events: 0,
      boundary_events: 0,
      poller: Poller.scaffold(),
      redraw: Redraw.scaffold(),
      input_dispatch: Dispatch.scaffold(),
      frame: Frame.scaffold(),
      focus_callbacks: :placeholder_ready,
      shortcut_callbacks: :placeholder_ready,
      window_lifecycle_callbacks: :placeholder_ready,
      routing_state: :shared_runtime_ready
    }
  end

  @spec record_route(map(), map()) :: map()
  def record_route(loop_state, route_result) when is_map(loop_state) and is_map(route_result) do
    count_key =
      if route_result.route == :canonical_boundary, do: :boundary_events, else: :local_events

    loop_state
    |> Map.update!(count_key, &(&1 + 1))
    |> Map.put(:last_route, route_result.route)
    |> Map.put(:last_runtime_event, route_result.runtime_event)
    |> Map.put(:last_family, route_result.family)
    |> Map.put(:last_input_family, route_result.input_family)
  end

  @spec diagnostics(map()) :: map()
  def diagnostics(loop_state) when is_map(loop_state) do
    %{
      local_events: Map.get(loop_state, :local_events, 0),
      boundary_events: Map.get(loop_state, :boundary_events, 0),
      poller: Map.get(loop_state, :poller),
      redraw: Map.get(loop_state, :redraw),
      input_dispatch: Map.get(loop_state, :input_dispatch),
      frame: Map.get(loop_state, :frame),
      focus_callbacks: Map.get(loop_state, :focus_callbacks),
      shortcut_callbacks: Map.get(loop_state, :shortcut_callbacks),
      window_lifecycle_callbacks: Map.get(loop_state, :window_lifecycle_callbacks),
      routing_state: Map.get(loop_state, :routing_state),
      last_route: Map.get(loop_state, :last_route),
      last_runtime_event: Map.get(loop_state, :last_runtime_event),
      last_family: Map.get(loop_state, :last_family),
      last_input_family: Map.get(loop_state, :last_input_family)
    }
  end
end
