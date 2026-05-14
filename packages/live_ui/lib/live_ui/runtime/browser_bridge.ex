defmodule LiveUi.Runtime.BrowserBridge do
  @moduledoc """
  Bounded browser-bridge placeholders for hooks and channel integration.
  """

  @type hook :: atom()
  @supported_hooks [
    :resize_observer,
    :viewport_measurement,
    :scroll_tracking,
    :canvas_pointer,
    :split_pane_drag
  ]

  @spec supported_hooks() :: [hook()]
  def supported_hooks do
    @supported_hooks
  end

  @spec normalize_hooks([hook()]) :: [hook()]
  def normalize_hooks(hooks) when is_list(hooks) do
    hooks
    |> Enum.uniq()
    |> Enum.filter(&supported?/1)
  end

  @spec authoritative?() :: boolean()
  def authoritative?, do: false

  @spec display_hooks() :: [hook()]
  def display_hooks do
    LiveUi.Display.browser_bridge_hooks()
  end

  @spec supported?(hook()) :: boolean()
  def supported?(hook) when is_atom(hook) do
    hook in @supported_hooks
  end

  @spec normalize_payload(hook(), map()) :: {:ok, map()} | {:error, term()}
  def normalize_payload(hook, payload) when is_atom(hook) and is_map(payload) do
    with :ok <- LiveUi.Transport.Diagnostics.validate_hook_payload(hook, payload) do
      {:ok, payload_for(hook, payload)}
    end
  end

  defp payload_for(:resize_observer, payload) do
    payload
    |> normalize_map()
    |> take_keys([:width, :height])
  end

  defp payload_for(:viewport_measurement, payload) do
    payload
    |> normalize_map()
    |> take_keys([:viewport_ref, :offset_x, :offset_y, :width, :height, :sync_group])
  end

  defp payload_for(:scroll_tracking, payload) do
    payload
    |> normalize_map()
    |> take_keys([:viewport_ref, :position_start, :position_end, :axis])
  end

  defp payload_for(:canvas_pointer, payload) do
    payload
    |> normalize_map()
    |> take_keys([:canvas_id, :x, :y, :buttons, :pressure])
  end

  defp payload_for(:split_pane_drag, payload) do
    payload
    |> normalize_map()
    |> take_keys([:split_pane_id, :ratio, :divider_size])
  end

  defp normalize_map(payload) when is_map(payload) do
    Map.new(payload, fn {key, value} ->
      {normalize_key(key), value}
    end)
  end

  defp take_keys(payload, keys) do
    Map.take(payload, keys)
  end

  defp normalize_key(atom) when is_atom(atom), do: atom

  defp normalize_key(binary) when is_binary(binary) do
    try do
      String.to_existing_atom(binary)
    rescue
      ArgumentError -> String.to_atom(binary)
    end
  end
end
