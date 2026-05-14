defmodule DesktopUi.Sdl3.Window do
  @moduledoc """
  SDL3-native window registry and ownership helpers.
  """

  alias DesktopUi.Runtime.{Error, State}
  alias DesktopUi.Widget

  @transient_layer_kinds [:overlay, :context_menu, :popover, :dialog]

  @spec registry(State.t()) :: {:ok, map()} | {:error, Error.t()}
  def registry(%State{} = runtime_state) do
    ownership = collect_ownership(runtime_state.root, nil, %{}, [])

    cond do
      ownership.orphaned_layers != [] ->
        {:error,
         Error.new(
           :orphaned_transient_layer,
           %{layer_ids: ownership.orphaned_layers},
           :sdl3_window
         )}

      not Map.has_key?(runtime_state.windows.registry, runtime_state.windows.primary) ->
        {:error,
         Error.new(
           :invalid_native_window_registry,
           %{primary_window_id: runtime_state.windows.primary},
           :sdl3_window
         )}

      true ->
        sessions =
          runtime_state.windows.registry
          |> Enum.sort_by(fn {window_id, _window} -> window_id end)
          |> Enum.map(fn {window_id, window} ->
            ownership_entry =
              ownership_entry(runtime_state, ownership.windows, window_id, window.window_identity)

            %{
              id: window_id,
              title: window.title,
              role: window.role,
              window_identity: window.window_identity,
              focus_order: window.focus_order,
              platform_target: window.platform_target,
              lifecycle: window.lifecycle,
              native_window?: true,
              owned_widget_ids: ownership_entry.widget_ids,
              transient_layers: ownership_entry.layers,
              owned_layer_ids: Enum.map(ownership_entry.layers, & &1.widget_id)
            }
          end)

        {:ok,
         %{
           primary_id: runtime_state.windows.primary,
           continuity: runtime_state.windows.continuity,
           sessions: sessions,
           validation_state: :native_window_registry_ready
         }}
    end
  end

  defp ownership_entry(%State{} = runtime_state, ownership_windows, window_id, window_identity) do
    root_window_id = if runtime_state.root.kind == :window, do: "window:#{runtime_state.root.id}"
    identity_window_id = if is_binary(window_identity), do: "window:#{window_identity}"

    ownership_windows
    |> Map.get(window_id)
    |> case do
      nil ->
        ownership_windows
        |> Map.get(root_window_id)
        |> Kernel.||(Map.get(ownership_windows, identity_window_id))
        |> Kernel.||(%{widget_ids: [], layers: []})

      entry ->
        entry
    end
  end

  @spec validate_transition(map(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def validate_transition(registry, source_window_id, target_window_id)
      when is_map(registry) and is_binary(source_window_id) and is_binary(target_window_id) do
    known_ids =
      registry
      |> Map.get(:sessions, [])
      |> Enum.map(& &1.id)

    cond do
      source_window_id == target_window_id ->
        :ok

      source_window_id not in known_ids ->
        {:error,
         Error.new(
           :invalid_window_transition,
           %{source_window_id: source_window_id, target_window_id: target_window_id},
           :sdl3_window
         )}

      target_window_id not in known_ids ->
        {:error,
         Error.new(
           :invalid_window_transition,
           %{source_window_id: source_window_id, target_window_id: target_window_id},
           :sdl3_window
         )}

      true ->
        :ok
    end
  end

  defp collect_ownership(%Widget{} = widget, current_window_id, windows, orphaned_layers) do
    current_window_id =
      if widget.kind == :window do
        "window:#{widget.id}"
      else
        current_window_id
      end

    windows =
      if is_binary(current_window_id) do
        Map.update(
          windows,
          current_window_id,
          %{widget_ids: [to_string(widget.id)], layers: []},
          fn entry ->
            update_in(entry.widget_ids, &Enum.uniq(&1 ++ [to_string(widget.id)]))
          end
        )
      else
        windows
      end

    {windows, orphaned_layers} =
      cond do
        widget.kind in @transient_layer_kinds and is_binary(current_window_id) ->
          windows =
            Map.update!(windows, current_window_id, fn entry ->
              Map.update!(entry, :layers, fn layers ->
                layers ++
                  [
                    %{
                      widget_id: to_string(widget.id),
                      kind: widget.kind,
                      role: Map.get(widget.metadata, :overlay_role, widget.kind)
                    }
                  ]
              end)
            end)

          {windows, orphaned_layers}

        widget.kind in @transient_layer_kinds ->
          {windows, orphaned_layers ++ [to_string(widget.id)]}

        true ->
          {windows, orphaned_layers}
      end

    Enum.reduce(widget.children, %{windows: windows, orphaned_layers: orphaned_layers}, fn child, acc ->
      collect_ownership(child, current_window_id, acc.windows, acc.orphaned_layers)
    end)
  end
end
