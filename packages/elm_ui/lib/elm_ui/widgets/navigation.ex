defmodule ElmUi.Widgets.Navigation do
  @moduledoc """
  Baseline navigation widgets for direct-use `elm_ui` screens.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:menu, :tabs]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec menu(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def menu(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:menu,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :vertical),
        active_item: Builder.option(opts, :active_item),
        items: normalize_items(items)
      },
      state: Builder.state(opts, [:disabled, :current]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_navigate: :navigation),
      metadata: Builder.metadata(opts, %{native_surface: :navigation})
    )
  end

  @spec tabs(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def tabs(id, items, opts \\ []) when is_list(items) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:tabs,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :horizontal),
        active_item: Builder.option(opts, :active_item),
        items: normalize_items(items)
      },
      state: Builder.state(opts, [:disabled, :current]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_navigate: :navigation),
      metadata: Builder.metadata(opts, %{native_surface: :navigation})
    )
  end

  defp normalize_items(items) do
    Enum.map(items, fn item ->
      item = Builder.options(item)

      %{}
      |> Builder.maybe_put(:id, Builder.option(item, :id))
      |> Builder.maybe_put(:label, Builder.option(item, :label))
      |> Builder.maybe_put(:value, Builder.option(item, :value))
      |> Builder.maybe_put(:description, Builder.option(item, :description))
      |> Builder.maybe_put(:disabled, Builder.option(item, :disabled))
      |> Builder.maybe_put(:active, Builder.option(item, :active))
    end)
  end
end
