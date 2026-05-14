defmodule DesktopUi.Sdl3.FrameScript do
  @moduledoc """
  Visible-frame script export for the compiled SDL3 host runner.
  """

  alias DesktopUi.Sdl3.RenderPlan

  @spec contract() :: map()
  def contract do
    %{
      format: :tab_separated_key_values,
      header: "DESKTOP_UI_SDL3_FRAME",
      version: 1,
      preserves: [
        :window_titles,
        :logical_bounds,
        :draw_kinds,
        :resolved_styles,
        :resource_descriptors,
        :interaction_contract,
        :clip_flags,
        :visual_state,
        :metrics,
        :clip_bounds
      ],
      target: :compiled_visible_runner
    }
  end

  @spec validation_state() :: atom()
  def validation_state, do: :frame_script_ready

  @spec encode(RenderPlan.t()) :: {:ok, String.t()}
  def encode(%RenderPlan{} = plan) do
    lines =
      [
        encode_line("DESKTOP_UI_SDL3_FRAME", version: 1),
        encode_line("RUNTIME", runtime_id: plan.runtime_id, screen_id: plan.screen_id)
      ] ++
        Enum.flat_map(plan.windows, &encode_window_lines/1)

    {:ok, Enum.join(lines, "\n") <> "\n"}
  end

  @spec write(RenderPlan.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def write(%RenderPlan{} = plan, path) when is_binary(path) do
    with {:ok, script} <- encode(plan),
         :ok <- File.write(path, script) do
      {:ok, path}
    end
  end

  defp encode_window_lines(window) do
    window_line =
      encode_line("WINDOW",
        window_id: window.window_id,
        title: window.title,
        role: window.role,
        x: get_in(window, [:logical_bounds, :x]),
        y: get_in(window, [:logical_bounds, :y]),
        width: get_in(window, [:logical_bounds, :width]),
        height: get_in(window, [:logical_bounds, :height]),
        units: get_in(window, [:logical_bounds, :units])
      )

    draw_lines =
      Enum.map(window.draw_operations, fn operation ->
        encode_line("DRAW",
          window_id: window.window_id,
          order: operation[:order] || 0,
          widget_id: operation.widget_id,
          kind: operation.kind,
          family: operation.family,
          draw_kind: operation.draw_kind,
          x: get_in(operation, [:logical_bounds, :x]),
          y: get_in(operation, [:logical_bounds, :y]),
          width: get_in(operation, [:logical_bounds, :width]),
          height: get_in(operation, [:logical_bounds, :height]),
          units: get_in(operation, [:logical_bounds, :units]),
          clip: operation.clip?,
          clip_x: get_in(operation, [:clip_bounds, :x]),
          clip_y: get_in(operation, [:clip_bounds, :y]),
          clip_width: get_in(operation, [:clip_bounds, :width]),
          clip_height: get_in(operation, [:clip_bounds, :height]),
          bg: get_in(operation, [:resolved_styles, :bg]),
          fg: get_in(operation, [:resolved_styles, :fg]),
          border: get_in(operation, [:resolved_styles, :border]),
          variant: get_in(operation, [:resolved_styles, :variant]),
          attrs: encode_attrs(get_in(operation, [:resolved_styles, :attrs])),
          semantic_role: operation.semantic_role,
          layer_role: operation.layer_role,
          resource_kind: get_in(operation, [:resource, :kind]),
          image_source: get_in(operation, [:resource, :source]),
          focusable: get_in(operation, [:interaction, :focusable]),
          shortcut: get_in(operation, [:interaction, :shortcut]),
          shortcut_intent: get_in(operation, [:interaction, :shortcut_intent]),
          click_intent: get_in(operation, [:interaction, :click_intent]),
          submit_intent: get_in(operation, [:interaction, :submit_intent]),
          selection_intent: get_in(operation, [:interaction, :selection_intent]),
          command_intent: get_in(operation, [:interaction, :command_intent]),
          close_intent: get_in(operation, [:interaction, :close_intent]),
          navigation_intent: get_in(operation, [:interaction, :navigation_intent]),
          window_identity: get_in(operation, [:interaction, :window_identity]),
          overlay_role: get_in(operation, [:interaction, :overlay_role]),
          selection_mode: get_in(operation, [:interaction, :selection_mode]),
          disabled: get_in(operation, [:visual_state, :disabled]),
          focused: get_in(operation, [:visual_state, :focused]),
          selected: get_in(operation, [:visual_state, :selected]),
          checked: get_in(operation, [:visual_state, :checked]),
          active: get_in(operation, [:visual_state, :active]),
          open: get_in(operation, [:visual_state, :open]),
          current: get_in(operation, [:visual_state, :current]),
          loading: get_in(operation, [:visual_state, :loading]),
          child_count: get_in(operation, [:metrics, :child_count]),
          item_count: get_in(operation, [:metrics, :item_count]),
          row_count: get_in(operation, [:metrics, :row_count]),
          column_count: get_in(operation, [:metrics, :column_count]),
          series_count: get_in(operation, [:metrics, :series_count]),
          current_index: get_in(operation, [:metrics, :current_index]),
          selected_index: get_in(operation, [:metrics, :selected_index]),
          value: get_in(operation, [:metrics, :value]),
          max_value: get_in(operation, [:metrics, :max_value]),
          content_length: get_in(operation, [:metrics, :content_length]),
          content: operation.content
        )
      end)

    [window_line | draw_lines]
  end

  defp encode_attrs(attrs) when is_list(attrs) do
    case attrs |> Enum.map(&to_string/1) |> Enum.join(",") do
      "" -> nil
      encoded -> encoded
    end
  end

  defp encode_attrs(_attrs), do: nil

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
