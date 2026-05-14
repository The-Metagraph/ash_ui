defmodule ElmUi.Widgets.Foundational do
  @moduledoc """
  Foundational content and action widgets for direct-use `elm_ui` screens.
  """

  alias ElmUi.Widgets.Builder

  @kinds [:text, :label, :icon, :image, :button, :badge, :hero, :link, :separator, :spacer, :content]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec text(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def text(id, content, opts \\ []) when is_binary(content) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:text,
      id: id,
      attributes: %{
        content: content,
        presentation: Builder.option(opts, :presentation, :inline)
      },
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec label(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def label(id, content, opts \\ []) when is_binary(content) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:label,
      id: id,
      attributes: %{
        content: content,
        for: Builder.option(opts, :for),
        relationship: Builder.option(opts, :relationship, :label)
      },
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec icon(String.t() | atom(), atom() | String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def icon(id, name, opts \\ []) when is_atom(name) or is_binary(name) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:icon,
      id: id,
      attributes: %{
        name: name,
        set: Builder.option(opts, :set),
        fallback_text: Builder.option(opts, :fallback_text)
      },
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec image(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def image(id, src, opts \\ []) when is_binary(src) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:image,
      id: id,
      attributes: %{
        src: src,
        alt: Builder.option(opts, :alt, ""),
        fit: Builder.option(opts, :fit, :cover)
      },
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec button(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def button(id, label, opts \\ []) when is_binary(label) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:button,
      id: id,
      attributes: %{
        label: label,
        variant: Builder.option(opts, :variant, :primary)
      },
      state: Builder.state(opts, [:disabled, :active, :pressed]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_click: :click),
      metadata: Builder.metadata(opts, %{native_surface: :foundational, action?: true})
    )
  end

  @spec badge(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def badge(id, label, opts \\ []) when is_binary(label) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:badge,
      id: id,
      attributes: %{
        label: label,
        icon: Builder.option(opts, :icon),
        icon_set: Builder.option(opts, :icon_set),
        presentation: Builder.option(opts, :presentation, :pill)
      },
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec hero(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def hero(id, children \\ [], opts \\ []) when is_list(children) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:hero,
      id: id,
      attributes: %{
        eyebrow: Builder.option(opts, :eyebrow),
        title: Builder.option(opts, :title),
        message: Builder.option(opts, :message),
        align: Builder.option(opts, :align)
      },
      slot_children:
        Builder.slot_map([
          {:default, children},
          {:supporting, Builder.option(opts, :supporting)},
          {:actions, Builder.option(opts, :actions)}
        ]),
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational, container?: true})
    )
  end

  @spec link(String.t() | atom(), String.t(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def link(id, label, href, opts \\ []) when is_binary(label) and is_binary(href) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:link,
      id: id,
      attributes: %{
        label: label,
        href: href,
        external: Builder.option(opts, :external, false)
      },
      state: Builder.state(opts, [:disabled, :current]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_click: :click, on_navigate: :navigation),
      metadata: Builder.metadata(opts, %{native_surface: :foundational, navigation?: true})
    )
  end

  @spec separator(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def separator(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:separator,
      id: id,
      attributes: %{
        orientation: Builder.option(opts, :orientation, :horizontal),
        decorative: Builder.option(opts, :decorative, true)
      },
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec spacer(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def spacer(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:spacer,
      id: id,
      attributes: %{
        size: Builder.option(opts, :size, :md),
        grow: Builder.option(opts, :grow, 0),
        min: Builder.option(opts, :min),
        max: Builder.option(opts, :max)
      },
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational})
    )
  end

  @spec content(String.t() | atom(), [ElmUi.Widget.t() | map() | keyword()], keyword() | map()) ::
          ElmUi.Widget.t()
  def content(id, children, opts \\ []) when is_list(children) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:content,
      id: id,
      attributes: %{
        role: Builder.option(opts, :role, :content),
        presentation: Builder.option(opts, :presentation, :body)
      },
      slot_children: %{default: Builder.children!(children)},
      state: Builder.state(opts),
      styles: Builder.styles(opts),
      metadata: Builder.metadata(opts, %{native_surface: :foundational, container?: true})
    )
  end
end
