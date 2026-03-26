defmodule AshUI.Resource.Authority do
  @moduledoc """
  Persists screen records from resource-local Ash UI authoring modules.

  Resource modules are the authoritative authoring units. The persisted
  `unified_dsl` payload generated here is a storage snapshot of that authority,
  not the primary source of truth.
  """

  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.Resource.Info

  @format "ash_ui/resource_authority"
  @version 1

  @type payload :: map()

  @doc """
  Returns the persisted resource-authority payload format.
  """
  @spec format() :: String.t()
  def format, do: @format

  @doc """
  Returns the persisted resource-authority payload version.
  """
  @spec version() :: pos_integer()
  def version, do: @version

  @doc """
  Returns true when a payload matches the resource-authority format.
  """
  @spec authority_payload?(term()) :: boolean()
  def authority_payload?(%{"format" => @format, "version" => @version}), do: true
  def authority_payload?(%{format: @format, version: @version}), do: true
  def authority_payload?(_other), do: false

  @doc """
  Builds a persisted payload from a screen resource module.
  """
  @spec payload(module(), keyword()) :: {:ok, payload()} | {:error, term()}
  def payload(screen_module, opts \\ []) when is_atom(screen_module) and is_list(opts) do
    with :screen <- Info.resource_role(screen_module),
         {:ok, screen_definition} <- Info.screen_definition(screen_module),
         {:ok, screen_bindings} <- Info.screen_bindings(screen_module),
         {:ok, element_modules} <- fetch_element_modules(screen_definition),
         {:ok, elements} <- build_elements(element_modules) do
      screen_metadata = build_metadata(screen_definition, Keyword.get(opts, :metadata, %{}))

      {:ok,
       %{
         "format" => @format,
         "version" => @version,
         "screen" => %{
           "module" => encode_module(screen_module),
           "name" => Keyword.get(opts, :name, default_name(screen_module)),
           "route" => Keyword.get(opts, :route, Map.get(screen_definition, :route)),
           "layout" => encode_value(Keyword.get(opts, :layout, Map.get(screen_definition, :layout, :default))),
           "metadata" => encode_value(screen_metadata),
           "inline_fragment" => encode_value(Map.get(screen_definition, :inline_fragment)),
           "bindings" => Enum.map(screen_bindings, &encode_binding/1)
         },
         "elements" => elements
       }}
    else
      nil -> {:error, {:missing_screen_authority, screen_module}}
      :element -> {:error, {:expected_screen_resource, screen_module}}
      {:error, _reason} = error -> error
      other -> {:error, {:invalid_screen_authority, screen_module, other}}
    end
  end

  @doc """
  Builds `Screen` resource attrs from a screen resource module.
  """
  @spec screen_attrs(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def screen_attrs(screen_module, opts \\ []) when is_atom(screen_module) and is_list(opts) do
    with {:ok, payload} <- payload(screen_module, opts),
         {:ok, screen_definition} <- Info.screen_definition(screen_module) do
      metadata = build_metadata(screen_definition, Keyword.get(opts, :metadata, %{}))

      {:ok,
       %{
         name: Keyword.get(opts, :name, default_name(screen_module)),
         route: Keyword.get(opts, :route, Map.get(screen_definition, :route)),
         layout: Keyword.get(opts, :layout, Map.get(screen_definition, :layout, :default)),
         metadata: encode_value(metadata),
         unified_dsl: payload,
         active: Keyword.get(opts, :active, true),
         version: Keyword.get(opts, :version, 1)
       }}
    end
  end

  @doc """
  Persists a screen record from a screen resource module.
  """
  @spec create(module(), keyword()) :: {:ok, struct()} | {:error, term()}
  def create(screen_module, opts \\ []) when is_atom(screen_module) and is_list(opts) do
    ui_storage = Keyword.get(opts, :ui_storage)
    screen_resource = Config.screen_resource(ui_storage)

    with {:ok, attrs} <- screen_attrs(screen_module, opts) do
      screen_resource
      |> Data.create(Keyword.put(persistence_opts(opts), :attrs, attrs))
    end
  end

  @doc """
  Validates a persisted resource-authority payload.
  """
  @spec validate_payload(term()) :: :ok | {:error, String.t()}
  def validate_payload(%{} = payload) do
    with true <- authority_payload?(payload) or {:error, "must declare the ash_ui resource_authority format"},
         :ok <- validate_section(payload, "screen"),
         :ok <- validate_elements(Map.get(payload, "elements") || Map.get(payload, :elements, [])) do
      :ok
    else
      false -> {:error, "must declare the ash_ui resource_authority format"}
      {:error, _message} = error -> error
    end
  end

  def validate_payload(_other), do: {:error, "must be a map"}

  defp validate_section(payload, key) do
    section = Map.get(payload, key) || Map.get(payload, String.to_atom(key))

    cond do
      not is_map(section) ->
        {:error, "#{key} must be a map"}

      not valid_module_reference?(Map.get(section, "module") || Map.get(section, :module)) ->
        {:error, "#{key} must include a module reference"}

      true ->
        :ok
    end
  end

  defp validate_elements(elements) when is_list(elements) do
    case Enum.find(elements, &(not valid_element_payload?(&1))) do
      nil -> :ok
      invalid -> {:error, "invalid element payload: #{inspect(invalid)}"}
    end
  end

  defp validate_elements(_other), do: {:error, "elements must be a list"}

  defp valid_element_payload?(%{} = element) do
    valid_module_reference?(Map.get(element, "module") || Map.get(element, :module)) and
      is_map(Map.get(element, "dsl") || Map.get(element, :dsl)) and
      is_list(Map.get(element, "bindings") || Map.get(element, :bindings, [])) and
      is_list(Map.get(element, "actions") || Map.get(element, :actions, []))
  end

  defp valid_element_payload?(_other), do: false

  defp valid_module_reference?(value) when is_binary(value), do: String.trim(value) != ""
  defp valid_module_reference?(_other), do: false

  defp fetch_element_modules(screen_definition) do
    {:ok, Map.get(screen_definition, :elements, [])}
  end

  defp build_elements(element_modules) do
    Enum.reduce_while(element_modules, {:ok, []}, fn element_module, {:ok, acc} ->
      with :element <- Info.resource_role(element_module),
           {:ok, element_definition} <- Info.element_definition(element_module),
           {:ok, bindings} <- Info.element_bindings(element_module),
           {:ok, actions} <- Info.element_actions(element_module) do
        element_payload = %{
          "module" => encode_module(element_module),
          "dsl" => encode_element_definition(element_definition),
          "bindings" => Enum.map(bindings, &encode_binding/1),
          "actions" => Enum.map(actions, &encode_action/1)
        }

        {:cont, {:ok, acc ++ [element_payload]}}
      else
        :screen ->
          {:halt, {:error, {:expected_element_resource, element_module}}}

        {:error, _reason} = error ->
          {:halt, error}

        other ->
          {:halt, {:error, {:invalid_element_resource, element_module, other}}}
      end
    end)
  end

  defp encode_binding(binding) do
    binding
    |> Enum.into(%{})
    |> encode_value()
  end

  defp encode_action(action) do
    action
    |> Enum.into(%{})
    |> encode_value()
  end

  defp encode_element_definition(definition) do
    definition
    |> Map.new()
    |> update_type()
    |> encode_value()
  end

  defp update_type(definition) do
    case Map.fetch(definition, :type) do
      {:ok, type} when is_atom(type) -> Map.put(definition, :type, Atom.to_string(type))
      _ -> definition
    end
  end

  defp build_metadata(screen_definition, metadata) do
    metadata
    |> Map.new()
    |> Map.merge(Map.get(screen_definition, :metadata, %{}))
  end

  defp default_name(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp persistence_opts(opts) do
    opts
    |> Keyword.drop([:name, :route, :layout, :metadata, :ui_storage, :active, :version])
  end

  defp encode_module(module) when is_atom(module), do: Atom.to_string(module)

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} -> {to_string(key), encode_value(nested_value)} end)
  end

  defp encode_value(value) when is_list(value), do: Enum.map(value, &encode_value/1)
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
