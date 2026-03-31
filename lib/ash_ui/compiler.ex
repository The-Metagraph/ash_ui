defmodule AshUI.Compiler do
  @moduledoc """
  Compiler that converts Ash Resources to IUR structures.

  This module handles the compilation of Ash UI resources (Screen, Element, Binding)
  into the internal IUR (Intermediate UI Representation) format.

  Phase 6 adds unified-ui compiler integration with caching.
  """

  require Ash.Query
  require Logger

  alias AshUI.Compilation.IUR
  alias AshUI.Config
  alias AshUI.Resource.Authority
  alias AshUI.Telemetry

  @type compile_result :: {:ok, IUR.t()} | {:error, term()}
  @type screen_record :: struct()

  @doc """
  Compiles a screen resource to an IUR structure.

  ## Options
    * `use_cache` - Whether to use compilation cache (default: true)
    * `:actor` - Actor for authorization
    * `:tenant` - Tenant for multi-tenancy
  """
  @spec compile(screen_record() | String.t() | integer(), keyword()) :: compile_result()
  def compile(screen, opts \\ [])

  def compile(screen_id, opts) when is_binary(screen_id) or is_integer(screen_id) do
    started_at = System.monotonic_time()
    metadata = compile_metadata(screen_id, opts)
    Telemetry.emit(:compilation, :compile_start, %{count: 1}, metadata)

    result = do_compile_by_id(screen_id, opts)

    emit_compile_telemetry(result, started_at, metadata)
  end

  def compile(%_{} = screen, opts) do
    if screen_resource?(screen, opts) do
      started_at = System.monotonic_time()
      metadata = compile_metadata(screen, opts)
      Telemetry.emit(:compilation, :compile_start, %{count: 1}, metadata)

      result = do_compile_screen(screen, opts)

      emit_compile_telemetry(result, started_at, metadata)
    else
      {:error, {:invalid_screen_resource, screen.__struct__}}
    end
  end

  @doc """
  Compiles a screen from its persisted authoritative `unified_dsl` payload.

  Resource-authority screens regenerate their compiler input from the screen
  record plus the current screen/element resource graph, using the persisted
  payload only to resolve the root screen module and screen-level overrides.
  """
  @spec compile_from_unified_dsl(screen_record(), keyword()) :: compile_result()
  def compile_from_unified_dsl(screen, opts \\ [])

  def compile_from_unified_dsl(screen, opts) when is_map(screen) do
    dsl = Map.get(screen, :unified_dsl)

    cond do
      not screen_resource?(screen, opts) ->
        {:error, :invalid_screen}

      not is_map(dsl) ->
        {:error, :invalid_screen}

      Authority.authority_payload?(dsl) ->
        compile_from_resource_authority(screen, dsl)

      true ->
        {:error, {:invalid_screen_dsl, :unsupported_format}}
    end
  end

  @doc """
  Compiles multiple screens in batch.

  ## Examples

      {:ok, results} = AshUI.Compiler.compile_batch(["screen-1", "screen-2"])
  """
  @spec compile_batch([String.t() | integer()], keyword()) :: {:ok, map()} | {:error, term()}
  def compile_batch(screen_ids, opts \\ []) when is_list(screen_ids) do
    results =
      Enum.reduce(screen_ids, %{}, fn screen_id, acc ->
        case compile(screen_id, opts) do
          {:ok, iur} -> Map.put(acc, screen_id, iur)
          {:error, _reason} -> acc
        end
      end)

    {:ok, results}
  end

  @doc """
  Invalidates compilation cache for a screen.

  ## Examples

      AshUI.Compiler.invalidate_cache("screen-1")
  """
  @spec invalidate_cache(String.t() | integer()) :: :ok
  def invalidate_cache(screen_id) do
    delete_from_cache_prefix(cache_key_prefix(screen_id))
    :ok
  end

  @doc """
  Clears entire compilation cache.

  ## Examples

      AshUI.Compiler.clear_cache()
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    try do
      :ets.delete_all_objects(:ash_ui_compiler_cache)
    rescue
      ArgumentError -> :ok
    end

    reset_cache_stats()

    :ok
  end

  @doc """
  Gets cache statistics.

  ## Examples

      stats = AshUI.Compiler.cache_stats()
      # => %{size: 10, hits: 100, misses: 5}
  """
  @spec cache_stats() :: map()
  def cache_stats do
    size =
      case :ets.info(:ash_ui_compiler_cache, :size) do
        :undefined -> 0
        info when is_integer(info) -> info
      end

    %{size: size, hits: get_hit_count(), misses: get_miss_count()}
  end

  @doc """
  Initializes the compiler cache.

  Called during application startup.
  """
  @spec init_cache() :: :ok
  def init_cache do
    try do
      :ets.new(
        :ash_ui_compiler_cache,
        [:named_table, :public, read_concurrency: true, write_concurrency: true]
      )
    rescue
      ArgumentError ->
        # Table already exists
        :ok
    end

    ensure_stats_table()
    reset_cache_stats()

    :ok
  end

  # Private functions

  defp do_compile_by_id(screen_id, opts) do
    use_cache = Keyword.get(opts, :use_cache, true)

    with {:ok, screen} <- load_screen(screen_id, opts) do
      cache_key = build_cache_key(screen)

      case maybe_get_cached(cache_key, use_cache) do
        {:ok, cached_iur, :cached} ->
          {:ok, cached_iur}

        :cache_miss ->
          compile_and_cache(screen, cache_key, opts)
      end
    end
  end

  defp do_compile_screen(screen, opts) when is_map(screen) do
    use_cache = Keyword.get(opts, :use_cache, true)
    cache_key = build_cache_key(screen)

    case maybe_get_cached(cache_key, use_cache) do
      {:ok, cached_iur, :cached} ->
        {:ok, cached_iur}

      :cache_miss ->
        if use_cache do
          compile_and_cache(screen, cache_key, opts)
        else
          compile_from_unified_dsl(screen, opts)
        end
    end
  end

  defp load_screen(screen_id, opts) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)
    ui_storage = Keyword.get(opts, :ui_storage)
    screen_resource = Config.screen_resource(ui_storage)
    domain = Config.ui_storage_domain(ui_storage)

    case Ash.get(screen_resource, screen_id, actor: actor, tenant: tenant, domain: domain) do
      {:ok, screen} -> {:ok, screen}
      {:error, reason} -> {:error, {:screen_not_found, reason}}
    end
  end

  defp build_cache_key(screen) when is_map(screen) do
    version = Map.get(screen, :version, 1)
    "screen:#{screen.id}:v#{version}:#{document_cache_suffix(screen)}"
  end

  defp cache_key_prefix(screen_id), do: "screen:#{screen_id}:"

  defp maybe_get_cached(cache_key, true) do
    case get_from_cache(cache_key) do
      {:ok, iur} ->
        increment_hit_count()
        {:ok, iur, :cached}

      :miss ->
        increment_miss_count()
        :cache_miss
    end
  end

  defp maybe_get_cached(_cache_key, false), do: :cache_miss

  defp emit_compile_telemetry(result, started_at, metadata) do
    duration = System.monotonic_time() - started_at

    case result do
      {:ok, _compiled} = success ->
        Telemetry.emit(
          :compilation,
          :compile_end,
          %{count: 1, duration: duration},
          Map.put(metadata, :status, :ok)
        )

        success

      {:error, reason} = error ->
        error_metadata = Map.merge(metadata, %{status: :error, error: inspect(reason)})

        Telemetry.emit(
          :compilation,
          :compile_error,
          %{count: 1, duration: duration},
          error_metadata
        )

        error
    end
  end

  defp compile_metadata(screen, opts) when is_map(screen) do
    %{
      resource_id: screen.id,
      resource_type: :screen,
      screen_id: screen.id,
      cache: Keyword.get(opts, :use_cache, true)
    }
  end

  defp compile_metadata(screen_id, opts) do
    %{
      resource_id: screen_id,
      resource_type: :screen,
      screen_id: screen_id,
      cache: Keyword.get(opts, :use_cache, true)
    }
  end

  defp get_from_cache(cache_key) do
    case :ets.lookup(:ash_ui_compiler_cache, cache_key) do
      [{^cache_key, iur, _timestamp}] -> {:ok, iur}
      [] -> :miss
    end
  rescue
    ArgumentError -> :miss
  end

  defp delete_from_cache_prefix(prefix) do
    try do
      :ash_ui_compiler_cache
      |> :ets.tab2list()
      |> Enum.each(fn {cache_key, _iur, _timestamp} ->
        if String.starts_with?(cache_key, prefix) do
          :ets.delete(:ash_ui_compiler_cache, cache_key)
        end
      end)
    rescue
      ArgumentError -> :ok
    end

    :ok
  end

  defp compile_and_cache(screen, cache_key, opts) do
    with {:ok, iur} <- compile(screen, Keyword.put(opts, :use_cache, false)),
         :ok <- store_in_cache(cache_key, iur) do
      {:ok, iur}
    end
  end

  defp store_in_cache(cache_key, iur) do
    try do
      :ets.insert(
        :ash_ui_compiler_cache,
        {cache_key, iur, System.system_time(:second)}
      )
    rescue
      ArgumentError -> :ok
    end

    :ok
  end

  defp compile_from_resource_authority(screen, document)
       when is_map(screen) and is_map(document) do
    with {:ok, runtime_document} <- Authority.runtime_payload(screen),
         {:ok, element_index} <- authority_element_index(runtime_document),
         {compiled_children, bindings} <-
           compile_authority_roots(runtime_document, screen, element_index),
         merged_children <- merge_inline_screen_children(runtime_document, compiled_children),
         root_iur <-
           IUR.new(:screen,
             id: screen.id,
             name: screen.name,
             attributes: %{
               "layout" => screen.layout,
               "route" => screen.route,
               "unified_dsl" => screen.unified_dsl
             },
             children: merged_children,
             bindings: bindings,
             metadata: compile_authority_runtime_metadata(screen, runtime_document),
             version: "v#{screen.version || 1}"
           ),
         :ok <- IUR.validate(root_iur) do
      {:ok, root_iur}
    end
  end

  defp authority_element_index(document) do
    elements =
      document
      |> Map.get("elements", [])
      |> List.wrap()

    index =
      Enum.reduce(elements, %{}, fn element, acc ->
        Map.put(acc, Map.get(element, "module"), element)
      end)

    {:ok, index}
  end

  defp compile_authority_roots(document, screen, element_index) do
    roots =
      document
      |> get_in(["composition", "roots"])
      |> List.wrap()

    screen_module = get_in(document, ["screen", "module"])

    screen_bindings =
      document
      |> get_in(["screen", "bindings"])
      |> List.wrap()
      |> Enum.map(&compile_screen_binding(&1, screen.id, screen_module))

    Enum.reduce(Enum.with_index(roots), {[], screen_bindings}, fn {node, index},
                                                                  {children, bindings} ->
      {compiled, updated_bindings} =
        compile_authority_node(node, screen, element_index, [index], bindings)

      {children ++ [compiled], updated_bindings}
    end)
  end

  defp compile_authority_node(node, screen, element_index, path, bindings)
       when is_map(node) and is_map(screen) do
    module_ref = Map.get(node, "module")
    relationship = Map.get(node, "relationship", %{})
    element = Map.fetch!(element_index, module_ref)
    dsl = Map.get(element, "dsl", %{})
    kind = Map.get(dsl, "type")
    element_id = authority_element_id(dsl, module_ref, path)

    {children, bindings} =
      node
      |> Map.get("children", [])
      |> Enum.with_index()
      |> Enum.reduce({[], bindings}, fn {child, index}, {compiled_children, acc} ->
        {compiled_child, updated_bindings} =
          compile_authority_node(child, screen, element_index, path ++ [index], acc)

        {compiled_children ++ [compiled_child], updated_bindings}
      end)

    element_bindings =
      element
      |> Map.get("bindings", [])
      |> Enum.map(&compile_element_binding(&1, screen.id, element_id, module_ref, kind))

    action_bindings =
      element
      |> Map.get("actions", [])
      |> Enum.map(&compile_action_binding(&1, screen.id, element_id, module_ref, kind))

    metadata =
      dsl
      |> Map.get("metadata", %{})
      |> normalize_snapshot()
      |> Map.put("authoring_module", module_ref)
      |> Map.put("composition", normalize_snapshot(relationship))

    props = Map.get(dsl, "props", %{}) |> normalize_snapshot()

    compiled =
      IUR.new(kind_to_iur_type(kind),
        id: element_id,
        name: element_id,
        attributes: props,
        props: props,
        children: children,
        metadata: metadata
      )

    {compiled, bindings ++ element_bindings ++ action_bindings}
  end

  defp merge_inline_screen_children(document, compiled_children) do
    case get_in(document, ["screen", "inline_fragment"]) do
      nil ->
        compiled_children

      fragment when is_map(fragment) ->
        [compile_inline_fragment(fragment, compiled_children, ["screen_inline"])]
    end
  end

  defp compile_inline_fragment(%{} = fragment, extra_children, path) do
    type = Map.get(fragment, "type")
    props = Map.get(fragment, "props", %{}) |> normalize_snapshot()
    metadata = Map.get(fragment, "metadata", %{}) |> normalize_snapshot()
    variants = Map.get(fragment, "variants", []) |> normalize_snapshot()
    fragment_id = authority_inline_id(metadata, type, path)

    inline_children =
      fragment
      |> Map.get("children", [])
      |> Enum.with_index()
      |> Enum.map(fn {child, index} ->
        compile_inline_fragment(child, [], path ++ [index])
      end)

    IUR.new(kind_to_iur_type(type),
      id: fragment_id,
      name: fragment_id,
      attributes: props,
      props: props,
      children: inline_children ++ extra_children,
      metadata: Map.put(metadata, "variants", variants)
    )
  end

  defp compile_screen_binding(binding, screen_id, screen_module) do
    binding
    |> normalize_snapshot()
    |> Map.put("binding_type", normalize_binding_type(Map.get(binding, "binding_type")))
    |> Map.put("screen_id", screen_id)
    |> Map.put("element_id", nil)
    |> Map.put("id", runtime_identifier(Map.get(binding, "id")))
    |> Map.put(
      "metadata",
      owner_metadata(binding, %{
        "owner_scope" => "screen",
        "owner_module" => screen_module,
        "owner_signal" => nil
      })
    )
    |> Map.put("transform", normalize_snapshot(Map.get(binding, "transform", %{})))
  end

  defp compile_element_binding(binding, screen_id, element_id, module_ref, widget_type) do
    binding
    |> normalize_snapshot()
    |> Map.put("binding_type", normalize_binding_type(Map.get(binding, "binding_type")))
    |> Map.put("screen_id", screen_id)
    |> Map.put("element_id", element_id)
    |> Map.put("id", runtime_identifier(Map.get(binding, "id")))
    |> Map.put(
      "metadata",
      owner_metadata(binding, %{
        "owner_scope" => "element",
        "owner_module" => module_ref,
        "owner_element_id" => element_id,
        "owner_widget_type" => kind_to_iur_type(widget_type),
        "owner_signal" => nil
      })
    )
    |> Map.put("transform", normalize_snapshot(Map.get(binding, "transform", %{})))
  end

  defp compile_action_binding(action, screen_id, element_id, module_ref, widget_type) do
    action
    |> normalize_snapshot()
    |> Map.put("binding_type", :action)
    |> Map.put("screen_id", screen_id)
    |> Map.put("element_id", element_id)
    |> Map.put("id", runtime_identifier(Map.get(action, "id")))
    |> Map.put(
      "metadata",
      owner_metadata(action, %{
        "owner_scope" => "element",
        "owner_module" => module_ref,
        "owner_element_id" => element_id,
        "owner_widget_type" => kind_to_iur_type(widget_type),
        "owner_signal" => normalize_snapshot(Map.get(action, "signal"))
      })
    )
    |> Map.put("transform", normalize_snapshot(Map.get(action, "transform", %{})))
  end

  defp owner_metadata(binding_or_action, ownership) do
    binding_or_action
    |> Map.get("metadata", %{})
    |> normalize_snapshot()
    |> Map.merge(ownership, fn _key, stored, override ->
      if is_nil(override), do: stored, else: override
    end)
  end

  defp authority_element_id(dsl, module_ref, path) do
    metadata = Map.get(dsl, "metadata", %{})

    runtime_identifier(Map.get(metadata, "id")) ||
      module_ref
      |> String.split(".")
      |> List.last()
      |> Macro.underscore()
      |> case do
        "" -> "authority_#{Enum.join(path, "_")}"
        name -> name
      end
  end

  defp authority_inline_id(metadata, type, path) do
    runtime_identifier(Map.get(metadata, "id")) ||
      "inline_#{runtime_identifier(type)}_#{Enum.join(path, "_")}"
  end

  defp compile_authority_runtime_metadata(screen, document) do
    screen_bindings = get_in(document, ["screen", "bindings"]) || []
    inline_fragment = get_in(document, ["screen", "inline_fragment"])

    screen.metadata
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> Map.put("ash_ui", %{
      "compiler_boundary" => "AshUI resource graph -> AshUI runtime normalization",
      "authoring_source" => %{
        "module" => get_in(document, ["screen", "module"]),
        "kind" => "resource_authority"
      },
      "resource_authority" => %{
        "screen_module" => get_in(document, ["screen", "module"]),
        "composition_root_count" => length(get_in(document, ["composition", "roots"]) || []),
        "composition_mode" =>
          if(is_map(inline_fragment), do: "mixed", else: "relationships_only"),
        "screen_binding_ids" => Enum.map(screen_bindings, &Map.get(&1, "id")),
        "screen_shell" => screen_shell_metadata(inline_fragment)
      }
    })
    |> Map.put_new("title", get_in(document, ["screen", "metadata", "title"]))
  end

  defp screen_shell_metadata(nil), do: nil

  defp screen_shell_metadata(fragment) when is_map(fragment) do
    metadata = Map.get(fragment, "metadata", %{})

    %{
      "id" => Map.get(metadata, "id"),
      "type" => Map.get(fragment, "type"),
      "source" => "screen_inline_fragment"
    }
  end

  # Cache statistics helpers

  defp get_hit_count do
    case :ets.whereis(:ash_ui_cache_stats) do
      :undefined ->
        0

      _ ->
        case :ets.lookup(:ash_ui_cache_stats, :hits) do
          [{:hits, count}] -> count
          [{:hits, count, _}] -> count
          [] -> 0
        end
    end
  end

  defp get_miss_count do
    case :ets.whereis(:ash_ui_cache_stats) do
      :undefined ->
        0

      _ ->
        case :ets.lookup(:ash_ui_cache_stats, :misses) do
          [{:misses, count}] -> count
          [{:misses, count, _}] -> count
          [] -> 0
        end
    end
  end

  defp increment_hit_count do
    ensure_stats_table()
    :ets.update_counter(:ash_ui_cache_stats, :hits, {2, 1}, {1, 0, 1})
  end

  defp increment_miss_count do
    ensure_stats_table()
    :ets.update_counter(:ash_ui_cache_stats, :misses, {2, 1}, {1, 0, 1})
  end

  defp reset_cache_stats do
    case :ets.whereis(:ash_ui_cache_stats) do
      :undefined -> :ok
      _ -> :ets.delete_all_objects(:ash_ui_cache_stats)
    end
  end

  defp ensure_stats_table do
    :ets.new(:ash_ui_cache_stats, [:named_table, :public])
  rescue
    ArgumentError -> :ok
  end

  defp screen_resource?(%{__struct__: module}, opts) do
    module == Config.screen_resource(Keyword.get(opts, :ui_storage))
  end

  defp screen_resource?(_screen, _opts), do: false

  defp normalize_binding_type(:action), do: :action
  defp normalize_binding_type("action"), do: :action
  defp normalize_binding_type(:event), do: :action
  defp normalize_binding_type("event"), do: :action
  defp normalize_binding_type(:list), do: :list
  defp normalize_binding_type("list"), do: :list
  defp normalize_binding_type(:collection), do: :list
  defp normalize_binding_type("collection"), do: :list
  defp normalize_binding_type(_other), do: :value

  defp kind_to_iur_type(kind) when is_binary(kind) do
    case kind do
      "text_input" -> :textinput
      "radio_group" -> :radio
      "toggle" -> :switch
      "separator" -> :divider
      other -> String.to_atom(other)
    end
  end

  defp kind_to_iur_type(kind) when is_atom(kind), do: kind_to_iur_type(Atom.to_string(kind))

  defp runtime_identifier(nil), do: nil
  defp runtime_identifier(id) when is_binary(id), do: id
  defp runtime_identifier(id) when is_atom(id), do: Atom.to_string(id)
  defp runtime_identifier(id), do: to_string(id)

  defp document_cache_suffix(screen) do
    authority_cache_suffix(screen)
  end

  defp authority_cache_suffix(screen) do
    case Authority.runtime_payload(screen) do
      {:ok, payload} ->
        hash = document_hash(payload)
        "graph-#{hash}:compiler-resource_graph"

      {:error, _reason} ->
        hash = document_hash(Map.get(screen, :unified_dsl, %{}))
        "graph-fallback-#{hash}:compiler-resource_graph"
    end
  end

  defp document_hash(document) do
    document
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)
  end

  defp normalize_snapshot(value) when is_list(value) do
    cond do
      value == [] ->
        []

      Keyword.keyword?(value) ->
        value
        |> Enum.map(fn {key, item} -> {to_string(key), normalize_snapshot(item)} end)
        |> Enum.into(%{})

      true ->
        Enum.map(value, &normalize_snapshot/1)
    end
  end

  defp normalize_snapshot(value) when is_map(value) do
    value
    |> Enum.map(fn {key, item} -> {to_string(key), normalize_snapshot(item)} end)
    |> Enum.into(%{})
  end

  defp normalize_snapshot(value), do: value
end
