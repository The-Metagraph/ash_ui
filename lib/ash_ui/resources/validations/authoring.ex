defmodule AshUI.Resources.Validations.Authoring do
  @moduledoc """
  Shared validation helpers for resource-local Ash UI authoring declarations.
  """

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.BindingSource

  @allowed_screen_layouts [:default, :bare, :modal, :panel, :row, :column, :grid, :stack]
  @allowed_action_signals [:click, :change, :submit, :toggle, :input]

  @spec validate_screen_definition!(map()) :: map()
  def validate_screen_definition!(definition) when is_map(definition) do
    layout = Map.get(definition, :layout, :default)
    route = Map.get(definition, :route)
    metadata = Map.get(definition, :metadata, %{})
    elements = Map.get(definition, :elements, [])
    inline_fragment = Map.get(definition, :inline_fragment)

    unless layout in @allowed_screen_layouts do
      raise ArgumentError,
            "ui_screen layout must be one of #{inspect(@allowed_screen_layouts)}, got: #{inspect(layout)}"
    end

    if not (is_nil(route) or (is_binary(route) and String.trim(route) != "")) do
      raise ArgumentError, "ui_screen route must be a non-empty string when present"
    end

    unless is_map(metadata) do
      raise ArgumentError, "ui_screen metadata must be a map, got: #{inspect(metadata)}"
    end

    validate_module_list!(elements, "ui_screen elements")
    validate_inline_fragment!(inline_fragment, "ui_screen inline_fragment")

    definition
  end

  @spec validate_element_definition!(map()) :: map()
  def validate_element_definition!(definition) when is_map(definition) do
    type = Map.get(definition, :type)
    props = Map.get(definition, :props, %{})
    variants = Map.get(definition, :variants, [])
    metadata = Map.get(definition, :metadata, %{})
    children = Map.get(definition, :children, [])

    normalized_type = normalize_widget_type(type)

    unless is_binary(normalized_type) and Storage.valid_widget_type?(normalized_type) do
      raise ArgumentError, "ui_element type must be a known widget type, got: #{inspect(type)}"
    end

    unless is_map(props) do
      raise ArgumentError, "ui_element props must be a map, got: #{inspect(props)}"
    end

    unless is_list(variants) and Enum.all?(variants, &(is_atom(&1) or is_binary(&1))) do
      raise ArgumentError,
            "ui_element variants must be a list of atoms or strings, got: #{inspect(variants)}"
    end

    unless is_map(metadata) do
      raise ArgumentError, "ui_element metadata must be a map, got: #{inspect(metadata)}"
    end

    validate_module_list!(children, "ui_element children")

    definition
  end

  @spec validate_binding_definition!(map(), keyword()) :: map()
  def validate_binding_definition!(binding, opts \\ []) when is_map(binding) do
    scope = Keyword.get(opts, :scope, :element)
    id = Map.get(binding, :id)
    source = Map.get(binding, :source)
    target = Map.get(binding, :target)
    binding_type = Map.get(binding, :binding_type, :value)
    transform = Map.get(binding, :transform, %{})
    metadata = Map.get(binding, :metadata, %{})

    validate_identifier!(id, "binding id")

    unless binding_type in [:value, :list, :action] do
      raise ArgumentError,
            "binding #{inspect(id)} binding_type must be one of [:value, :list, :action], got: #{inspect(binding_type)}"
    end

    case BindingSource.validate_source(source, binding_type) do
      :ok ->
        :ok

      {:error, message} ->
        raise ArgumentError, "binding #{inspect(id)} #{message}"
    end

    unless is_binary(target) and String.trim(target) != "" do
      raise ArgumentError, "binding #{inspect(id)} target must be a non-empty string"
    end

    unless is_map(transform) do
      raise ArgumentError, "binding #{inspect(id)} transform must be a map"
    end

    unless is_map(metadata) do
      raise ArgumentError, "binding #{inspect(id)} metadata must be a map"
    end

    if scope not in [:screen, :element] do
      raise ArgumentError, "binding #{inspect(id)} scope must be :screen or :element"
    end

    binding
  end

  @spec validate_action_definition!(map()) :: map()
  def validate_action_definition!(action) when is_map(action) do
    id = Map.get(action, :id)
    signal = Map.get(action, :signal)
    source = Map.get(action, :source)
    target = Map.get(action, :target)
    transform = Map.get(action, :transform, %{})
    metadata = Map.get(action, :metadata, %{})

    validate_identifier!(id, "action id")

    unless signal in @allowed_action_signals do
      raise ArgumentError,
            "action #{inspect(id)} signal must be one of #{inspect(@allowed_action_signals)}, got: #{inspect(signal)}"
    end

    case BindingSource.validate_source(source, :action) do
      :ok ->
        :ok

      {:error, message} ->
        raise ArgumentError, "action #{inspect(id)} #{message}"
    end

    if not (is_nil(target) or (is_binary(target) and String.trim(target) != "")) do
      raise ArgumentError, "action #{inspect(id)} target must be a non-empty string when present"
    end

    unless is_map(transform) do
      raise ArgumentError, "action #{inspect(id)} transform must be a map"
    end

    unless is_map(metadata) do
      raise ArgumentError, "action #{inspect(id)} metadata must be a map"
    end

    action
  end

  @spec normalize_widget_type(term()) :: String.t() | nil
  def normalize_widget_type(type) when is_atom(type), do: Atom.to_string(type)
  def normalize_widget_type(type) when is_binary(type), do: type
  def normalize_widget_type(_type), do: nil

  @spec validate_module_list!(term(), String.t()) :: :ok
  def validate_module_list!(value, label) when is_list(value) do
    if Enum.all?(value, &is_atom/1) do
      :ok
    else
      raise ArgumentError, "#{label} must be a list of modules, got: #{inspect(value)}"
    end
  end

  def validate_module_list!(value, label) do
    raise ArgumentError, "#{label} must be a list of modules, got: #{inspect(value)}"
  end

  @spec validate_inline_fragment!(term(), String.t()) :: :ok
  def validate_inline_fragment!(nil, _label), do: :ok

  def validate_inline_fragment!(fragment, label) when is_map(fragment) do
    case Storage.validate_write(fragment) do
      :ok -> :ok
      {:error, errors} -> raise ArgumentError, "#{label} must be valid unified_dsl: #{Enum.join(errors, ", ")}"
    end
  end

  def validate_inline_fragment!(value, label) do
    raise ArgumentError, "#{label} must be a map when present, got: #{inspect(value)}"
  end

  @spec validate_identifier!(term(), String.t()) :: :ok
  def validate_identifier!(value, _label)
      when (is_binary(value) and value != "") or (is_atom(value) and not is_nil(value)) do
    :ok
  end

  def validate_identifier!(value, label) do
    raise ArgumentError, "#{label} must be a non-empty string or atom, got: #{inspect(value)}"
  end
end
