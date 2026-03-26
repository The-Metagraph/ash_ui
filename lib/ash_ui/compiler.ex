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
  alias AshUI.Authoring.Document
  alias AshUI.Config
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
  Compiles a screen from its persisted upstream `UnifiedUi` authoring document.

  Ash UI delegates authoring compilation to `UnifiedUi.Compiler`, then
  normalizes that compiler output into the Ash UI runtime shape by:

  * preserving screen route/layout/metadata
  * lowering upstream widgets into Ash UI's internal IUR struct
  * attaching Ash UI-owned runtime binding metadata from the persisted document

  Resource-first compilation is no longer the default path for persisted
  `unified_dsl` screens.
  """
  @spec compile_from_unified_dsl(screen_record(), keyword()) :: compile_result()
  def compile_from_unified_dsl(screen, opts \\ [])

  def compile_from_unified_dsl(screen, opts) when is_map(screen) do
    dsl = Map.get(screen, :unified_dsl)

    with true <- screen_resource?(screen, opts),
         true <- is_map(dsl),
         {:ok, module} <- validate_dsl(dsl),
         {:ok, compiled} <- compile_authored_document(module),
         {:ok, ash_iur} <- compile_to_ash_iur(screen, compiled, dsl),
         :ok <- IUR.validate(ash_iur) do
      {:ok, ash_iur}
    else
      false -> {:error, :invalid_screen}
      error -> error
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
    try do
      case :ets.lookup(:ash_ui_compiler_cache, cache_key) do
        [{^cache_key, iur, _timestamp}] -> {:ok, iur}
        [] -> :miss
      end
    rescue
      ArgumentError -> :miss
    end
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

  defp validate_dsl(dsl) do
    case Document.source_module(dsl) do
      {:ok, module} ->
        {:ok, module}

      {:error, reason} ->
        {:error, normalize_compile_error(reason)}
    end
  end

  defp compile_authored_document(module) when is_atom(module) do
    {:ok, UnifiedUi.Compiler.compile!(module)}
  rescue
    error in [
      ArgumentError,
      FunctionClauseError,
      RuntimeError,
      Spark.Error.DslError,
      UndefinedFunctionError
    ] ->
      {:error, {:upstream_compile_error, module, Exception.message(error)}}
  end

  defp compile_to_ash_iur(screen, %UnifiedUi.Compiler.Result{} = compiled, document)
       when is_map(screen) do
    snapshot = compiled.iur |> UnifiedIUR.Reference.snapshot() |> normalize_snapshot()
    authored_ids = authored_snapshot_ids(compiled)

    children =
      snapshot
      |> Map.get("children", [])
      |> Enum.with_index()
      |> Enum.map(fn {child, index} -> compile_snapshot_child(child, [index], authored_ids) end)
      |> Enum.reject(&is_nil/1)

    root_iur =
      IUR.new(:screen,
        id: screen.id,
        name: screen.name,
        attributes: %{
          "layout" => screen.layout,
          "route" => screen.route,
          "unified_dsl" => screen.unified_dsl
        },
        children: children,
        bindings: compile_runtime_bindings(snapshot, document, screen.id),
        metadata: compile_runtime_metadata(screen, snapshot, compiled, document),
        version: "v#{screen.version || 1}"
      )

    {:ok, root_iur}
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
    try do
      :ets.new(:ash_ui_cache_stats, [:named_table, :public])
    rescue
      ArgumentError -> :ok
    end
  end

  defp screen_resource?(%{__struct__: module}, opts) do
    module == Config.screen_resource(Keyword.get(opts, :ui_storage))
  end

  defp screen_resource?(_screen, _opts), do: false

  defp compile_snapshot_child(%{"element" => nil}, _path, _authored_ids), do: nil

  defp compile_snapshot_child(%{"slot" => slot, "element" => element}, path, authored_ids)
       when is_map(element) do
    compiled = compile_snapshot_element(element, path, authored_ids)
    %{compiled | metadata: Map.put(compiled.metadata, "slot", slot)}
  end

  defp compile_snapshot_element(%{"kind" => kind} = element, path, authored_ids) do
    props = translate_upstream_props(kind, Map.get(element, "attributes", %{}))
    id = runtime_element_id(element, kind, path, authored_ids)

    IUR.new(kind_to_iur_type(kind),
      id: id,
      name: runtime_name(kind, element, id),
      attributes: props,
      props: props,
      children:
        element
        |> Map.get("children", [])
        |> Enum.with_index()
        |> Enum.map(fn {child, index} ->
          compile_snapshot_child(child, path ++ [index], authored_ids)
        end)
        |> Enum.reject(&is_nil/1),
      metadata: normalize_metadata(Map.get(element, "metadata", %{}))
    )
  end

  defp compile_runtime_bindings(_snapshot, document, screen_id) do
    authored_ids = authored_compiled_ids(document)

    document
    |> Document.binding_metadata()
    |> Enum.reduce([], fn {binding_id, metadata}, acc ->
      case build_runtime_binding(binding_id, metadata, screen_id, authored_ids) do
        nil -> acc
        binding -> [binding | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp build_runtime_binding(binding_id, metadata, screen_id, authored_ids)
       when (is_binary(binding_id) or is_atom(binding_id)) and is_map(metadata) do
    source = normalize_runtime_source(Map.get(metadata, "source") || Map.get(metadata, :source))

    if is_map(source) do
      binding_type =
        Map.get(metadata, "binding_type") ||
          Map.get(metadata, :binding_type) ||
          Map.get(metadata, "type") ||
          Map.get(metadata, :type) ||
          infer_binding_type(source)

      binding_type = normalize_binding_type(binding_type)
      element_id = resolve_binding_element_id(binding_id, metadata, authored_ids)
      target = resolve_binding_target(binding_id, metadata, source, binding_type)

      %{
        "id" => runtime_identifier(binding_id),
        "source" => source,
        "target" => target,
        "binding_type" => binding_type,
        "transform" => Map.get(metadata, "transform") || Map.get(metadata, :transform) || %{},
        "element_id" => element_id,
        "screen_id" => screen_id,
        "metadata" =>
          metadata
          |> Map.new(fn {key, value} -> {to_string(key), value} end)
          |> Map.put("authored_binding_id", runtime_identifier(binding_id))
      }
    else
      nil
    end
  end

  defp build_runtime_binding(_binding_id, _metadata, _screen_id, _authored_ids), do: nil

  defp resolve_binding_element_id(binding_id, metadata, authored_ids) do
    explicit =
      Map.get(metadata, "element_id") ||
        Map.get(metadata, :element_id)

    candidate =
      runtime_identifier(explicit || runtime_identifier(binding_id))

    cond do
      explicit ->
        candidate

      MapSet.member?(authored_ids, candidate) ->
        candidate

      true ->
        candidate
    end
  end

  defp resolve_binding_target(binding_id, metadata, source, :value) do
    runtime_identifier(
      Map.get(metadata, "target") ||
        Map.get(metadata, :target) ||
        Map.get(source, "field") ||
        binding_id
    )
  end

  defp resolve_binding_target(_binding_id, metadata, source, :list) do
    runtime_identifier(
      Map.get(metadata, "target") ||
        Map.get(metadata, :target) ||
        Map.get(source, "relationship") ||
        "items"
    )
  end

  defp resolve_binding_target(binding_id, metadata, source, :action) do
    runtime_identifier(
      Map.get(metadata, "target") ||
        Map.get(metadata, :target) ||
        Map.get(source, "action") ||
        binding_id
    )
  end

  defp compile_runtime_metadata(screen, snapshot, compiled, document) do
    screen.metadata
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> Map.put("ash_ui", %{
      "compiler_boundary" => "UnifiedUi.Compiler -> AshUI runtime normalization",
      "authoring_source" => %{
        "module" => compiled.module |> Atom.to_string() |> String.trim_leading("Elixir."),
        "kind" => get_in(document, ["authoring", "source", "kind"])
      },
      "binding_metadata" => Document.binding_metadata(document),
      "upstream" => %{
        "identity" => normalize_snapshot(compiled.identity),
        "composition" => normalize_snapshot(compiled.composition),
        "trace" => normalize_snapshot(compiled.trace)
      }
    })
    |> Map.put_new("title", snapshot_title(snapshot))
  end

  defp normalize_runtime_source(%{} = source) do
    Map.new(source, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_runtime_source(source) when is_binary(source) do
    case String.split(source, ".", parts: 2) do
      [resource, field] -> %{"resource" => resource, "field" => field}
      _other -> %{"value" => source}
    end
  end

  defp normalize_runtime_source(_other), do: nil

  defp infer_binding_type(%{"action" => _action}), do: :action
  defp infer_binding_type(%{"relationship" => _relationship}), do: :list
  defp infer_binding_type(_source), do: :value

  defp normalize_binding_type(:action), do: :action
  defp normalize_binding_type("action"), do: :action
  defp normalize_binding_type(:event), do: :action
  defp normalize_binding_type("event"), do: :action
  defp normalize_binding_type(:list), do: :list
  defp normalize_binding_type("list"), do: :list
  defp normalize_binding_type(:collection), do: :list
  defp normalize_binding_type("collection"), do: :list
  defp normalize_binding_type(_other), do: :value

  defp translate_upstream_props(kind, attributes) do
    attributes = normalize_snapshot(attributes)

    case kind do
      "text" ->
        %{"content" => get_in(attributes, ["content", "text"])}

      "label" ->
        %{"content" => get_in(attributes, ["content", "text"])}

      "badge" ->
        attributes
        |> Map.get("badge", %{})
        |> Map.put("label", get_in(attributes, ["content", "text"]))

      "hero" ->
        Map.get(attributes, "hero", %{})

      "button" ->
        attributes
        |> Map.get("button", %{})
        |> Map.put(
          "label",
          get_in(attributes, ["content", "text"]) || get_in(attributes, ["label", "text"])
        )

      "text_input" ->
        attributes
        |> Map.get("input", %{})
        |> Map.put_new("type", "text")

      "select" ->
        Map.get(attributes, "input", %{})

      "checkbox" ->
        Map.get(attributes, "input", %{})

      "radio_group" ->
        Map.get(attributes, "input", %{})

      "toggle" ->
        Map.get(attributes, "input", %{})

      "slider" ->
        Map.get(attributes, "input", %{})

      "stat" ->
        Map.get(attributes, "stat", %{})

      "key_value" ->
        Map.get(attributes, "key_value", %{})

      "info_list" ->
        Map.get(attributes, "info_list", %{})

      "row" ->
        layout_props(attributes)

      "column" ->
        layout_props(attributes)

      "grid" ->
        layout_props(attributes)

      "stack" ->
        layout_props(attributes)

      _other ->
        flatten_attributes(attributes)
    end
  end

  defp layout_props(attributes) do
    attributes
    |> Map.get("layout", %{})
    |> then(fn layout ->
      if Map.has_key?(layout, "gap") do
        Map.put(layout, "spacing", layout["gap"])
      else
        layout
      end
    end)
  end

  defp flatten_attributes(attributes) do
    Enum.reduce(attributes, %{}, fn
      {key, value}, acc when is_map(value) ->
        Map.merge(acc, Map.put_new(value, "section", key))

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end

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

  defp runtime_name(kind, element, id) do
    runtime_identifier(Map.get(element, "name")) ||
      runtime_identifier(Map.get(element, "id")) ||
      id ||
      "#{kind}_node"
  end

  defp authored_snapshot_ids(%UnifiedUi.Compiler.Result{trace: trace}) do
    trace
    |> Map.get(:authored_ids, [])
    |> Enum.map(&runtime_identifier/1)
    |> MapSet.new()
  end

  defp runtime_element_id(element, kind, path, authored_ids) do
    element_id = runtime_identifier(Map.get(element, "id"))

    cond do
      authored_id?(element_id, authored_ids) ->
        element_id

      generated_runtime_id?(element_id) ->
        derived_runtime_id(kind, path)

      is_binary(element_id) and element_id != "" ->
        element_id

      true ->
        derived_runtime_id(kind, path)
    end
  end

  defp authored_id?(nil, _authored_ids), do: false
  defp authored_id?(id, authored_ids), do: MapSet.member?(authored_ids, id)

  # Upstream anonymous nodes currently arrive with UUID-like ids. Replace those
  # with stable path-derived runtime ids so cache hits and uncached compiles
  # render identically for equivalent authored documents.
  defp generated_runtime_id?(id) when is_binary(id) do
    String.match?(id, ~r/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
  end

  defp generated_runtime_id?(_id), do: false

  defp derived_runtime_id(kind, path) do
    "generated_#{kind}_#{Enum.join(path, "_")}"
  end

  defp snapshot_title(snapshot) do
    snapshot
    |> get_in(["metadata", "annotations", "title"])
    |> case do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end

  defp normalize_metadata(metadata) do
    metadata
    |> normalize_snapshot()
    |> Map.drop(["annotations"])
    |> Map.put("annotations", get_in(normalize_snapshot(metadata), ["annotations"]) || %{})
  end

  defp normalize_compile_error({:unsupported_authoring_document, _reason}) do
    {:unsupported_authoring_document, :phase_11_upstream_modules_only}
  end

  defp normalize_compile_error(reason), do: reason

  defp authored_compiled_ids(document) do
    document
    |> get_in(["authoring", "document", "compiler_listing", "trace", "compiled_element_ids"])
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&runtime_identifier/1)
    |> MapSet.new()
  end

  defp document_cache_suffix(screen) do
    document = Map.get(screen, :unified_dsl, %{})
    hash = document_hash(document)
    compiler = upstream_compiler_version()
    "doc-#{hash}:compiler-#{compiler}"
  end

  defp document_hash(document) do
    document
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)
  end

  defp upstream_compiler_version do
    :unified_ui
    |> Application.spec(:vsn)
    |> to_string()
  rescue
    _ -> "unknown"
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
