defmodule AshUI.Resources.Validations.Authoring do
  @moduledoc """
  Shared validation helpers for resource-local Ash UI authoring declarations.
  """

  alias AshUI.DSL.Storage
  alias AshUI.Navigation.Intent, as: NavigationIntent
  alias AshUI.Resources.Validations.BindingSource

  @allowed_screen_layouts [:default, :bare, :modal, :panel, :row, :column, :grid, :stack]
  @allowed_action_signals [:click, :change, :submit, :toggle, :input]
  @allowed_relationship_kinds [:child, :companion]
  @allowed_relationship_placements [:append, :prepend]
  @screen_binding_prefixes ["flash.", "screen.", "metadata."]
  @screen_binding_targets ["title"]
  @list_widgets MapSet.new(["list", "table", "info_list", "select"])
  @action_widgets MapSet.new([
                    "button",
                    "input",
                    "textinput",
                    "textarea",
                    "select",
                    "checkbox",
                    "radio",
                    "switch",
                    "slider",
                    "form_builder"
                  ])
  @signal_capabilities %{
    "button" => [:click, :submit],
    "input" => [:change, :input, :submit],
    "textinput" => [:change, :input, :submit],
    "textarea" => [:change, :input, :submit],
    "select" => [:change, :input, :submit],
    "checkbox" => [:change, :toggle],
    "radio" => [:change, :input],
    "switch" => [:change, :toggle],
    "slider" => [:change, :input],
    "form_builder" => [:submit]
  }

  @doc """
  Validates the screen-scoped Ash UI DSL declared on a screen resource.
  """
  @spec validate_screen_definition!(map()) :: map()
  def validate_screen_definition!(definition) when is_map(definition) do
    layout = Map.get(definition, :layout, :default)
    route = Map.get(definition, :route)
    metadata = Map.get(definition, :metadata, %{})
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

    validate_inline_fragment!(inline_fragment, "ui_screen inline_fragment")

    definition
  end

  @doc """
  Validates the element-scoped Ash UI DSL declared on an element resource.
  """
  @spec validate_element_definition!(map()) :: map()
  def validate_element_definition!(definition) when is_map(definition) do
    type = Map.get(definition, :type)
    props = Map.get(definition, :props, %{})
    variants = Map.get(definition, :variants, [])
    metadata = Map.get(definition, :metadata, %{})

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

    definition
  end

  @doc """
  Validates one binding declaration for either element or screen scope.
  """
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

  @doc """
  Validates that an element definition owns only compatible bindings and actions.
  """
  @spec validate_element_authority!(map(), [map()], [map()]) :: :ok
  def validate_element_authority!(definition, bindings, actions)
      when is_map(definition) and is_list(bindings) and is_list(actions) do
    widget_type = definition |> Map.get(:type) |> normalize_widget_type()

    Enum.each(bindings, &validate_element_binding_locality!(&1, widget_type))
    Enum.each(actions, &validate_action_signal_ownership!(&1, widget_type))

    :ok
  end

  @doc """
  Validates that a screen definition only uses the allowed screen-scoped bindings.
  """
  @spec validate_screen_authority!(map(), [map()], [map()]) :: :ok
  def validate_screen_authority!(definition, bindings, actions \\ [])
      when is_map(definition) and is_list(bindings) and is_list(actions) do
    _ = definition
    Enum.each(bindings, &validate_screen_binding_locality!/1)
    Enum.each(actions, &validate_screen_action_locality!/1)
    :ok
  end

  @doc """
  Validates a single element-owned action declaration.
  """
  @spec validate_action_definition!(map()) :: map()
  def validate_action_definition!(action) when is_map(action) do
    id = Map.get(action, :id)
    signal = Map.get(action, :signal)
    source = Map.get(action, :source)
    target = Map.get(action, :target)
    navigation = Map.get(action, :navigation)
    source_context = Map.get(action, :source_context, %{})
    payload_mapping = Map.get(action, :payload_mapping, %{})
    binding_refs = Map.get(action, :binding_refs, [])
    transform = Map.get(action, :transform, %{})
    metadata = Map.get(action, :metadata, %{})

    validate_identifier!(id, "action id")

    unless signal in @allowed_action_signals do
      raise ArgumentError,
            "action #{inspect(id)} signal must be one of #{inspect(@allowed_action_signals)}, got: #{inspect(signal)}"
    end

    if is_nil(source) and is_nil(navigation) do
      raise ArgumentError,
            "action #{inspect(id)} source is required unless navigation is declared"
    end

    if source do
      case BindingSource.validate_source(source, :action) do
        :ok ->
          :ok

        {:error, message} ->
          raise ArgumentError, "action #{inspect(id)} #{message}"
      end
    end

    if not (is_nil(target) or (is_binary(target) and String.trim(target) != "")) do
      raise ArgumentError, "action #{inspect(id)} target must be a non-empty string when present"
    end

    unless is_nil(navigation) do
      NavigationIntent.normalize!(navigation, label: "action #{inspect(id)} navigation")
    end

    unless is_map(source_context) do
      raise ArgumentError, "action #{inspect(id)} source_context must be a map"
    end

    unless is_map(payload_mapping) do
      raise ArgumentError, "action #{inspect(id)} payload_mapping must be a map"
    end

    unless is_list(binding_refs) do
      raise ArgumentError, "action #{inspect(id)} binding_refs must be a list"
    end

    unless is_map(transform) do
      raise ArgumentError, "action #{inspect(id)} transform must be a map"
    end

    unless is_map(metadata) do
      raise ArgumentError, "action #{inspect(id)} metadata must be a map"
    end

    action
  end

  @doc """
  Validates one explicit relationship-composition declaration.
  """
  @spec validate_relationship_definition!(map()) :: map()
  def validate_relationship_definition!(relationship) when is_map(relationship) do
    name = Map.get(relationship, :name)
    kind = Map.get(relationship, :kind, :child)
    slot = Map.get(relationship, :slot, :default)
    placement = Map.get(relationship, :placement, :append)
    order = Map.get(relationship, :order)

    validate_identifier!(name, "relationship name")

    unless kind in @allowed_relationship_kinds do
      raise ArgumentError,
            "relationship #{inspect(name)} kind must be one of #{inspect(@allowed_relationship_kinds)}, got: #{inspect(kind)}"
    end

    unless (is_atom(slot) and not is_nil(slot)) or (is_binary(slot) and String.trim(slot) != "") do
      raise ArgumentError,
            "relationship #{inspect(name)} slot must be a non-empty atom or string, got: #{inspect(slot)}"
    end

    unless placement in @allowed_relationship_placements do
      raise ArgumentError,
            "relationship #{inspect(name)} placement must be one of #{inspect(@allowed_relationship_placements)}, got: #{inspect(placement)}"
    end

    if not (is_nil(order) or (is_integer(order) and order >= 0)) do
      raise ArgumentError,
            "relationship #{inspect(name)} order must be a non-negative integer when present, got: #{inspect(order)}"
    end

    relationship
  end

  @doc """
  Returns true when a binding target is reserved for screen scope.
  """
  @spec screen_scoped_target?(term()) :: boolean()
  def screen_scoped_target?(target) when is_binary(target) do
    target in @screen_binding_targets or
      Enum.any?(@screen_binding_prefixes, &String.starts_with?(target, &1))
  end

  def screen_scoped_target?(_target), do: false

  @doc """
  Normalizes widget identifiers to the string form used by storage validation.
  """
  @spec normalize_widget_type(term()) :: String.t() | nil
  def normalize_widget_type(type) when is_atom(type), do: Atom.to_string(type)
  def normalize_widget_type(type) when is_binary(type), do: type
  def normalize_widget_type(_type), do: nil

  @doc """
  Validates that a DSL child list contains only resource modules.
  """
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

  @doc """
  Validates an inline screen fragment against stored DSL rules.
  """
  @spec validate_inline_fragment!(term(), String.t()) :: :ok
  def validate_inline_fragment!(nil, _label), do: :ok

  def validate_inline_fragment!(fragment, label) when is_map(fragment) do
    case Storage.validate_write(fragment) do
      :ok ->
        :ok

      {:error, errors} ->
        raise ArgumentError, "#{label} must be valid unified_dsl: #{Enum.join(errors, ", ")}"
    end
  end

  def validate_inline_fragment!(value, label) do
    raise ArgumentError, "#{label} must be a map when present, got: #{inspect(value)}"
  end

  @doc """
  Validates an authoring identifier used for bindings and actions.
  """
  @spec validate_identifier!(term(), String.t()) :: :ok
  def validate_identifier!(value, _label)
      when (is_binary(value) and value != "") or (is_atom(value) and not is_nil(value)) do
    :ok
  end

  def validate_identifier!(value, label) do
    raise ArgumentError, "#{label} must be a non-empty string or atom, got: #{inspect(value)}"
  end

  defp validate_element_binding_locality!(binding, widget_type) do
    target = Map.get(binding, :target)
    binding_type = Map.get(binding, :binding_type, :value)

    if screen_scoped_target?(target) do
      raise ArgumentError,
            "binding #{inspect(Map.get(binding, :id))} targets #{inspect(target)}, which is reserved for screen-scoped bindings"
    end

    if binding_type == :list and not MapSet.member?(@list_widgets, widget_type) do
      raise ArgumentError,
            "binding #{inspect(Map.get(binding, :id))} declares a list binding on #{inspect(widget_type)}, which does not expose collection semantics"
    end

    if binding_type == :action and not MapSet.member?(@action_widgets, widget_type) do
      raise ArgumentError,
            "binding #{inspect(Map.get(binding, :id))} declares an action binding on #{inspect(widget_type)}, which does not expose interactive action signals"
    end

    :ok
  end

  defp validate_screen_binding_locality!(binding) do
    target = Map.get(binding, :target)

    if screen_scoped_target?(target) do
      :ok
    else
      raise ArgumentError,
            "screen-scoped binding #{inspect(Map.get(binding, :id))} must target one of #{inspect(@screen_binding_targets)} or prefixes #{inspect(@screen_binding_prefixes)}, got: #{inspect(target)}"
    end
  end

  defp validate_action_signal_ownership!(action, widget_type) do
    signal = Map.get(action, :signal)
    supported = Map.get(@signal_capabilities, widget_type, [])

    if signal in supported do
      :ok
    else
      raise ArgumentError,
            "action #{inspect(Map.get(action, :id))} declares signal #{inspect(signal)} on #{inspect(widget_type)}, but supported signals are #{inspect(supported)}"
    end
  end

  defp validate_screen_action_locality!(action) do
    if Map.has_key?(action, :navigation) do
      :ok
    else
      raise ArgumentError,
            "screen-scoped action #{inspect(Map.get(action, :id))} must declare navigation intent"
    end
  end
end
