defmodule DesktopUi.Runtime.Boot do
  @moduledoc """
  Runtime boot helpers for the `desktop_ui` Phase 1 backbone.
  """

  alias DesktopUi.Navigation.Controller
  alias DesktopUi.Platform
  alias DesktopUi.Runtime.{Error, EventLoop, Realization, Screen, State, StyleResolver, Window}
  alias DesktopUi.Widget

  @required_screen_keys [:id, :title, :root]

  @spec prepare_native_screen(map(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def prepare_native_screen(screen, opts \\ []) do
    with :ok <- validate_screen(screen),
         {:ok, root} <- normalize_root(Map.fetch!(screen, :root)) do
      build_state(Map.put(screen, :root, root), :native, opts)
    end
  end

  @spec prepare_rendered_screen(Widget.t() | map(), keyword()) ::
          {:ok, State.t()} | {:error, Error.t()}
  def prepare_rendered_screen(rendered_root, opts \\ []) do
    with {:ok, root} <- normalize_root(rendered_root) do
      build_state(
        %{
          id: Keyword.get(opts, :screen_id, "canonical-screen"),
          title: Keyword.get(opts, :title, "Canonical Screen"),
          root: root
        },
        :canonical,
        opts
      )
    end
  end

  @spec start_navigation_controller(State.t(), keyword()) :: {:ok, State.t()} | {:error, term()}
  def start_navigation_controller(state, opts \\ []) do
    registry = Keyword.get(opts, :registry)
    initial_screen = Keyword.get(opts, :initial_screen)

    cond do
      !registry && !initial_screen ->
        # No navigation needed
        {:ok, state}

      initial_screen ->
        screen_module = elem(initial_screen, 1)
        params = elem(initial_screen, 2)

        case Controller.start_link(
               name: nil,
               registry: registry,
               initial_screen: initial_screen
             ) do
          {:ok, controller} ->
            nav_state = Controller.get_state(controller)

            {:ok,
             %{
               state
               | navigation_controller: controller,
                 current_screen_module: screen_module,
                 navigation_state: nav_state,
                 screen_params: params
             }}

          {:error, reason} ->
            {:error, Error.new(:navigation_controller_start_failed, %{reason: reason}, :runtime_boot)}
        end

      true ->
        {:ok, state}
    end
  end

  defp build_state(screen, source_kind, opts) do
    with {:ok, %{target: platform_target, adapter: adapter}} <- Platform.select(opts) do
      screen_model =
        Screen.new(screen, source_kind, Keyword.put(opts, :platform_target, platform_target))

      with {:ok, realization} <- Realization.realize_screen(screen_model, opts) do
        realization = StyleResolver.resolve_screen(screen_model, realization, opts)
        windows = Window.register_all(screen_model, opts)

        {:ok,
         %State{
           runtime_id: Keyword.get(opts, :runtime_id, "desktop-ui:#{screen_model.id}"),
           screen_id: screen_model.id,
           title: screen_model.title,
           source_kind: source_kind,
           platform_target: platform_target,
           platform_adapter: adapter.summary(),
           root: screen_model.root,
           screen: screen_model,
           windows: windows,
           focus: %{
             current:
               realization.current_focus ||
                 windows.primary
                 |> then(&Map.fetch!(windows.registry, &1))
                 |> Window.primary_focus_target(),
             order: realization.focus_order
           },
           redraw: %{
             status: :idle,
             requests: 0,
             pending_reason: nil
           },
           realization:
             Map.merge(realization, %{
               mode: :shared_sdl_runtime,
               root_kind: screen_model.root.kind,
               window_id: windows.primary
             }),
           event_loop:
             EventLoop.scaffold(platform_target: platform_target, screen_id: screen_model.id),
           lifecycle: %{
             boot: :initialized,
             runtime: :ready,
             shutdown: :idle
           },
           validation_state: :runtime_backbone_ready
         }}
      end
    else
      {:error, {:unsupported_platform_target, target}} ->
        {:error,
         Error.new(:unsupported_platform_target, %{platform_target: target}, :runtime_boot)}

      {:error, {:invalid_platform_adapter, target}} ->
        {:error, Error.new(:invalid_platform_adapter, %{platform_target: target}, :runtime_boot)}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp validate_screen(screen) when is_map(screen) do
    missing_keys =
      Enum.reject(@required_screen_keys, fn key ->
        value = Map.get(screen, key)
        not is_nil(value)
      end)

    cond do
      missing_keys != [] ->
        {:error, Error.new(:invalid_screen, %{missing_keys: missing_keys}, :runtime_boot)}

      true ->
        :ok
    end
  end

  defp normalize_root(%Widget{} = root), do: {:ok, root}

  defp normalize_root(%{kind: kind} = root) when is_atom(kind) do
    {:ok,
     %Widget{
       id: Map.get(root, :id),
       kind: kind,
       family: Map.get(root, :family, Widget.family_for(kind)),
       metadata: Map.get(root, :metadata, %{}),
       state: Map.get(root, :state, %{}),
       bindings: Map.get(root, :bindings, %{}),
       slots: Map.get(root, :slots, [:default]),
       slot_children: Map.get(root, :slot_children, %{}),
       attributes: Map.get(root, :attributes, %{}),
       styles: Map.get(root, :styles, %{}),
       events: Map.get(root, :events, %{}),
       children: Map.get(root, :children, [])
     }}
  end

  defp normalize_root(root) do
    {:error, Error.new(:invalid_screen_root, %{root: root}, :runtime_boot)}
  end
end
