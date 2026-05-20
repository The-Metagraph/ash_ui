defmodule ElmUi.Widgets.Feedback do
  @moduledoc """
  Advanced feedback widgets for status-heavy and progress-heavy `elm_ui`
  workflows.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:status, :progress, :inline_feedback, :diff_banner]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec status(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def status(id, text, opts \\ []) when is_binary(text) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:status,
      id: id,
      attributes: %{
        text: text,
        severity: Builder.option(opts, :severity, :info),
        status: Builder.option(opts, :status, :idle),
        icon: Builder.option(opts, :icon)
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :feedback})
    )
  end

  @spec progress(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def progress(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:progress,
      id: id,
      attributes: %{
        current: Builder.option(opts, :current),
        total: Builder.option(opts, :total),
        indeterminate: Builder.option(opts, :indeterminate, false),
        label: Builder.option(opts, :label),
        severity: Builder.option(opts, :severity),
        status: Builder.option(opts, :status)
      },
      state: Builder.state(opts, [:disabled, :loading]),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :feedback})
    )
  end

  @spec inline_feedback(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def inline_feedback(id, message, opts \\ []) when is_binary(message) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:inline_feedback,
      id: id,
      attributes: %{
        title: Builder.option(opts, :title),
        message: message,
        severity: Builder.option(opts, :severity, :info),
        status: Builder.option(opts, :status)
      },
      state: Builder.state(opts, [:disabled]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_close: :close),
      metadata: Builder.metadata(opts, %{native_surface: :feedback})
    )
  end

  @spec diff_banner(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def diff_banner(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:diff_banner,
      id: id,
      attributes: %{
        new_count: Builder.option(opts, :new_count, 0),
        changed_count: Builder.option(opts, :changed_count, 0),
        removed_count: Builder.option(opts, :removed_count, 0),
        base_label: Builder.option(opts, :base_label),
        show_filter_chips?: Builder.option(opts, :show_filter_chips?, true)
      },
      state: %{
        active_filter: Builder.option(opts, :active_filter, :all),
        size: Builder.option(opts, :size, :default)
      },
      events: Builder.events(opts, on_filter: :selection),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :feedback})
    )
  end
end
