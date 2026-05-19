defmodule DesktopUi.Renderer do
  @moduledoc """
  Canonical renderer entrypoint for `desktop_ui`.
  """

  alias DesktopUi.Renderer.Error
  alias DesktopUi.Renderer.Mapper
  alias UnifiedIUR.Element

  @spec accepts() :: module()
  def accepts, do: Element

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :accept_canonical_iur,
      :foundational_canonical_mapping,
      :advanced_canonical_mapping,
      :reuse_native_runtime_model,
      :shared_runtime_realization,
      :layered_meaning_preservation
    ]
  end

  @doc """
  All 45 canonical IUR widget kinds supported by the desktop_ui renderer.
  Each kind has dedicated native widget mapping, draw kind handling, and
  SDL3 rendering implementation.
  """
  @spec supported_kinds() :: [atom()]
  def supported_kinds do
    # Foundational (13)
    # Input (10)
    # Navigation (4)
    # Data (7)
    # Feedback (6)
    # Operational (7)
    # Visualization (5)
    # Layout & Structure (3)
    # Container (1)
    ([
       :badge,
       :button,
       :command,
       :content,
       :hero,
       :icon,
       :image,
       :label,
       :link,
       :separator,
       :spacer,
       :text,
       :toggle,
       :checkbox,
       :date_input,
       :file_input,
       :numeric_input,
       :pick_list,
       :radio_group,
       :select,
       :slider,
       :text_input,
       :time_input,
       :breadcrumbs,
       :list,
       :menu,
       :tabs,
       :inspector,
       :info_list,
       :key_value,
       :markdown_viewer,
       :stat,
       :table,
       :tree_view,
       :alert_dialog,
       :dialog,
       :inline_feedback,
       :progress,
       :status,
       :toast,
       :cluster_dashboard,
       :command_palette,
       :confidence_indicator,
       :log_viewer,
       :process_monitor,
       :stream_widget,
       :supervision_tree_viewer,
       :window_command,
       :bar_chart,
       :canvas,
       :gauge,
       :line_chart,
       :timeline,
       :column,
       :row,
       :stack,
       :window
     ] ++ UnifiedIUR.Widgets.Components.kinds())
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec validation_state() :: atom()
  def validation_state, do: :advanced_mapper_ready

  @spec render(Element.t(), keyword()) :: {:ok, DesktopUi.Widget.t()} | {:error, Error.t()}
  def render(%Element{} = element, _opts \\ []) do
    Mapper.map(element)
  end
end
