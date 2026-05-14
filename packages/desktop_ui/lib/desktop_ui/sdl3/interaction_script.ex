defmodule DesktopUi.Sdl3.InteractionScript do
  @moduledoc """
  Deterministic interaction-script export for the compiled SDL3 visible runner.
  """

  @spec contract() :: map()
  def contract do
    %{
      format: :tab_separated_key_values,
      header: "DESKTOP_UI_SDL3_INTERACTION",
      version: 1,
      preserves: [
        :event_type,
        :window_target,
        :widget_target,
        :pointer_coordinates,
        :keyboard_modifiers,
        :wheel_deltas,
        :semantic_intent
      ],
      target: :compiled_visible_runner
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :interaction_script_ready

  @spec encode([map() | keyword()]) :: {:ok, String.t()}
  def encode(events) when is_list(events) do
    lines =
      [
        encode_line("DESKTOP_UI_SDL3_INTERACTION", version: 1)
      ] ++ Enum.map(events, &encode_event_line/1)

    {:ok, Enum.join(lines, "\n") <> "\n"}
  end

  @spec write([map() | keyword()], String.t()) :: {:ok, String.t()} | {:error, term()}
  def write(events, path) when is_list(events) and is_binary(path) do
    with {:ok, script} <- encode(events),
         :ok <- File.write(path, script) do
      {:ok, path}
    end
  end

  defp encode_event_line(event) when is_list(event), do: encode_event_line(Map.new(event))

  defp encode_event_line(event) when is_map(event) do
    pointer = Map.get(event, :pointer, %{})

    encode_line("EVENT",
      type: Map.get(event, :type),
      window_id: Map.get(event, :window_id),
      widget_id: Map.get(event, :widget_id),
      focus_target: Map.get(event, :focus_target),
      key: Map.get(event, :key),
      modifiers: encode_list(Map.get(event, :modifiers, [])),
      button: Map.get(event, :button),
      x: Map.get(pointer, :x, Map.get(event, :x)),
      y: Map.get(pointer, :y, Map.get(event, :y)),
      delta_x: Map.get(event, :delta_x),
      delta_y: Map.get(event, :delta_y),
      intent: Map.get(event, :intent)
    )
  end

  defp encode_list(values) when is_list(values) do
    case values |> Enum.map(&to_string/1) |> Enum.join(",") do
      "" -> nil
      encoded -> encoded
    end
  end

  defp encode_list(_values), do: nil

  defp encode_line(tag, attrs) do
    encoded_attrs =
      attrs
      |> Enum.flat_map(fn
        {_key, nil} -> []
        {_key, []} -> []
        {key, value} when is_boolean(value) -> ["#{key}=#{if(value, do: 1, else: 0)}"]
        {key, value} -> ["#{key}=#{URI.encode_www_form(to_string(value))}"]
      end)

    Enum.join([tag | encoded_attrs], "\t")
  end
end
