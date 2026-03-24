defmodule AshUI.DSL.Builder do
  @moduledoc """
  Builder functions for creating unified-ui DSL structures.

  Provides helper functions for building unified-ui DSL
  that can be stored in Ash Resource attributes.
  """

  @type dsl_map :: %{
          required(:type) => String.t(),
          required(:props) => map(),
          required(:children) => [dsl_map()],
          required(:signals) => [map()],
          optional(:metadata) => map()
        }

  @reserved_option_keys [:children, :signals, :props, :metadata]

  @doc """
  Creates a root DSL element.

  The root element is the top-level container for a UI definition.

  ## Options
    * `:type` - The widget type (e.g., "row", "column", "text")
    * `:props` - Map of widget properties
    * `:children` - List of child DSL elements
    * `:signals` - List of signal definitions
    * `:metadata` - Optional metadata map

  ## Examples

      AshUI.DSL.Builder.root("row", children: [
        AshUI.DSL.Builder.text("Hello, World!")
      ])
  """
  @spec root(String.t(), keyword()) :: dsl_map()
  def root(type, opts \\ []) do
    dsl = %{
      type: type,
      props: Keyword.get(opts, :props, %{}),
      children: Keyword.get(opts, :children, []),
      signals: Keyword.get(opts, :signals, [])
    }

    case Keyword.get(opts, :metadata) do
      metadata when is_map(metadata) -> Map.put(dsl, :metadata, metadata)
      _ -> dsl
    end
  end

  @doc """
  Creates a screen layout element.

  Screens are the top-level IUR container.
  """
  @spec screen(keyword()) :: dsl_map()
  def screen(opts \\ []) when is_list(opts) do
    build_widget("screen", %{}, opts)
  end

  @doc """
  Creates a row layout element.

  Rows arrange children horizontally.

  ## Examples

      row = AshUI.DSL.Builder.row(children: [
        AshUI.DSL.Builder.text("Left"),
        AshUI.DSL.Builder.text("Right")
      ])
  """
  @spec row(keyword()) :: dsl_map()
  def row(opts \\ []) when is_list(opts) do
    build_widget(
      "row",
      %{
        spacing: 8,
        align: :start,
        justify: :start
      },
      opts
    )
  end

  @doc """
  Creates a column layout element.

  Columns arrange children vertically.

  ## Examples

      column = AshUI.DSL.Builder.column(children: [
        AshUI.DSL.Builder.text("Top"),
        AshUI.DSL.Builder.text("Bottom")
      ])
  """
  @spec column(keyword()) :: dsl_map()
  def column(opts \\ []) when is_list(opts) do
    build_widget(
      "column",
      %{
        spacing: 8,
        align: :start,
        justify: :start
      },
      opts
    )
  end

  @doc """
  Creates a grid layout element.
  """
  @spec grid(keyword()) :: dsl_map()
  def grid(opts \\ []) when is_list(opts) do
    build_widget(
      "grid",
      %{
        columns: 12,
        spacing: 8,
        align: :stretch
      },
      opts
    )
  end

  @doc """
  Creates a stack layout element.
  """
  @spec stack(keyword()) :: dsl_map()
  def stack(opts \\ []) when is_list(opts) do
    build_widget(
      "stack",
      %{
        spacing: 0,
        align: :stretch,
        justify: :start
      },
      opts
    )
  end

  @doc """
  Creates a text widget element.

  ## Examples

      text = AshUI.DSL.Builder.text("Hello, World!", size: 16, color: "blue")
  """
  @spec text(String.t(), keyword()) :: dsl_map()
  def text(content, opts \\ []) when is_list(opts) do
    build_widget(
      "text",
      %{
        content: content,
        size: 14,
        color: "inherit",
        weight: :normal,
        align: :left
      },
      opts
    )
  end

  @doc """
  Creates a button widget element.

  ## Examples

      button = AshUI.DSL.Builder.button("Click Me", on_click: "save_action")
  """
  @spec button(String.t(), keyword()) :: dsl_map()
  def button(label, opts \\ []) when is_list(opts) do
    default_signals =
      case Keyword.get(opts, :on_click) do
        nil -> []
        action -> [%{type: :event, target: "button", action: action}]
      end

    build_widget(
      "button",
      %{
        label: label,
        variant: :primary,
        size: :medium,
        disabled: false,
        on_click: Keyword.get(opts, :on_click)
      },
      opts,
      [:on_click],
      default_signals
    )
  end

  @doc """
  Creates an input widget element.

  ## Examples

      input = AshUI.DSL.Builder.input("name", placeholder: "Enter name", value: "")
  """
  @spec input(String.t(), keyword()) :: dsl_map()
  def input(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "input",
      %{
        name: name,
        type: :text,
        placeholder: "",
        value: "",
        disabled: false,
        required: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a textarea widget element.
  """
  @spec textarea(String.t(), keyword()) :: dsl_map()
  def textarea(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "textarea",
      %{
        name: name,
        placeholder: "",
        value: "",
        rows: 4,
        disabled: false,
        required: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a checkbox widget element.
  """
  @spec checkbox(String.t(), keyword()) :: dsl_map()
  def checkbox(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "checkbox",
      %{
        name: name,
        label: name,
        checked: false,
        disabled: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a radio widget element.
  """
  @spec radio(String.t(), keyword()) :: dsl_map()
  def radio(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "radio",
      %{
        name: name,
        value: name,
        label: name,
        checked: false,
        disabled: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a switch widget element.
  """
  @spec switch(String.t(), keyword()) :: dsl_map()
  def switch(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "switch",
      %{
        name: name,
        label: name,
        checked: false,
        disabled: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a slider widget element.
  """
  @spec slider(String.t(), keyword()) :: dsl_map()
  def slider(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "slider",
      %{
        name: name,
        min: 0,
        max: 100,
        step: 1,
        value: 0,
        disabled: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a select widget element.
  """
  @spec select(String.t(), keyword()) :: dsl_map()
  def select(name, opts \\ []) when is_list(opts) do
    signals =
      case Keyword.get(opts, :bind_to) do
        nil -> []
        binding -> [%{type: :bidirectional, target: name, source: binding}]
      end

    build_widget(
      "select",
      %{
        name: name,
        options: [],
        value: nil,
        prompt: nil,
        multiple: false,
        disabled: false
      },
      opts,
      [:bind_to],
      signals
    )
  end

  @doc """
  Creates a card widget element.
  """
  @spec card(keyword()) :: dsl_map()
  def card(opts \\ []) when is_list(opts) do
    build_widget(
      "card",
      %{
        title: nil,
        subtitle: nil,
        variant: :default,
        padding: 16
      },
      opts
    )
  end

  @doc """
  Creates a list widget element.
  """
  @spec list(keyword()) :: dsl_map()
  def list(opts \\ []) when is_list(opts) do
    build_widget(
      "list",
      %{
        items: [],
        ordered: false,
        empty_text: nil
      },
      opts
    )
  end

  @doc """
  Creates a table widget element.
  """
  @spec table(keyword()) :: dsl_map()
  def table(opts \\ []) when is_list(opts) do
    build_widget(
      "table",
      %{
        columns: [],
        rows: [],
        caption: nil,
        empty_text: nil
      },
      opts
    )
  end

  @doc """
  Creates an image widget element.
  """
  @spec image(String.t(), keyword()) :: dsl_map()
  def image(src, opts \\ []) when is_list(opts) do
    build_widget(
      "image",
      %{
        src: src,
        alt: "",
        width: nil,
        height: nil,
        loading: :lazy
      },
      opts
    )
  end

  @doc """
  Creates an icon widget element.
  """
  @spec icon(String.t(), keyword()) :: dsl_map()
  def icon(name, opts \\ []) when is_list(opts) do
    build_widget(
      "icon",
      %{
        name: name,
        size: 16,
        color: "currentColor"
      },
      opts
    )
  end

  @doc """
  Creates a divider widget element.
  """
  @spec divider(keyword()) :: dsl_map()
  def divider(opts \\ []) when is_list(opts) do
    build_widget(
      "divider",
      %{
        orientation: :horizontal,
        color: "currentColor",
        thickness: 1
      },
      opts
    )
  end

  @doc """
  Creates a spacer widget element.
  """
  @spec spacer(keyword()) :: dsl_map()
  def spacer(opts \\ []) when is_list(opts) do
    build_widget(
      "spacer",
      %{
        size: 8,
        axis: :vertical
      },
      opts
    )
  end

  @doc """
  Creates a container element with custom props.

  ## Examples

      container = AshUI.DSL.Builder.container("div", padding: 16, background: "white")
  """
  @spec container(String.t(), keyword()) :: dsl_map()
  def container(type, opts \\ []) when is_list(opts) do
    build_widget(type, %{}, opts)
  end

  @doc """
  Adds a signal binding to an element.

  ## Examples

      element = AshUI.DSL.Builder.text("Hello")
      element = AshUI.DSL.Builder.add_signal(element, :bidirectional, "name", "User.name")
  """
  @spec add_signal(dsl_map(), atom(), String.t(), String.t()) :: dsl_map()
  def add_signal(element, type, target, source) do
    signal = %{
      type: type,
      target: target,
      source: source
    }

    Map.update(element, :signals, [signal], fn signals -> signals ++ [signal] end)
  end

  @doc """
  Merges multiple elements into a single DSL structure.

  ## Examples

      combined = AshUI.DSL.Builder.merge([
        AshUI.DSL.Builder.text("Hello"),
        AshUI.DSL.Builder.text("World")
      ])
  """
  @spec merge([dsl_map()]) :: dsl_map()
  def merge(elements) when is_list(elements) do
    root("fragment", children: elements)
  end

  @doc """
  Converts a DSL structure to a map for database storage.

  ## Examples

      dsl_map = AshUI.DSL.Builder.to_store(dsl_structure)
  """
  @spec to_store(dsl_map()) :: map()
  def to_store(dsl) when is_map(dsl) do
    # Recursively convert DSL to plain map
    dsl
    |> Map.update!(:children, &Enum.map(&1, fn child -> to_store(child) end))
    |> Map.update!(:signals, &Enum.map(&1, fn signal -> Map.new(signal) end))
    |> Map.update!(:props, &Map.new/1)
  end

  @doc """
  Converts stored map back to DSL structure.

  ## Examples

      dsl_structure = AshUI.DSL.Builder.from_store(stored_map)
  """
  @spec from_store(map()) :: dsl_map()
  def from_store(stored) when is_map(stored) do
    %{
      type: fetch_store_value(stored, :type),
      props: fetch_store_value(stored, :props, %{}) |> Map.new(),
      children:
        stored
        |> fetch_store_value(:children, [])
        |> Enum.map(&from_store/1),
      signals:
        stored
        |> fetch_store_value(:signals, [])
        |> Enum.map(&normalize_signal/1),
      metadata: fetch_store_value(stored, :metadata, %{})
    }
  end

  @doc """
  Validates a DSL structure against unified-ui format.

  ## Returns
    * `:ok` - Valid DSL
    * `{:error, errors}` - List of validation errors

  ## Examples

      case AshUI.DSL.Builder.validate(dsl) do
        :ok -> :valid
        {:error, errors} -> # handle errors
      end
  """
  @spec validate(dsl_map()) :: :ok | {:error, [String.t()]}
  def validate(dsl) do
    errors =
      []
      |> validate_type(dsl)
      |> validate_children(dsl)
      |> validate_signals(dsl)
      |> validate_props(dsl)

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  defp fetch_store_value(map, key, default \\ nil) do
    string_key = Atom.to_string(key)

    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, string_key) -> Map.get(map, string_key)
      true -> default
    end
  end

  defp normalize_signal(signal) when is_map(signal) do
    Enum.into(signal, %{}, fn {key, value} ->
      {normalize_signal_key(key), value}
    end)
  end

  defp normalize_signal(signal), do: signal

  defp normalize_signal_key("type"), do: :type
  defp normalize_signal_key("target"), do: :target
  defp normalize_signal_key("source"), do: :source
  defp normalize_signal_key("transform"), do: :transform
  defp normalize_signal_key("action"), do: :action
  defp normalize_signal_key(key), do: key

  defp build_widget(type, default_props, opts, extra_reserved_keys \\ [], default_signals \\ nil) do
    reserved_keys = @reserved_option_keys ++ extra_reserved_keys

    props =
      default_props
      |> Map.merge(extract_prop_options(opts, reserved_keys))
      |> Map.merge(Keyword.get(opts, :props, %{}))

    root(type,
      props: props,
      children: Keyword.get(opts, :children, []),
      signals: Keyword.get(opts, :signals, default_signals || []),
      metadata: Keyword.get(opts, :metadata)
    )
  end

  defp extract_prop_options(opts, reserved_keys) do
    opts
    |> Keyword.drop(reserved_keys)
    |> Enum.into(%{})
  end

  # Private validation functions

  defp validate_type(errors, %{type: type}) when is_binary(type), do: errors
  defp validate_type(errors, _), do: ["Missing or invalid type field" | errors]

  defp validate_children(errors, %{children: children}) when is_list(children),
    do: errors

  defp validate_children(errors, _), do: ["Children must be a list" | errors]

  defp validate_signals(errors, %{signals: signals}) when is_list(signals), do: errors
  defp validate_signals(errors, _), do: ["Signals must be a list" | errors]

  defp validate_props(errors, %{props: props}) when is_map(props), do: errors
  defp validate_props(errors, _), do: ["Props must be a map" | errors]
end
