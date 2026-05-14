defmodule DesktopUi.Widgets.Input do
  @moduledoc """
  Foundational input widgets for direct-native `desktop_ui`.
  """

  alias DesktopUi.Widget

  @spec kinds() :: [atom()]
  def kinds do
    [
      :checkbox,
      :date_input,
      :file_input,
      :numeric_input,
      :pick_list,
      :radio_group,
      :select,
      :slider,
      :text_input,
      :time_input
    ]
  end

  @spec text_input(String.t() | atom(), keyword()) :: Widget.t()
  def text_input(id, opts \\ []) do
    Widget.new(:text_input,
      id: id,
      metadata: metadata(opts, role: :text_input),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: Keyword.get(opts, :value, "")
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{placeholder: Keyword.get(opts, :placeholder, "")},
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :change_value}),
        submit: Keyword.get(opts, :on_submit, %{intent: :submit_value})
      }
    )
  end

  @spec numeric_input(String.t() | atom(), keyword()) :: Widget.t()
  def numeric_input(id, opts \\ []) do
    value = Keyword.get(opts, :value, 0)
    min = Keyword.get(opts, :min, nil)
    max = Keyword.get(opts, :max, nil)
    step = Keyword.get(opts, :step, 1)

    Widget.new(:numeric_input,
      id: id,
      metadata: metadata(opts, role: :numeric_input),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: value
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{
        min: min,
        max: max,
        step: step,
        placeholder: Keyword.get(opts, :placeholder, "")
      },
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :change_value}),
        increment: %{intent: :increment_value},
        decrement: %{intent: :decrement_value}
      }
    )
  end

  @spec slider(String.t() | atom(), keyword()) :: Widget.t()
  def slider(id, opts \\ []) do
    value = Keyword.get(opts, :value, 0)
    min = Keyword.get(opts, :min, 0)
    max = Keyword.get(opts, :max, 100)
    step = Keyword.get(opts, :step, 1)

    Widget.new(:slider,
      id: id,
      metadata: metadata(opts, role: :slider),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: value
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{
        min: min,
        max: max,
        step: step,
        show_value: Keyword.get(opts, :show_value, true),
        orientation: Keyword.get(opts, :orientation, :horizontal)
      },
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :change_value})
      }
    )
  end

  @spec date_input(String.t() | atom(), keyword()) :: Widget.t()
  def date_input(id, opts \\ []) do
    Widget.new(:date_input,
      id: id,
      metadata: metadata(opts, role: :date_input),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: Keyword.get(opts, :value, nil)
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{
        min: Keyword.get(opts, :min),
        max: Keyword.get(opts, :max),
        placeholder: Keyword.get(opts, :placeholder, "YYYY-MM-DD")
      },
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :change_date}),
        open_picker: %{intent: :open_date_picker}
      }
    )
  end

  @spec time_input(String.t() | atom(), keyword()) :: Widget.t()
  def time_input(id, opts \\ []) do
    Widget.new(:time_input,
      id: id,
      metadata: metadata(opts, role: :time_input),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: Keyword.get(opts, :value, nil)
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{
        placeholder: Keyword.get(opts, :placeholder, "HH:MM"),
        format: Keyword.get(opts, :format, :"24h")
      },
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :change_time}),
        open_picker: %{intent: :open_time_picker}
      }
    )
  end

  @spec file_input(String.t() | atom(), keyword()) :: Widget.t()
  def file_input(id, opts \\ []) do
    Widget.new(:file_input,
      id: id,
      metadata: metadata(opts, role: :file_input),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        value: Keyword.get(opts, :value, nil)
      },
      bindings: %{value: Keyword.get(opts, :binding, :value)},
      attributes: %{
        accept: Keyword.get(opts, :accept),
        multiple: Keyword.get(opts, :multiple, false),
        placeholder: Keyword.get(opts, :placeholder, "Choose file...")
      },
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :select_files}),
        open_picker: %{intent: :open_file_picker}
      }
    )
  end

  @spec pick_list(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def pick_list(id, options, opts \\ []) do
    Widget.new(:pick_list,
      id: id,
      metadata:
        metadata(opts,
          role: :pick_list,
          binding_surface: :selection
        ),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        selected: Keyword.get(opts, :selected),
        open: Keyword.get(opts, :open, false)
      },
      bindings: %{selected: Keyword.get(opts, :binding, :selected)},
      attributes: %{
        options: Enum.map(options, &Map.new/1),
        current: Keyword.get(opts, :selected),
        searchable: Keyword.get(opts, :searchable, true),
        multiple: Keyword.get(opts, :multiple, false),
        placeholder: Keyword.get(opts, :placeholder, "Select...")
      },
      styles: styles(opts),
      events: %{
        selection: Keyword.get(opts, :on_select, %{intent: :select_option}),
        open: Keyword.get(opts, :on_open, %{intent: :open_list}),
        close: Keyword.get(opts, :on_close, %{intent: :close_list}),
        search: Keyword.get(opts, :on_search, %{intent: :search_options})
      }
    )
  end

  @spec checkbox(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def checkbox(id, label, opts \\ []) do
    Widget.new(:checkbox,
      id: id,
      metadata: metadata(opts, role: :checkbox),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        checked: Keyword.get(opts, :checked, false)
      },
      bindings: %{checked: Keyword.get(opts, :binding, :checked)},
      attributes: %{label: label},
      styles: styles(opts),
      events: %{
        change: Keyword.get(opts, :on_change, %{intent: :toggle_checked})
      }
    )
  end

  @spec radio_group(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def radio_group(id, options, opts \\ []) do
    Widget.new(:radio_group,
      id: id,
      metadata:
        metadata(opts,
          role: :radio_group,
          focus_group: Keyword.get(opts, :focus_group, "#{id}:radio_group"),
          binding_surface: :selection
        ),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        selected: Keyword.get(opts, :selected)
      },
      bindings: %{selected: Keyword.get(opts, :binding, :selected)},
      attributes: %{options: Enum.map(options, &Map.new/1)},
      styles: styles(opts),
      events: %{
        selection: Keyword.get(opts, :on_select, %{intent: :select_option})
      }
    )
  end

  @spec select(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def select(id, options, opts \\ []) do
    Widget.new(:select,
      id: id,
      metadata:
        metadata(opts,
          role: :select,
          shortcut: Keyword.get(opts, :shortcut),
          binding_surface: :selection
        ),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        selected: Keyword.get(opts, :selected)
      },
      bindings: %{selected: Keyword.get(opts, :binding, :selected)},
      attributes: %{options: Enum.map(options, &Map.new/1), current: Keyword.get(opts, :selected)},
      styles: styles(opts),
      events:
        %{
          selection: Keyword.get(opts, :on_select, %{intent: :select_option}),
          shortcut:
            shortcut_payload(
              Keyword.get(opts, :shortcut),
              Keyword.get(opts, :shortcut_intent, :open_select)
            )
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
    )
  end

  defp metadata(opts, defaults) do
    defaults
    |> Keyword.merge(
      focusable: true,
      shortcut_scope: Keyword.get(opts, :shortcut_scope, :screen)
    )
    |> Keyword.merge(Keyword.get(opts, :metadata, []))
    |> Map.new()
  end

  defp styles(opts), do: Map.new(Keyword.get(opts, :styles, []))

  defp shortcut_payload(nil, _intent), do: nil

  defp shortcut_payload(shortcut, intent) do
    %{key: shortcut, intent: intent}
  end
end
