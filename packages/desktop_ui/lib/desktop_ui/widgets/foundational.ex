defmodule DesktopUi.Widgets.Foundational do
  @moduledoc """
  Foundational content and action widgets for direct-native `desktop_ui`.
  """

  alias DesktopUi.Widget

  @spec kinds() :: [atom()]
  def kinds do
    [
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
      :toggle
    ]
  end

  @spec text(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def text(id, content, opts \\ []) do
    Widget.new(:text,
      id: id,
      metadata: metadata(opts, focusable: false, role: :text),
      state: state(opts),
      attributes: %{content: content},
      styles: styles(opts)
    )
  end

  @spec label(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def label(id, content, opts \\ []) do
    Widget.new(:label,
      id: id,
      metadata: metadata(opts, focusable: false, role: :label),
      state: state(opts),
      attributes: %{content: content},
      styles: styles(opts)
    )
  end

  @spec icon(String.t() | atom(), atom() | String.t(), keyword()) :: Widget.t()
  def icon(id, name, opts \\ []) do
    Widget.new(:icon,
      id: id,
      metadata: metadata(opts, focusable: false, role: :icon),
      state: state(opts),
      attributes: %{
        icon: name,
        content: Keyword.get(opts, :fallback_text, "[icon]")
      },
      styles: styles(opts)
    )
  end

  @spec image(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def image(id, source, opts \\ []) do
    Widget.new(:image,
      id: id,
      metadata: metadata(opts, focusable: false, role: :image),
      state: state(opts),
      attributes: %{
        source: source,
        alt: Keyword.get(opts, :alt, "")
      },
      styles: styles(opts)
    )
  end

  @spec spacer(String.t() | atom(), keyword()) :: Widget.t()
  def spacer(id, opts \\ []) do
    Widget.new(:spacer,
      id: id,
      metadata: metadata(opts, focusable: false, role: :spacer),
      state: state(opts),
      attributes: %{size: Keyword.get(opts, :size, :md)},
      styles: styles(opts)
    )
  end

  @spec separator(String.t() | atom(), keyword()) :: Widget.t()
  def separator(id, opts \\ []) do
    Widget.new(:separator,
      id: id,
      metadata: metadata(opts, focusable: false, role: :separator),
      state: state(opts),
      attributes: %{orientation: Keyword.get(opts, :orientation, :horizontal)},
      styles: styles(opts)
    )
  end

  @spec badge(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def badge(id, content, opts \\ []) do
    Widget.new(:badge,
      id: id,
      metadata: metadata(opts, focusable: false, role: :badge),
      state: state(opts),
      attributes: %{
        content: content,
        size: Keyword.get(opts, :size, :md),
        variant: Keyword.get(opts, :variant, :default)
      },
      styles: styles(opts)
    )
  end

  @spec hero(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def hero(id, headline, opts \\ []) do
    Widget.new(:hero,
      id: id,
      metadata: metadata(opts, focusable: false, role: :hero),
      state: state(opts),
      attributes: %{
        headline: headline,
        subheadline: Keyword.get(opts, :subheadline),
        image: Keyword.get(opts, :image),
        actions: Keyword.get(opts, :actions, [])
      },
      styles: styles(opts)
    )
  end

  @spec content(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def content(id, children, opts \\ []) do
    Widget.new(:content,
      id: id,
      metadata: metadata(opts, focusable: false, role: :content_container),
      state: state(opts),
      attributes: %{
        gap: Keyword.get(opts, :gap, 12),
        align: Keyword.get(opts, :align, :start)
      },
      styles: styles(opts),
      children: children
    )
  end

  @spec button(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def button(id, label, opts \\ []) do
    Widget.new(:button,
      id: id,
      metadata: metadata(opts, focusable: true, role: :button),
      state: state(opts, active: Keyword.get(opts, :active, false)),
      attributes: %{label: label},
      styles: styles(opts),
      events:
        %{
          click: event_payload(opts, :on_click, %{intent: Keyword.get(opts, :intent, :activate)}),
          shortcut: shortcut_event(opts)
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
    )
  end

  @spec toggle(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def toggle(id, label, opts \\ []) do
    Widget.new(:toggle,
      id: id,
      metadata: metadata(opts, focusable: true, role: :toggle),
      state:
        state(opts,
          checked: Keyword.get(opts, :checked, false),
          active: Keyword.get(opts, :checked, false)
        ),
      bindings: %{checked: Keyword.get(opts, :binding, :checked)},
      attributes: %{label: label},
      styles: styles(opts),
      events: %{
        change:
          event_payload(opts, :on_change, %{intent: Keyword.get(opts, :intent, :toggle_value)})
      }
    )
  end

  @spec link(String.t() | atom(), String.t(), String.t(), keyword()) :: Widget.t()
  def link(id, label, href, opts \\ []) do
    Widget.new(:link,
      id: id,
      metadata: metadata(opts, focusable: true, role: :link),
      state: state(opts),
      attributes: %{label: label, href: href},
      styles: styles(opts),
      events: %{
        click: event_payload(opts, :on_follow, %{intent: Keyword.get(opts, :intent, :open_link)})
      }
    )
  end

  @spec command(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def command(id, label, opts \\ []) do
    Widget.new(:command,
      id: id,
      metadata:
        metadata(opts,
          focusable: true,
          role: :command,
          shortcut: Keyword.get(opts, :shortcut),
          shortcut_scope: Keyword.get(opts, :shortcut_scope, :screen)
        ),
      state: state(opts),
      attributes: %{label: label},
      styles: styles(opts),
      events:
        %{
          click:
            event_payload(opts, :on_press, %{intent: Keyword.get(opts, :intent, :run_command)}),
          shortcut: shortcut_event(opts)
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
    )
  end

  defp metadata(opts, defaults) do
    defaults
    |> Keyword.merge(Keyword.get(opts, :metadata, []))
    |> Map.new()
  end

  defp state(opts, defaults \\ []) do
    defaults
    |> Keyword.merge(disabled: Keyword.get(opts, :disabled, false), focused: false)
    |> Map.new()
  end

  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))

  defp event_payload(opts, key, fallback) do
    Keyword.get(opts, key, fallback)
  end

  defp shortcut_event(opts) do
    shortcut = Keyword.get(opts, :shortcut)

    if is_nil(shortcut) do
      nil
    else
      %{
        key: shortcut,
        intent: Keyword.get(opts, :intent, :shortcut)
      }
    end
  end
end
