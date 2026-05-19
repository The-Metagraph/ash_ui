defmodule DesktopUi.Widgets.Feedback do
  @moduledoc """
  Advanced overlay and feedback widgets for direct-native `desktop_ui`.
  """

  alias DesktopUi.Widget

  @spec kinds() :: [atom()]
  def kinds do
    [
      :alert_dialog,
      :dialog,
      :diff_banner,
      :inline_feedback,
      :progress,
      :sparkline,
      :status,
      :toast
    ]
  end

  @spec sparkline(String.t() | atom(), keyword()) :: Widget.t()
  def sparkline(id, opts \\ []) do
    Widget.new(:sparkline,
      id: id,
      metadata: metadata(opts, role: :sparkline),
      state:
        state(opts,
          loading: Keyword.get(opts, :loading, false)
        ),
      attributes: %{
        data: Keyword.get(opts, :data, []),
        min: Keyword.get(opts, :min),
        max: Keyword.get(opts, :max),
        color: Keyword.get(opts, :color),
        width: Keyword.get(opts, :width),
        height: Keyword.get(opts, :height),
        show_area: Keyword.get(opts, :show_area, true),
        show_dots: Keyword.get(opts, :show_dots, false)
      },
      styles: styles(opts)
    )
  end

  @spec inline_feedback(String.t() | atom(), keyword()) :: Widget.t()
  def inline_feedback(id, opts \\ []) do
    Widget.new(:inline_feedback,
      id: id,
      metadata:
        metadata(opts,
          focusable: false,
          role: :inline_feedback,
          overlay_role: :inline_feedback
        ),
      state:
        state(opts,
          open: Keyword.get(opts, :open, true),
          severity: Keyword.get(opts, :severity, :info)
        ),
      attributes: %{
        message: Keyword.get(opts, :message),
        placement: Keyword.get(opts, :placement, :bottom),
        dismissible: Keyword.get(opts, :dismissible, true),
        auto_hide: Keyword.get(opts, :auto_hide, true),
        timeout_ms: Keyword.get(opts, :timeout_ms, 3_000)
      },
      events:
        events(close: Keyword.get(opts, :on_close), dismiss: Keyword.get(opts, :on_dismiss)),
      styles: styles(opts)
    )
  end

  @spec dialog(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def dialog(id, children, opts \\ []) do
    Widget.new(:dialog,
      id: id,
      metadata:
        metadata(opts,
          role: :dialog,
          overlay_role: :dialog,
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
        ),
      state:
        state(opts,
          open: Keyword.get(opts, :open, true),
          phase: Keyword.get(opts, :phase, :active)
        ),
      slot_children: %{content: children},
      events:
        events(close: Keyword.get(opts, :on_close), dismiss: Keyword.get(opts, :on_dismiss)),
      styles: styles(opts)
    )
  end

  @spec toast(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def toast(id, message, opts \\ []) do
    Widget.new(:toast,
      id: id,
      metadata:
        metadata(opts,
          role: :toast,
          overlay_role: :toast,
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :ephemeral)
        ),
      state:
        state(opts,
          open: Keyword.get(opts, :open, true),
          severity: Keyword.get(opts, :severity, :info)
        ),
      attributes: %{message: message, timeout_ms: Keyword.get(opts, :timeout_ms, 3_000)},
      events: events(close: Keyword.get(opts, :on_close)),
      styles: styles(opts)
    )
  end

  @spec alert_dialog(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def alert_dialog(id, message, children, opts \\ []) do
    Widget.new(:alert_dialog,
      id: id,
      metadata:
        metadata(opts,
          role: :alert_dialog,
          overlay_role: :alert_dialog,
          overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
        ),
      state:
        state(opts,
          open: Keyword.get(opts, :open, true),
          severity: Keyword.get(opts, :severity, :warning)
        ),
      attributes: %{message: message},
      slot_children: %{content: children},
      events:
        events(close: Keyword.get(opts, :on_close), dismiss: Keyword.get(opts, :on_dismiss)),
      styles: styles(opts)
    )
  end

  @spec progress(String.t() | atom(), keyword()) :: Widget.t()
  def progress(id, opts \\ []) do
    Widget.new(:progress,
      id: id,
      metadata: metadata(opts, role: :progress),
      state:
        state(opts,
          progress: Keyword.get(opts, :current),
          loading: Keyword.get(opts, :loading, false),
          severity: Keyword.get(opts, :severity)
        ),
      bindings: bindings(value: Keyword.get(opts, :binding)),
      attributes: %{
        current: Keyword.get(opts, :current),
        total: Keyword.get(opts, :total),
        indeterminate: Keyword.get(opts, :indeterminate, false),
        label: Keyword.get(opts, :label)
      },
      styles: styles(opts)
    )
  end

  @spec status(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def status(id, label, opts \\ []) do
    Widget.new(:status,
      id: id,
      metadata: metadata(opts, role: :status),
      state:
        state(opts,
          active: Keyword.get(opts, :active, true),
          severity: Keyword.get(opts, :severity, :info)
        ),
      attributes: %{
        label: label,
        status: Keyword.get(opts, :status, :idle),
        icon: Keyword.get(opts, :icon)
      },
      styles: styles(opts)
    )
  end

  @spec diff_banner(String.t() | atom(), keyword()) :: Widget.t()
  def diff_banner(id, opts \\ []) do
    Widget.new(:diff_banner,
      id: id,
      metadata: metadata(opts, role: :radiogroup),
      state:
        state(opts,
          active_filter: Keyword.get(opts, :active_filter, :all),
          size: Keyword.get(opts, :size, :default)
        ),
      attributes: %{
        new_count: Keyword.get(opts, :new_count, 0),
        changed_count: Keyword.get(opts, :changed_count, 0),
        removed_count: Keyword.get(opts, :removed_count, 0),
        base_label: Keyword.get(opts, :base_label),
        show_filter_chips?: Keyword.get(opts, :show_filter_chips?, true),
        chips: Keyword.get(opts, :chips, [])
      },
      events: events(filter: Keyword.get(opts, :on_filter)),
      styles: styles(opts)
    )
  end

  defp metadata(opts, defaults),
    do: defaults |> Keyword.merge(Keyword.get(opts, :metadata, [])) |> Map.new()

  defp state(opts, defaults),
    do:
      defaults
      |> Keyword.merge(disabled: Keyword.get(opts, :disabled, false), focused: false)
      |> Map.new()

  defp bindings(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp events(entries), do: entries |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))
end
