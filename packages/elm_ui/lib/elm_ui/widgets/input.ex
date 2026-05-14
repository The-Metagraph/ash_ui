defmodule ElmUi.Widgets.Input do
  @moduledoc """
  Baseline input widgets for direct-use `elm_ui` forms.
  """

  alias ElmUi.Widgets.Builder

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
  def kinds, do: @kinds

  @spec text_input(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def text_input(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    text_like_input(:text_input, id, opts,
      value: Builder.option(opts, :value, ""),
      placeholder: Builder.option(opts, :placeholder),
      multiline: Builder.option(opts, :multiline, false),
      input_mode: Builder.option(opts, :input_mode, :text)
    )
  end

  @spec numeric_input(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def numeric_input(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    text_like_input(:numeric_input, id, opts,
      value: Builder.option(opts, :value),
      placeholder: Builder.option(opts, :placeholder),
      min: Builder.option(opts, :min),
      max: Builder.option(opts, :max),
      step: Builder.option(opts, :step, 1)
    )
  end

  @spec date_input(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def date_input(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    text_like_input(:date_input, id, opts,
      value: Builder.option(opts, :value),
      min: Builder.option(opts, :min),
      max: Builder.option(opts, :max),
      format: Builder.option(opts, :format, :iso8601)
    )
  end

  @spec time_input(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def time_input(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    text_like_input(:time_input, id, opts,
      value: Builder.option(opts, :value),
      min: Builder.option(opts, :min),
      max: Builder.option(opts, :max),
      step: Builder.option(opts, :step),
      format: Builder.option(opts, :format, :iso8601)
    )
  end

  @spec file_input(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def file_input(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:file_input,
      id: id,
      attributes: %{
        name: Builder.option(opts, :name),
        accept: List.wrap(Builder.option(opts, :accept, [])),
        multiple: Builder.option(opts, :multiple, false),
        capture: Builder.option(opts, :capture)
      },
      state: Builder.state(opts, [:disabled, :focused, :editing]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end

  @spec slider(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def slider(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:slider,
      id: id,
      attributes: %{
        name: Builder.option(opts, :name),
        value: Builder.option(opts, :value),
        min: Builder.option(opts, :min, 0),
        max: Builder.option(opts, :max, 100),
        step: Builder.option(opts, :step, 1)
      },
      state: Builder.state(opts, [:disabled, :focused, :editing]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end

  @spec toggle(String.t() | atom(), keyword() | map()) :: ElmUi.Widget.t()
  def toggle(id, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:toggle,
      id: id,
      attributes: %{
        name: Builder.option(opts, :name),
        label: Builder.option(opts, :label),
        checked_value: Builder.option(opts, :checked_value, true),
        unchecked_value: Builder.option(opts, :unchecked_value, false)
      },
      state:
        Builder.state(opts, [:disabled, :focused, :checked, :selected])
        |> Map.put(:checked, Builder.option(opts, :checked, Builder.option(opts, :value, false))),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end

  @spec checkbox(String.t() | atom(), String.t(), keyword() | map()) :: ElmUi.Widget.t()
  def checkbox(id, label, opts \\ []) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    Builder.widget(:checkbox,
      id: id,
      attributes: %{
        name: Builder.option(opts, :name),
        label: label,
        checked_value: Builder.option(opts, :checked_value, true),
        unchecked_value: Builder.option(opts, :unchecked_value, false)
      },
      state:
        Builder.state(opts, [:disabled, :focused, :checked])
        |> Map.put(:checked, Builder.option(opts, :checked, Builder.option(opts, :value, false))),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end

  @spec radio_group(String.t() | atom(), [keyword() | map()], keyword() | map()) ::
          ElmUi.Widget.t()
  def radio_group(id, options, opts \\ []) when is_list(options) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    selection_input(:radio_group, id, options, opts,
      multiple: false,
      presentation: :radio_group
    )
  end

  @spec select(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def select(id, options, opts \\ []) when is_list(options) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    selection_input(:select, id, options, opts,
      multiple: Builder.option(opts, :multiple, false),
      presentation: :select
    )
  end

  @spec pick_list(String.t() | atom(), [keyword() | map()], keyword() | map()) :: ElmUi.Widget.t()
  def pick_list(id, options, opts \\ []) when is_list(options) do
    opts = Builder.options(Map.put(Builder.options(opts), :id, id))

    selection_input(:pick_list, id, options, opts,
      multiple: Builder.option(opts, :multiple, true),
      presentation: :pick_list
    )
  end

  defp normalize_options(options) do
    Enum.map(options, fn option ->
      option = Builder.options(option)

      %{}
      |> Builder.maybe_put(:id, Builder.option(option, :id))
      |> Builder.maybe_put(:value, Builder.option(option, :value))
      |> Builder.maybe_put(:label, Builder.option(option, :label))
      |> Builder.maybe_put(:description, Builder.option(option, :description))
      |> Builder.maybe_put(:disabled, Builder.option(option, :disabled))
      |> Builder.maybe_put(:selected, Builder.option(option, :selected))
    end)
  end

  defp text_like_input(kind, id, opts, attrs) do
    Builder.widget(kind,
      id: id,
      attributes:
        %{
          name: Builder.option(opts, :name)
        }
        |> Map.merge(Enum.reject(attrs, fn {_key, value} -> is_nil(value) end) |> Map.new()),
      state: Builder.state(opts, [:disabled, :focused, :editing]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus, on_submit: :submit),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end

  defp selection_input(kind, id, options, opts, attrs) do
    Builder.widget(kind,
      id: id,
      attributes:
        %{
          name: Builder.option(opts, :name),
          value: Builder.option(opts, :value),
          options: normalize_options(options)
        }
        |> Map.merge(Enum.reject(attrs, fn {_key, value} -> is_nil(value) end) |> Map.new()),
      state: Builder.state(opts, [:disabled, :focused, :editing]),
      styles: Builder.styles(opts),
      events: Builder.events(opts, on_change: :change, on_focus: :focus),
      metadata: Builder.metadata(opts, %{native_surface: :input})
    )
  end
end
