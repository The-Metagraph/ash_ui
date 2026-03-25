defmodule UnifiedIUR.Widgets.Foundational do
  @moduledoc """
  Canonical constructors for foundational visual, content, and content-bearing
  widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Metadata

  @type opts :: keyword() | map()
  @type accessibility :: %{
          optional(:label) => String.t(),
          optional(:description) => String.t(),
          optional(:role_description) => String.t(),
          optional(:hidden?) => boolean()
        }
  @type state_hooks :: %{
          optional(:disabled?) => boolean(),
          optional(:active?) => boolean(),
          optional(:selected?) => boolean(),
          optional(:pressed?) => boolean(),
          optional(:current?) => boolean(),
          optional(:emphasis) => atom() | String.t()
        }
  @type style_hooks :: %{
          optional(:style_refs) => [atom() | String.t()],
          optional(:variant) => atom() | String.t(),
          optional(:tone) => atom() | String.t()
        }

  @type widget_kind ::
          :text
          | :label
          | :icon
          | :image
          | :badge
          | :hero
          | :button
          | :link
          | :separator
          | :spacer
          | :content

  @foundational_kinds [
    :text,
    :label,
    :icon,
    :image,
    :badge,
    :hero,
    :button,
    :link,
    :separator,
    :spacer,
    :content
  ]

  @spec kinds() :: [widget_kind()]
  def kinds do
    @foundational_kinds
  end

  @spec text(String.t(), opts()) :: Element.t()
  def text(value, opts \\ []) when is_binary(value) do
    opts = normalize_opts(opts)

    build_widget(
      :text,
      %{
        content: %{text: value}
      },
      opts
    )
  end

  @spec label(String.t(), opts()) :: Element.t()
  def label(value, opts \\ []) when is_binary(value) do
    opts = normalize_opts(opts)

    build_widget(
      :label,
      %{
        content: %{text: value},
        label: normalize_map(option(opts, :label, %{}))
      },
      opts
    )
  end

  @spec icon(atom() | String.t(), opts()) :: Element.t()
  def icon(name, opts \\ []) when is_atom(name) or is_binary(name) do
    opts = normalize_opts(opts)

    build_widget(
      :icon,
      %{
        icon: %{
          name: name,
          set: option(opts, :set),
          fallback_text: option(opts, :fallback_text)
        }
      },
      opts
    )
  end

  @spec image(String.t(), opts()) :: Element.t()
  def image(source, opts \\ []) when is_binary(source) do
    opts = normalize_opts(opts)

    build_widget(
      :image,
      %{
        image: %{
          source: source,
          media_type: option(opts, :media_type),
          alt_text: option(opts, :alt_text),
          fit: option(opts, :fit)
        }
      },
      opts
    )
  end

  @spec button(String.t(), opts()) :: Element.t()
  def button(label, opts \\ []) when is_binary(label) do
    opts = normalize_opts(opts)

    build_widget(
      :button,
      %{
        content: %{text: label}
      },
      opts
    )
  end

  @spec badge(String.t(), opts()) :: Element.t()
  def badge(label, opts \\ []) when is_binary(label) do
    opts = normalize_opts(opts)

    build_widget(
      :badge,
      %{
        content: %{text: label},
        badge:
          %{}
          |> maybe_put(:icon, option(opts, :icon))
          |> maybe_put(:icon_set, option(opts, :icon_set))
          |> maybe_put(:presentation, option(opts, :presentation, :pill))
      },
      opts
    )
  end

  @spec hero(
          [Element.t() | Element.Child.t() | {Element.Child.slot(), Element.t() | nil} | map()],
          opts()
        ) :: Element.t()
  def hero(children \\ [], opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_widget(
      :hero,
      %{
        hero:
          %{}
          |> maybe_put(:eyebrow, option(opts, :eyebrow))
          |> maybe_put(:title, option(opts, :title))
          |> maybe_put(:message, option(opts, :message))
          |> maybe_put(:align, option(opts, :align))
      },
      Map.put(opts, :children, children)
    )
  end

  @spec link(String.t(), String.t(), opts()) :: Element.t()
  def link(label, target, opts \\ []) when is_binary(label) and is_binary(target) do
    opts = normalize_opts(opts)

    build_widget(
      :link,
      %{
        content: %{text: label},
        link: %{
          target: target,
          external?: option(opts, :external?, false),
          target_kind: option(opts, :target_kind, :uri)
        }
      },
      Map.put(opts, :navigation_target, target)
    )
  end

  @spec separator(opts()) :: Element.t()
  def separator(opts \\ []) do
    opts = normalize_opts(opts)

    build_widget(
      :separator,
      %{
        separator: %{
          orientation: option(opts, :orientation, :horizontal),
          decorative?: option(opts, :decorative?, true)
        }
      },
      opts
    )
  end

  @spec spacer(opts()) :: Element.t()
  def spacer(opts \\ []) do
    opts = normalize_opts(opts)

    build_widget(
      :spacer,
      %{
        spacer: %{
          size: option(opts, :size, :md),
          grow: option(opts, :grow, 0),
          min: option(opts, :min),
          max: option(opts, :max)
        }
      },
      opts
    )
  end

  @spec content(
          [Element.t() | Element.Child.t() | {Element.Child.slot(), Element.t() | nil} | map()],
          opts()
        ) ::
          Element.t()
  def content(children, opts \\ []) when is_list(children) do
    opts = normalize_opts(opts)

    build_widget(
      :content,
      %{
        container: %{
          role: option(opts, :role, :content),
          presentation: option(opts, :presentation, :body)
        }
      },
      Map.put(normalize_opts(opts), :children, children)
    )
  end

  defp build_widget(kind, kind_attributes, opts) do
    opts = normalize_opts(opts)

    Element.new(:widget, kind,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{}
        |> merge_attribute(:content, Map.get(kind_attributes, :content))
        |> merge_attribute(:icon, Map.get(kind_attributes, :icon))
        |> merge_attribute(:image, Map.get(kind_attributes, :image))
        |> merge_attribute(:badge, Map.get(kind_attributes, :badge))
        |> merge_attribute(:hero, Map.get(kind_attributes, :hero))
        |> merge_attribute(:link, Map.get(kind_attributes, :link))
        |> merge_attribute(:label, Map.get(kind_attributes, :label))
        |> merge_attribute(:separator, Map.get(kind_attributes, :separator))
        |> merge_attribute(:spacer, Map.get(kind_attributes, :spacer))
        |> merge_attribute(:container, Map.get(kind_attributes, :container))
        |> merge_attribute(:accessibility, normalize_accessibility(opts))
        |> merge_attribute(:state, normalize_state(opts))
        |> Attachment.merge(opts,
          component: kind,
          tone: option(opts, :tone),
          local_style: option(opts, :style),
          fallback_interactions: default_interactions(kind, opts)
        ),
      children: option(opts, :children, [])
    )
  end

  defp normalize_metadata(opts) do
    opts
    |> option(:metadata)
    |> Metadata.merge(%{
      authored_ref: option(opts, :authored_ref),
      description: option(opts, :description),
      annotations: option(opts, :annotations, %{}),
      tags: option(opts, :tags, []),
      extra: option(opts, :extra, %{})
    })
  end

  defp normalize_accessibility(opts) do
    opts
    |> option(:accessibility, %{})
    |> normalize_map()
    |> maybe_put(:label, option(opts, :accessibility_label))
    |> maybe_put(:description, option(opts, :accessibility_description))
    |> maybe_put(:role_description, option(opts, :role_description))
    |> maybe_put(:hidden?, option(opts, :accessibility_hidden?))
  end

  defp normalize_state(opts) do
    opts
    |> option(:state, %{})
    |> normalize_map()
    |> maybe_put(:disabled?, option(opts, :disabled?))
    |> maybe_put(:active?, option(opts, :active?))
    |> maybe_put(:selected?, option(opts, :selected?))
    |> maybe_put(:pressed?, option(opts, :pressed?))
    |> maybe_put(:current?, option(opts, :current?))
    |> maybe_put(:emphasis, option(opts, :emphasis))
  end

  defp default_interactions(:button, opts) do
    action =
      opts
      |> option(:action, %{})
      |> normalize_map()

    if action == %{} do
      []
    else
      [
        Interaction.click(
          intent: option(action, :intent),
          element_id: option(opts, :id),
          path: option(action, :path),
          binding: option(action, :binding),
          command: option(action, :command),
          value: option(action, :value),
          mapping: option(action, :mapping)
        )
      ]
    end
  end

  defp default_interactions(:link, opts) do
    [
      Interaction.navigation(
        intent: :follow_link,
        element_id: option(opts, :id),
        entity: option(opts, :target_kind, :uri),
        value: option(opts, :navigation_target)
      )
    ]
  end

  defp default_interactions(_kind, _opts), do: []

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp merge_attribute(attributes, _key, value) when value in [%{}, [], nil], do: attributes
  defp merge_attribute(attributes, key, value), do: Map.put(attributes, key, value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
