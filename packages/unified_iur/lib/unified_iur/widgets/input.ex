defmodule UnifiedIUR.Widgets.Input do
  @moduledoc """
  Canonical constructors for baseline input, selection, and form-control
  widgets in `UnifiedIUR`.
  """

  alias UnifiedIUR.Attachment
  alias UnifiedIUR.Element
  alias UnifiedIUR.Metadata

  @kinds [
    :text_input,
    :numeric_input,
    :toggle,
    :checkbox,
    :radio_group,
    :select,
    :pick_list,
    :slider,
    :date_input,
    :time_input,
    :file_input
  ]

  @spec kinds() :: [atom()]
  def kinds do
    @kinds
  end

  @spec text_input(keyword() | map()) :: Element.t()
  def text_input(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :text_input,
      %{
        input: %{
          value_kind: :text,
          placeholder: option(opts, :placeholder),
          multiline?: option(opts, :multiline?, false),
          input_mode: option(opts, :input_mode, :text)
        }
      },
      opts
    )
  end

  @spec numeric_input(keyword() | map()) :: Element.t()
  def numeric_input(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :numeric_input,
      %{
        input: %{
          value_kind: :numeric,
          placeholder: option(opts, :placeholder),
          min: option(opts, :min),
          max: option(opts, :max),
          step: option(opts, :step, 1)
        }
      },
      opts
    )
  end

  @spec toggle(keyword() | map()) :: Element.t()
  def toggle(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :toggle,
      %{
        input: %{
          value_kind: :boolean,
          presentation: :toggle,
          checked_value: option(opts, :checked_value, true),
          unchecked_value: option(opts, :unchecked_value, false)
        }
      },
      opts
    )
  end

  @spec checkbox(keyword() | map()) :: Element.t()
  def checkbox(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :checkbox,
      %{
        input: %{
          value_kind: :boolean,
          presentation: :checkbox,
          checked_value: option(opts, :checked_value, true),
          unchecked_value: option(opts, :unchecked_value, false)
        }
      },
      opts
    )
  end

  @spec radio_group([keyword() | map()], keyword() | map()) :: Element.t()
  def radio_group(options, opts \\ []) when is_list(options) do
    opts = normalize_opts(opts)

    build_input(
      :radio_group,
      %{
        selection: %{
          multiple?: false,
          presentation: :radio_group,
          options: normalize_options(options)
        }
      },
      opts
    )
  end

  @spec select([keyword() | map()], keyword() | map()) :: Element.t()
  def select(options, opts \\ []) when is_list(options) do
    opts = normalize_opts(opts)

    build_input(
      :select,
      %{
        selection: %{
          multiple?: option(opts, :multiple?, false),
          presentation: :select,
          options: normalize_options(options)
        }
      },
      opts
    )
  end

  @spec pick_list([keyword() | map()], keyword() | map()) :: Element.t()
  def pick_list(options, opts \\ []) when is_list(options) do
    opts = normalize_opts(opts)

    build_input(
      :pick_list,
      %{
        selection: %{
          multiple?: option(opts, :multiple?, true),
          presentation: :pick_list,
          options: normalize_options(options)
        }
      },
      opts
    )
  end

  @spec slider(keyword() | map()) :: Element.t()
  def slider(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :slider,
      %{
        input: %{
          value_kind: :range,
          min: option(opts, :min, 0),
          max: option(opts, :max, 100),
          step: option(opts, :step, 1)
        }
      },
      opts
    )
  end

  @spec date_input(keyword() | map()) :: Element.t()
  def date_input(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :date_input,
      %{
        input: %{
          value_kind: :date,
          format: option(opts, :format, :iso8601),
          min: option(opts, :min),
          max: option(opts, :max)
        }
      },
      opts
    )
  end

  @spec time_input(keyword() | map()) :: Element.t()
  def time_input(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :time_input,
      %{
        input: %{
          value_kind: :time,
          format: option(opts, :format, :iso8601),
          min: option(opts, :min),
          max: option(opts, :max),
          step: option(opts, :step)
        }
      },
      opts
    )
  end

  @spec file_input(keyword() | map()) :: Element.t()
  def file_input(opts \\ []) do
    opts = normalize_opts(opts)

    build_input(
      :file_input,
      %{
        file: %{
          accept: option(opts, :accept, []),
          multiple?: option(opts, :multiple?, false),
          capture: option(opts, :capture)
        }
      },
      opts
    )
  end

  defp build_input(kind, kind_attributes, opts) do
    Element.new(:widget, kind,
      id: option(opts, :id),
      metadata: normalize_metadata(opts),
      attributes:
        %{}
        |> merge_attribute(:input, Map.get(kind_attributes, :input))
        |> merge_attribute(:selection, Map.get(kind_attributes, :selection))
        |> merge_attribute(:file, Map.get(kind_attributes, :file))
        |> merge_attribute(:label, normalize_label(opts))
        |> merge_attribute(:validation, normalize_validation(opts))
        |> merge_attribute(:accessibility, normalize_accessibility(opts))
        |> merge_attribute(:state, normalize_state(opts))
        |> Attachment.merge(opts,
          component: kind,
          tone: option(opts, :tone),
          local_style: option(opts, :style),
          fallback_bindings: normalize_binding(opts)
        ),
      children: []
    )
  end

  defp normalize_options(options) do
    Enum.map(options, fn option_value ->
      option_value = normalize_opts(option_value)

      %{}
      |> maybe_put(:id, option(option_value, :id))
      |> maybe_put(:value, option(option_value, :value))
      |> maybe_put(:label, option(option_value, :label))
      |> maybe_put(:description, option(option_value, :description))
      |> maybe_put(:disabled?, option(option_value, :disabled?))
      |> maybe_put(:selected?, option(option_value, :selected?))
    end)
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

  defp normalize_label(opts) do
    opts
    |> option(:label, %{})
    |> normalize_map()
    |> maybe_put(:text, option(opts, :label_text))
  end

  defp normalize_binding(opts) do
    opts
    |> option(:binding, %{})
    |> normalize_map()
    |> maybe_put(:name, option(opts, :name))
    |> maybe_put(:path, option(opts, :path, option(opts, :value_path)))
    |> maybe_put(:value, option(opts, :value))
    |> maybe_put(:default, option(opts, :default, option(opts, :default_value)))
    |> maybe_put(:format, option(opts, :binding_format))
    |> maybe_put(:source, option(opts, :source))
    |> maybe_put(:collection?, option(opts, :collection?))
  end

  defp normalize_validation(opts) do
    opts
    |> option(:validation, %{})
    |> normalize_map()
    |> maybe_put(:required?, option(opts, :required?))
    |> maybe_put(:errors, normalize_errors(option(opts, :errors)))
    |> maybe_put(:constraints, normalize_optional_map(option(opts, :constraints)))
    |> maybe_put(:status, option(opts, :status))
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
    |> maybe_put(:readonly?, option(opts, :readonly?))
    |> maybe_put(:invalid?, option(opts, :invalid?))
    |> maybe_put(:selected?, option(opts, :selected?))
    |> maybe_put(:focused?, option(opts, :focused?))
    |> maybe_put(:current?, option(opts, :current?))
  end

  defp normalize_errors(nil), do: nil
  defp normalize_errors(errors) when is_list(errors), do: Enum.reject(errors, &is_nil/1)

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp normalize_optional_map(nil), do: nil
  defp normalize_optional_map(map), do: normalize_map(map)

  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(opts) when is_map(opts), do: Map.new(opts)

  defp option(opts, key, default \\ nil) do
    Map.get(opts, key, Map.get(opts, Atom.to_string(key), default))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp merge_attribute(attributes, _key, value) when value in [%{}, [], nil], do: attributes
  defp merge_attribute(attributes, key, value), do: Map.put(attributes, key, value)
end
