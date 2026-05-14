defmodule DesktopUi.Runtime do
  @moduledoc """
  Shared runtime entrypoint for native and canonical `desktop_ui` screens.
  """

  alias DesktopUi.Renderer
  alias DesktopUi.Runtime.{Boot, Error, EventLoop, EventRouter, Shutdown, State, StyleResolver}
  alias UnifiedIUR.Element
  alias Jido.Signal

  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      Boot,
      EventLoop,
      EventRouter,
      DesktopUi.Runtime.Poller,
      DesktopUi.Runtime.Realization,
      DesktopUi.Runtime.Redraw,
      DesktopUi.Runtime.Dispatch,
      DesktopUi.Runtime.Frame,
      DesktopUi.Runtime.Window,
      DesktopUi.Runtime.Screen,
      StyleResolver,
      DesktopUi.Runtime.State,
      DesktopUi.Runtime.Shutdown,
      DesktopUi.Runtime.Error,
      DesktopUi.Layout,
      DesktopUi.Layer
    ]
  end

  @spec capabilities() :: [atom()]
  def capabilities do
    [
      :native_mount,
      :renderer_mount,
      :shared_sdl_runtime,
      :sdl3_callback_runtime,
      :sdl3_runtime_handoff,
      :window_registry,
      :redraw_scheduling,
      :foundational_layout_realization,
      :binding_indexing,
      :event_targeting,
      :advanced_display_realization,
      :layered_runtime,
      :multiwindow_registry,
      :window_focus_handoff,
      :canonical_boundary_events,
      :normalized_desktop_inputs,
      :shared_event_routing,
      :event_polling_scaffold,
      :frame_coordination,
      :focus_callback_placeholders,
      :shortcut_callback_placeholders,
      :window_lifecycle_callbacks,
      :platform_adapter_registration,
      :shared_style_model,
      :theme_inheritance_resolution,
      :deterministic_runtime_errors
    ]
  end

  @spec assumptions() :: map()
  def assumptions do
    %{
      shared_runtime_foundation: :sdl3,
      shared_runtime_binding: :sdl,
      lifecycle_model: :callback_oriented,
      shared_runtime_for_native_and_canonical: true,
      platform_variation_bounded: true,
      boundary_local_routing_shared: true,
      shared_style_model: true,
      renderer_boot_path_present: true,
      package_application_takeover: false
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :runtime_backbone_ready

  @spec accepts() :: module()
  def accepts, do: Element

  @spec mount_native_screen(map(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def mount_native_screen(screen, opts \\ []) when is_map(screen) do
    Boot.prepare_native_screen(screen, opts)
  end

  @spec mount_iur_screen(Element.t(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def mount_iur_screen(%Element{} = element, opts \\ []) do
    with {:ok, rendered_root} <- Renderer.render(element, opts) do
      Boot.prepare_rendered_screen(rendered_root, opts)
    else
      {:error, %DesktopUi.Renderer.Error{} = error} ->
        {:error, Error.new(error.reason, error.details, :renderer_boot)}
    end
  end

  @doc """
  Mount an IUR element using the desktop runtime.
  Compatible interface with LiveUi.Runtime for runtime adapter support.
  """
  @spec mount_iur(Element.t(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def mount_iur(%Element{} = element, opts \\ []) do
    mount_iur_screen(element, opts)
  end

  @doc """
  Returns the LiveView component module for server-rendered HTML.
  For desktop_ui, this delegates to live_ui for browser compatibility.
  """
  @spec component() :: module()
  def component do
    # Desktop UI can be previewed in browser via live_ui components
    # This allows unified examples to work with both runtimes
    LiveUi.Runtime.component()
  end

  @spec shutdown(State.t()) :: {:ok, State.t()} | {:error, Error.t()}
  def shutdown(%State{} = runtime_state) do
    Shutdown.stop(runtime_state)
  end

  @spec dispatch_native_event(State.t(), keyword() | map()) ::
          {:ok, State.t(), map()} | {:error, Error.t() | term()}
  def dispatch_native_event(%State{} = runtime_state, attrs)
      when is_map(attrs) or is_list(attrs) do
    attrs =
      attrs
      |> normalize_map()
      |> Map.put_new(:platform_target, runtime_state.platform_target)
      |> Map.put_new(:runtime_id, runtime_state.runtime_id)
      |> Map.put_new(:screen, runtime_state.screen_id)
      |> Map.put_new(:source_kind, runtime_state.source_kind)

    with {:ok, translation} <- DesktopUi.Transport.from_native_event(attrs),
         {:ok, route_result} <- EventRouter.route(runtime_state, translation) do
      {:ok, apply_route(runtime_state, route_result), route_result}
    end
  end

  @spec dispatch_widget_interaction(State.t(), String.t() | atom(), atom(), keyword() | map()) ::
          {:ok, State.t(), map()} | {:error, Error.t() | term()}
  def dispatch_widget_interaction(%State{} = runtime_state, widget_id, family, attrs \\ []) do
    attrs =
      attrs
      |> normalize_map()
      |> Map.put(:widget_id, widget_id)
      |> Map.put(:family, family)
      |> Map.put_new(:input_family, input_family_for(family))

    dispatch_native_event(runtime_state, attrs)
  end

  @spec handle_boundary_signal(State.t(), Signal.t() | map()) ::
          {:ok, State.t(), map()} | {:error, Error.t() | term()}
  def handle_boundary_signal(%State{} = runtime_state, signal) do
    with {:ok, translation} <- DesktopUi.Transport.from_boundary_signal(signal),
         {:ok, route_result} <- EventRouter.route(runtime_state, translation) do
      {:ok, apply_route(runtime_state, route_result), route_result}
    end
  end

  defp apply_route(%State{} = runtime_state, route_result) do
    translation = route_result.translation

    %{
      runtime_state
      | focus: apply_focus(runtime_state.focus, translation, route_result.route),
        event_loop: EventLoop.record_route(runtime_state.event_loop, route_result),
        event_log: runtime_state.event_log ++ [event_log_entry(route_result)]
    }
  end

  defp apply_focus(nil, _translation, _route), do: nil

  defp apply_focus(focus, %{family: :focus, widget_id: widget_id}, :local_runtime)
       when not is_nil(widget_id) do
    %{
      current: to_string(widget_id),
      order:
        ([to_string(widget_id)] ++ List.wrap(Map.get(focus, :order, [])))
        |> Enum.uniq()
    }
  end

  defp apply_focus(focus, _translation, _route), do: focus

  defp event_log_entry(route_result) do
    translation = route_result.translation

    %{
      route: route_result.route,
      family: route_result.family,
      input_family: route_result.input_family,
      runtime_event: route_result.runtime_event,
      boundary: route_result.boundary,
      widget_id: translation.widget_id,
      local_handling: route_result.local_handling,
      signal_type:
        case Map.get(translation, :signal) do
          %Signal{} = signal -> signal.type
          _other -> nil
        end
    }
  end

  defp input_family_for(family) when family in [:change, :submit], do: :keyboard
  defp input_family_for(:selection), do: :pointer
  defp input_family_for(:click), do: :pointer
  defp input_family_for(:navigation), do: :keyboard
  defp input_family_for(:command), do: :shortcut
  defp input_family_for(:focus), do: :focus
  defp input_family_for(:open), do: :window
  defp input_family_for(:close), do: :window
  defp input_family_for(_family), do: :keyboard

  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
end
