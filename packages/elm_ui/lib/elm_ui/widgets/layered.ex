defmodule ElmUi.Widgets.Layered do
  @moduledoc """
  Native layered composition widgets for dialogs, toasts, overlays, and
  context-sensitive web surfaces.
  """

  alias ElmUi.Widgets.{Builder, Navigation}

  @kinds [:overlay, :dialog, :toast, :alert_dialog, :context_menu]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec overlay(
          String.t() | atom(),
          ElmUi.Widget.t() | map() | keyword(),
          [ElmUi.Widget.t() | map() | keyword()],
          keyword() | map()
        ) :: ElmUi.Widget.t()
  def overlay(id, base, layers, opts \\ []) when is_list(layers) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))
    base = Builder.child!(base)
    layers = Builder.children!(layers)

    validate_layers!(layers)

    Builder.widget(:overlay,
      id: id,
      attributes: %{
        mode: Builder.option(opts, :mode, :stacked),
        background_fill: Builder.option(opts, :background_fill, :transparent),
        dismissible: Builder.option(opts, :dismissible, true),
        focus_scope: Builder.option(opts, :focus_scope),
        z_order: Builder.option(opts, :z_order, :overlay)
      },
      slot_children:
        Builder.slot_map([
          {:base, base},
          {:layers, layers}
        ]),
      state: layer_state(opts),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_open: :open, on_close: :close, on_dismiss: :dismiss),
      metadata: Builder.metadata(opts, %{native_surface: :layer, layered: true})
    )
  end

  @spec dialog(String.t() | atom(), ElmUi.Widget.t() | map() | keyword(), keyword() | map()) ::
          ElmUi.Widget.t()
  def dialog(id, content, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:dialog,
      id: id,
      attributes: %{
        title: Builder.option(opts, :title),
        modal: Builder.option(opts, :modal, true),
        dismissible: Builder.option(opts, :dismissible, true),
        size: Builder.option(opts, :size, :md),
        background_fill: Builder.option(opts, :background_fill, :scrim),
        focus_scope: Builder.option(opts, :focus_scope, :dialog)
      },
      slot_children: Builder.slot_map([{:content, content}]),
      state: layer_state(opts),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_close: :close, on_dismiss: :dismiss),
      metadata: Builder.metadata(opts, %{native_surface: :layer, layered: true})
    )
  end

  @spec toast(String.t() | atom(), ElmUi.Widget.t() | map() | keyword(), keyword() | map()) ::
          ElmUi.Widget.t()
  def toast(id, content, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:toast,
      id: id,
      attributes: %{
        placement: Builder.option(opts, :placement, :top_end),
        duration_ms: Builder.option(opts, :duration_ms, 5_000),
        severity: Builder.option(opts, :severity, :info),
        transient: Builder.option(opts, :transient, true)
      },
      slot_children: Builder.slot_map([{:content, content}]),
      state: layer_state(opts),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_close: :close, on_dismiss: :dismiss),
      metadata: Builder.metadata(opts, %{native_surface: :layer, layered: true})
    )
  end

  @spec alert_dialog(
          String.t() | atom(),
          ElmUi.Widget.t() | map() | keyword(),
          keyword() | map()
        ) :: ElmUi.Widget.t()
  def alert_dialog(id, content, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:alert_dialog,
      id: id,
      attributes: %{
        title: Builder.option(opts, :title),
        severity: Builder.option(opts, :severity, :warning),
        requires_confirmation: Builder.option(opts, :requires_confirmation, true),
        background_fill: Builder.option(opts, :background_fill, :scrim),
        focus_scope: Builder.option(opts, :focus_scope, :alert_dialog)
      },
      slot_children: Builder.slot_map([{:content, content}]),
      state: layer_state(opts),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_close: :close, on_dismiss: :dismiss),
      metadata: Builder.metadata(opts, %{native_surface: :layer, layered: true})
    )
  end

  @spec context_menu(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def context_menu(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    menu =
      Navigation.menu(
        Builder.option(opts, :menu_id, "#{id}-menu"),
        items,
        orientation: :vertical,
        active_item: Builder.option(opts, :active_item)
      )

    Builder.widget(:context_menu,
      id: id,
      attributes: %{
        anchor: Builder.option(opts, :anchor, %{}),
        placement: Builder.option(opts, :placement, :bottom_start),
        dismissible: Builder.option(opts, :dismissible, true),
        background_fill: Builder.option(opts, :background_fill, :none)
      },
      slot_children: Builder.slot_map([{:menu, menu}]),
      state: layer_state(opts),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_close: :close, on_dismiss: :dismiss),
      metadata: Builder.metadata(opts, %{native_surface: :layer, layered: true})
    )
  end

  defp validate_layers!([]) do
    raise ArgumentError, "elm_ui overlay widgets require at least one layer widget"
  end

  defp validate_layers!(layers) do
    if Enum.any?(layers, &(&1.family != :layer)) do
      raise ArgumentError,
            "elm_ui overlay widgets require every overlay layer to use the :layer family"
    end
  end

  defp layer_state(opts) do
    opts
    |> Builder.state([:disabled, :open, :focused])
    |> Map.put(:open, Builder.option(opts, :open, true))
  end
end
