defmodule LiveUi.Widgets.DiffBanner do
  @moduledoc """
  Native comparison banner widget.
  """

  use LiveUi.Component,
    family: :feedback,
    name: :diff_banner,
    events: [:selection]

  LiveUi.Component.common_attrs()
  attr(:new_count, :integer, default: 0)
  attr(:changed_count, :integer, default: 0)
  attr(:removed_count, :integer, default: 0)
  attr(:base_label, :string, default: nil)
  attr(:active_filter, :any, default: :all)
  attr(:show_filter_chips?, :boolean, default: true)
  attr(:size, :any, default: :default)
  attr(:chips, :list, default: [])

  @impl true
  def render(assigns) do
    chips = if assigns.chips == [], do: default_chips(assigns), else: assigns.chips

    assigns =
      assigns
      |> assign(:chips, chips)
      |> assign(:size_name, to_string(assigns.size))

    ~H"""
    <aside
      id={@id}
      class={["live-ui-diff-banner", "live-ui-diff-banner--#{@size_name}", @class]}
      data-live-ui-widget="diff-banner"
      data-active-filter={to_string(@active_filter)}
      data-live-ui-size={@size_name}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      {@rest}
    >
      <span :if={@base_label && @size_name != "compact"} class="live-ui-diff-banner__base">
        {@base_label}
      </span>

      <div
        class="live-ui-diff-banner__chips"
        role={if @show_filter_chips?, do: "radiogroup", else: nil}
      >
        <%= for chip <- @chips do %>
          <button
            :if={@show_filter_chips?}
            type="button"
            class={[
              "live-ui-diff-banner__chip",
              "live-ui-diff-banner__chip--#{chip_kind(chip)}",
              chip_active?(chip, @active_filter) && "live-ui-diff-banner__chip--active"
            ]}
            role="radio"
            aria-checked={to_string(chip_active?(chip, @active_filter))}
            data-filter-kind={chip_kind(chip)}
            {chip_attrs(chip)}
          >
            {chip_label(chip)}
          </button>

          <span
            :if={!@show_filter_chips?}
            class={[
              "live-ui-diff-banner__chip",
              "live-ui-diff-banner__chip--#{chip_kind(chip)}",
              "live-ui-diff-banner__chip--static",
              chip_active?(chip, @active_filter) && "live-ui-diff-banner__chip--active"
            ]}
            data-filter-kind={chip_kind(chip)}
          >
            {chip_label(chip)}
          </span>
        <% end %>
      </div>
    </aside>
    """
  end

  defp default_chips(assigns) do
    [
      %{kind: :all, count: total_count(assigns), label: "all"},
      %{kind: :new, count: assigns.new_count, label: "new"},
      %{kind: :changed, count: assigns.changed_count, label: "changed"},
      %{kind: :removed, count: assigns.removed_count, label: "removed"}
    ]
  end

  defp total_count(assigns), do: assigns.new_count + assigns.changed_count + assigns.removed_count

  defp chip_kind(chip), do: chip |> fetch(:kind, :all) |> to_string()
  defp chip_label(chip), do: "#{fetch(chip, :count, 0)} #{fetch(chip, :label, chip_kind(chip))}"
  defp chip_attrs(chip), do: fetch(chip, :attrs, %{})

  defp chip_active?(chip, active_filter) do
    chip_kind(chip) == to_string(active_filter)
  end

  defp fetch(source, key, default) when is_map(source), do: Map.get(source, key, default)
  defp fetch(source, key, default) when is_list(source), do: Keyword.get(source, key, default)
  defp fetch(_source, _key, default), do: default
end
