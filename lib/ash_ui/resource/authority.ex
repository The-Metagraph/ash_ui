defmodule AshUI.Resource.Authority do
  @moduledoc """
  Persists screen records from resource-local Ash UI authoring modules.

  Resource modules are the authoritative authoring units. The persisted
  `unified_dsl` payload generated here is a storage snapshot of the
  relationship-driven screen and element graph, not the primary source of
  truth.
  """

  alias AshUI.Config
  alias AshUI.Data
  alias AshUI.Resource.Info

  @format "ash_ui/resource_authority"
  @version 2

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
         {:ok, composition_roots} <- build_composition(screen_module),
         {:ok, elements} <- build_elements(composition_roots) do
      screen_metadata = build_metadata(screen_definition, Keyword.get(opts, :metadata, %{}))

      {:ok,
       %{
         "format" => @format,
         "version" => @version,
         "screen" => %{
           "module" => encode_module(screen_module),
           "name" => Keyword.get(opts, :name, default_name(screen_module)),
           "route" => Keyword.get(opts, :route, Map.get(screen_definition, :route)),
           "layout" =>
             encode_value(Keyword.get(opts, :layout, Map.get(screen_definition, :layout, :default))),
           "metadata" => encode_value(screen_metadata),
           "inline_fragment" => encode_value(Map.get(screen_definition, :inline_fragment)),
           "bindings" => Enum.map(screen_bindings, &encode_binding/1)
         },
         "composition" => %{
           "roots" => composition_roots
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
         :ok <- validate_nested_map(payload, "composition"),
         :ok <- validate_elements(Map.get(payload, "elements") || Map.get(payload, :elements, [])),
         :ok <- validate_composition(payload) do
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

  defp validate_nested_map(payload, key) do
    case Map.get(payload, key) || Map.get(payload, String.to_atom(key)) do
      value when is_map(value) -> :ok
      _other -> {:error, "#{key} must be a map"}
    end
  end

  defp validate_elements(elements) when is_list(elements) do
    case Enum.find(elements, &(not valid_element_payload?(&1))) do
      nil -> :ok
      invalid -> {:error, "invalid element payload: #{inspect(invalid)}"}
    end
  end

  defp validate_elements(_other), do: {:error, "elements must be a list"}

  defp validate_composition(payload) do
    roots =
      payload
      |> get_in(["composition", "roots"])
      |> List.wrap()

    element_modules =
      payload
      |> Map.get("elements", [])
      |> Enum.map(&(Map.get(&1, "module") || Map.get(&1, :module)))
      |> MapSet.new()

    validate_composition_nodes(roots, element_modules)
  end

  defp validate_composition_nodes(nodes, element_modules) when is_list(nodes) do
    case Enum.find_value(nodes, fn node ->
           case validate_composition_node(node, element_modules) do
             :ok -> nil
             {:error, _message} = error -> error
           end
         end) do
      nil -> :ok
      {:error, _message} = error -> error
    end
  end

  defp validate_composition_nodes(_other, _element_modules) do
    {:error, "composition.roots must be a list"}
  end

  defp validate_composition_node(%{} = node, element_modules) do
    module_ref = Map.get(node, "module") || Map.get(node, :module)
    relationship = Map.get(node, "relationship") || Map.get(node, :relationship)
    children = Map.get(node, "children") || Map.get(node, :children, [])

    cond do
      not valid_module_reference?(module_ref) ->
        {:error, "composition nodes must include a module reference"}

      not MapSet.member?(element_modules, module_ref) ->
        {:error, "composition references unknown element module #{inspect(module_ref)}"}

      not is_map(relationship) ->
        {:error, "composition nodes must include relationship metadata"}

      not is_list(children) ->
        {:error, "composition node children must be a list"}

      true ->
        validate_composition_nodes(children, element_modules)
    end
  end

  defp validate_composition_node(_other, _element_modules) do
    {:error, "composition nodes must be maps"}
  end

  defp valid_element_payload?(%{} = element) do
    valid_module_reference?(Map.get(element, "module") || Map.get(element, :module)) and
      is_map(Map.get(element, "dsl") || Map.get(element, :dsl)) and
      is_list(Map.get(element, "bindings") || Map.get(element, :bindings, [])) and
      is_list(Map.get(element, "actions") || Map.get(element, :actions, []))
  end

  defp valid_element_payload?(_other), do: false

  defp valid_module_reference?(value) when is_binary(value), do: String.trim(value) != ""
  defp valid_module_reference?(_other), do: false

  defp build_composition(screen_module) do
    with {:ok, edges} <- Info.composition_edges(screen_module) do
      traverse_edges(edges, MapSet.new([screen_module]))
    end
  end

  defp traverse_edges(edges, ancestry) do
    duplicates =
      edges
      |> Enum.group_by(& &1.destination)
      |> Enum.filter(fn {_module, related} -> length(related) > 1 end)
      |> Enum.map(fn {module, _related} -> encode_module(module) end)

    if duplicates != [] do
      {:error, {:duplicate_composition_relationships, duplicates}}
    else
      edges
      |> Enum.sort_by(fn edge ->
        {placement_rank(edge.placement), edge.order, Atom.to_string(edge.name)}
      end)
      |> Enum.reduce_while({:ok, []}, fn edge, {:ok, acc} ->
        case build_node(edge, ancestry) do
          {:ok, node} -> {:cont, {:ok, acc ++ [node]}}
          {:error, _reason} = error -> {:halt, error}
        end
      end)
    end
  end

  defp placement_rank(:prepend), do: 0
  defp placement_rank("prepend"), do: 0
  defp placement_rank(_other), do: 1

  defp build_node(edge, ancestry) do
    if MapSet.member?(ancestry, edge.destination) do
      {:error,
       {:cyclical_composition,
        Enum.map(MapSet.to_list(ancestry), &encode_module/1) ++ [encode_module(edge.destination)]}}
    else
      with {:ok, child_edges} <- Info.composition_edges(edge.destination),
           {:ok, children} <- traverse_edges(child_edges, MapSet.put(ancestry, edge.destination)) do
        {:ok,
         %{
           "module" => encode_module(edge.destination),
           "relationship" => encode_relationship(edge),
           "children" => children
         }}
      end
    end
  end

  defp build_elements(composition_roots) do
    modules =
      composition_roots
      |> collect_modules()
      |> Enum.uniq()

    Enum.reduce_while(modules, {:ok, []}, fn element_module, {:ok, acc} ->
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

  defp collect_modules(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, fn node ->
      module_name = Map.get(node, "module")
      module = decode_module(module_name)

      [module | collect_modules(Map.get(node, "children", []))]
    end)
  end

  defp encode_relationship(edge) do
    %{
      "name" => Atom.to_string(edge.name),
      "type" => encode_value(edge.type),
      "kind" => encode_value(edge.kind),
      "slot" => encode_value(edge.slot),
      "placement" => encode_value(edge.placement),
      "order" => edge.order
    }
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

  defp decode_module(module_name) when is_binary(module_name) do
    module_name
    |> String.split(".")
    |> Module.concat()
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} -> {to_string(key), encode_value(nested_value)} end)
  end

  defp encode_value(value) when is_list(value), do: Enum.map(value, &encode_value/1)
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
