defmodule AshUI.Authoring.Document do
  @moduledoc """
  Persisted-screen authoring bridge for upstream `UnifiedUi.Dsl` modules.

  Phase 10 defines the durable `Screen.unified_dsl` contract as an Ash UI
  wrapper around an upstream-authored `unified_ui` document plus Ash UI-owned
  screen metadata, binding annotations, and migration/runtime metadata.
  """

  alias AshUI.Authoring
  alias AshUI.DSL.Storage

  @format "ash_ui/unified_ui_document"
  @version 2

  @type t :: map()

  @doc """
  Returns the current persisted authoring format identifier.
  """
  @spec format() :: String.t()
  def format, do: @format

  @doc """
  Returns the current persisted authoring document version.
  """
  @spec version() :: pos_integer()
  def version, do: @version

  @doc """
  Builds a persisted authoring document from a `UnifiedUi.Dsl` module.
  """
  @spec new(module(), keyword()) :: {:ok, t()} | {:error, term()}
  def new(module, opts \\ []) when is_atom(module) and is_list(opts) do
    with :ok <- validate_module(module) do
      module_summary = UnifiedUi.Info.module_summary(module)
      composition_summary = UnifiedUi.Info.composition_summary(module)
      compiler_summary = UnifiedUi.Compiler.summary(module)
      compiler_listing = UnifiedUi.Compiler.listing(module)

      screen_name = opts[:name] || default_name(module_summary, module)

      {:ok,
       %{
         "format" => @format,
         "version" => @version,
         "authoring" => %{
           "source" => %{
             "kind" => "unified_ui_module",
             "module" => encode_module(module)
           },
           "package" => encode_value(Authoring.package_identity()),
           "document" => %{
             "module_summary" => encode_value(module_summary),
             "composition_summary" => encode_value(composition_summary),
             "compiler_summary" => encode_value(compiler_summary),
             "compiler_listing" => encode_value(compiler_listing)
           }
         },
         "ash_ui" => %{
           "screen" => %{
             "name" => screen_name,
             "layout" => encode_value(Keyword.get(opts, :layout, :default)),
             "route" => opts[:route]
           },
           "metadata" => encode_value(Keyword.get(opts, :metadata, %{})),
           "binding_metadata" => encode_value(Keyword.get(opts, :binding_metadata, %{})),
           "runtime_annotations" => %{
             "extension_points" => encode_value(Authoring.extension_points()),
             "construct_families" => encode_value(Authoring.construct_families())
           }
         }
       }}
    end
  rescue
    error in [
      ArgumentError,
      FunctionClauseError,
      RuntimeError,
      Spark.Error.DslError,
      UndefinedFunctionError
    ] ->
      {:error, {:invalid_unified_ui_module, module, Exception.message(error)}}
  end

  @doc """
  Wraps a deterministic migration from a legacy builder DSL into the Phase 10
  persisted document contract.
  """
  @spec migration_document(map(), map(), map(), keyword()) :: {:ok, t()} | {:error, term()}
  def migration_document(serialized_document, compiler_dsl, report, opts \\ [])
      when is_map(serialized_document) and is_map(compiler_dsl) and is_map(report) and
             is_list(opts) do
    screen_name = Keyword.fetch!(opts, :name)

    {:ok,
     %{
       "format" => @format,
       "version" => @version,
       "authoring" => %{
         "source" => %{
           "kind" => "legacy_builder_migration",
           "migration" => %{
             "from_format" => "ash_ui.dsl.builder",
             "from_version" => 1,
             "mode" => "deterministic"
           }
         },
         "package" => encode_value(Authoring.package_identity()),
         "document" => encode_value(serialized_document)
       },
       "ash_ui" => %{
         "screen" => %{
           "name" => screen_name,
           "layout" => encode_value(Keyword.get(opts, :layout, :default)),
           "route" => opts[:route]
         },
         "metadata" => encode_value(Keyword.get(opts, :metadata, %{})),
         "binding_metadata" => encode_value(Keyword.get(opts, :binding_metadata, %{})),
         "runtime_annotations" => %{
           "extension_points" => encode_value(Authoring.extension_points()),
           "construct_families" => encode_value(Authoring.construct_families()),
           "compiler_dsl" => encode_value(compiler_dsl),
           "migration_report" => encode_value(report)
         }
       }
     }}
  end

  @doc """
  Returns true when the given map matches the current persisted authoring document.
  """
  @spec authoring_document?(term()) :: boolean()
  def authoring_document?(%{"format" => @format, "version" => @version}), do: true
  def authoring_document?(%{format: @format, version: @version}), do: true
  def authoring_document?(_other), do: false

  @doc """
  Returns true when the given map matches the current write format.
  """
  @spec current_document?(term()) :: boolean()
  def current_document?(%{"format" => @format, "version" => @version}), do: true
  def current_document?(%{format: @format, version: @version}), do: true
  def current_document?(_other), do: false

  @doc """
  Validates a persisted authoring document for writes.
  """
  @spec validate(term()) :: :ok | {:error, String.t()}
  def validate(document), do: validate_write(document)

  @doc """
  Validates the current persisted document contract.
  """
  @spec validate_write(term()) :: :ok | {:error, String.t()}
  def validate_write(document) when is_map(document) do
    with true <-
           current_document?(document) or
             {:error, "must declare the Phase 10 ash_ui unified_ui document format"},
         :ok <- validate_nested_map(document, "authoring"),
         :ok <- validate_nested_map(document, "ash_ui"),
         :ok <- validate_authoring_payload(fetch(document, "authoring")),
         :ok <- validate_ash_ui_payload(fetch(document, "ash_ui")) do
      :ok
    else
      false -> {:error, "must declare the Phase 10 ash_ui unified_ui document format"}
      error -> error
    end
  end

  def validate_write(_other), do: {:error, "must be a map"}

  @doc """
  Validates the current persisted authoring document for reads.
  """
  @spec validate_read(term()) :: :ok | {:error, String.t()}
  def validate_read(document) when is_map(document), do: validate_write(document)

  def validate_read(_other), do: {:error, "must be a map"}

  @doc """
  Extracts the compiler lowering carried by a Phase 10 migration document.
  """
  @spec compiler_dsl(term()) :: {:ok, map()} | :error
  def compiler_dsl(document) when is_map(document) do
    case get_in(document, ["ash_ui", "runtime_annotations", "compiler_dsl"]) do
      dsl when is_map(dsl) -> {:ok, dsl}
      _other -> :error
    end
  end

  def compiler_dsl(_other), do: :error

  defp validate_module(module) do
    if Code.ensure_loaded?(module) do
      _ = UnifiedUi.Info.module_summary(module)
      _ = UnifiedUi.Compiler.summary(module)
      :ok
    else
      {:error, {:invalid_unified_ui_module, module, "module is not available"}}
    end
  end

  defp validate_authoring_payload(authoring) do
    with :ok <- validate_nested_map(authoring, "source"),
         :ok <- validate_nested_map(authoring, "package"),
         :ok <- validate_nested_map(authoring, "document") do
      source = fetch(authoring, "source")
      document = fetch(authoring, "document")

      case fetch(source, "kind") do
        "unified_ui_module" ->
          validate_module_document(source, document)

        "legacy_builder_migration" ->
          validate_migrated_document(source, document)

        other ->
          {:error,
           "authoring.source.kind must be \"unified_ui_module\" or \"legacy_builder_migration\", got #{inspect(other)}"}
      end
    end
  end

  defp validate_module_document(source, document) do
    required = [
      "module_summary",
      "composition_summary",
      "compiler_summary",
      "compiler_listing"
    ]

    with module when is_binary(module) and module != "" <- fetch(source, "module"),
         :ok <- validate_required_map_keys(document, required, "authoring.document"),
         true <-
           is_map(document["module_summary"]) or {:error, module_doc_error("module_summary")},
         true <-
           is_list(document["composition_summary"]) or
             {:error, module_doc_error("composition_summary")},
         true <-
           is_map(document["compiler_summary"]) or
             {:error, module_doc_error("compiler_summary")},
         true <-
           is_map(document["compiler_listing"]) or
             {:error, module_doc_error("compiler_listing")} do
      :ok
    else
      value when is_binary(value) -> :ok
      {:error, _message} = error -> error
      _other -> {:error, "authoring.source.module must be a non-empty string"}
    end
  end

  defp validate_ash_ui_payload(ash_ui) do
    with :ok <- validate_nested_map(ash_ui, "screen"),
         :ok <- validate_nested_map(ash_ui, "metadata"),
         :ok <- validate_nested_map(ash_ui, "binding_metadata"),
         :ok <- validate_nested_map(ash_ui, "runtime_annotations"),
         :ok <- validate_screen_payload(fetch(ash_ui, "screen")),
         :ok <- validate_runtime_annotations(fetch(ash_ui, "runtime_annotations")) do
      :ok
    end
  end

  defp validate_migrated_document(source, document) do
    with :ok <- validate_nested_map(source, "migration"),
         :ok <- validate_nested_map(document, "identity"),
         :ok <- validate_nested_map(document, "composition"),
         :ok <- validate_nested_map(fetch(document, "composition"), "root"),
         migration <- fetch(source, "migration"),
         true <-
           fetch(migration, "from_format") == "ash_ui.dsl.builder" or
             {:error, "authoring.source.migration.from_format must be \"ash_ui.dsl.builder\""},
         true <-
           fetch(migration, "from_version") == 1 or
             {:error, "authoring.source.migration.from_version must be 1"} do
      :ok
    else
      {:error, _message} = error ->
        error

      _other ->
        {:error,
         "migrated authoring documents must include identity, composition, and migration metadata"}
    end
  end

  defp validate_screen_payload(screen) do
    cond do
      not is_binary(screen["name"]) or screen["name"] == "" ->
        {:error, "ash_ui.screen.name must be a non-empty string"}

      not (is_nil(screen["route"]) or is_binary(screen["route"])) ->
        {:error, "ash_ui.screen.route must be nil or a string"}

      not (is_nil(screen["layout"]) or is_binary(screen["layout"])) ->
        {:error, "ash_ui.screen.layout must be nil or a string"}

      true ->
        :ok
    end
  end

  defp validate_runtime_annotations(runtime_annotations) do
    with :ok <- validate_nested_map(runtime_annotations, "extension_points"),
         :ok <- validate_nested_map(runtime_annotations, "construct_families"),
         :ok <- validate_optional_compiler_dsl(runtime_annotations),
         :ok <- validate_optional_map_field(runtime_annotations, "migration_report") do
      :ok
    end
  end

  defp validate_optional_compiler_dsl(runtime_annotations) do
    case fetch(runtime_annotations, "compiler_dsl") do
      nil ->
        :ok

      dsl when is_map(dsl) ->
        case Storage.validate_write(dsl) do
          :ok -> :ok
          {:error, errors} -> {:error, "compiler_dsl is invalid: #{Enum.join(errors, "; ")}"}
        end

      _other ->
        {:error, "compiler_dsl must be a map when present"}
    end
  end

  defp validate_optional_map_field(map, key) do
    case fetch(map, key) do
      nil -> :ok
      value when is_map(value) -> :ok
      _other -> {:error, "#{key} must be a map when present"}
    end
  end

  defp validate_nested_map(map, key) do
    case fetch(map, key) do
      value when is_map(value) -> :ok
      _other -> {:error, "#{key} must be a map"}
    end
  end

  defp validate_required_map_keys(map, keys, path) do
    case Enum.find(keys, &(not Map.has_key?(map, &1))) do
      nil -> :ok
      missing -> {:error, "#{path} is missing #{missing}"}
    end
  end

  defp module_doc_error(field) do
    "authoring.document.#{field} must be a JSON-safe #{field_type(field)}"
  end

  defp field_type("module_summary"), do: "map"
  defp field_type("composition_summary"), do: "list"
  defp field_type("compiler_summary"), do: "map"
  defp field_type("compiler_listing"), do: "map"

  defp default_name(module_summary, module) do
    module_summary
    |> get_in([:identity, :id])
    |> case do
      value when is_atom(value) -> Atom.to_string(value)
      value when is_binary(value) -> value
      nil -> module |> Module.split() |> List.last() |> Macro.underscore()
    end
  end

  defp encode_module(module) do
    module
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
  end

  defp encode_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, item} -> {encode_key(key), encode_value(item)} end)
    |> Enum.into(%{})
  end

  defp encode_value(value) when is_list(value) do
    cond do
      value == [] ->
        []

      Keyword.keyword?(value) ->
        value
        |> Enum.map(fn {key, item} -> {encode_key(key), encode_value(item)} end)
        |> Enum.into(%{})

      true ->
        Enum.map(value, &encode_value/1)
    end
  end

  defp encode_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp encode_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp encode_value(%Date{} = value), do: Date.to_iso8601(value)
  defp encode_value(%Time{} = value), do: Time.to_iso8601(value)

  defp encode_value(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Map.put("__struct__", encode_module(value.__struct__))
    |> encode_value()
  end

  defp encode_value(value) when is_atom(value) do
    if value in [true, false, nil] do
      value
    else
      Atom.to_string(value)
    end
  end

  defp encode_value(value) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> Enum.map(&encode_value/1)
  end

  defp encode_value(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: to_string(key)

  defp fetch(map, key) do
    Map.get(map, key) ||
      case key do
        "format" -> Map.get(map, :format)
        "version" -> Map.get(map, :version)
        "authoring" -> Map.get(map, :authoring)
        "ash_ui" -> Map.get(map, :ash_ui)
        "source" -> Map.get(map, :source)
        "package" -> Map.get(map, :package)
        "document" -> Map.get(map, :document)
        "screen" -> Map.get(map, :screen)
        "metadata" -> Map.get(map, :metadata)
        "binding_metadata" -> Map.get(map, :binding_metadata)
        "runtime_annotations" -> Map.get(map, :runtime_annotations)
        "migration" -> Map.get(map, :migration)
        "migration_report" -> Map.get(map, :migration_report)
        "compiler_dsl" -> Map.get(map, :compiler_dsl)
        "from_format" -> Map.get(map, :from_format)
        "from_version" -> Map.get(map, :from_version)
        "kind" -> Map.get(map, :kind)
        "module" -> Map.get(map, :module)
        "identity" -> Map.get(map, :identity)
        "composition" -> Map.get(map, :composition)
        "root" -> Map.get(map, :root)
        "module_summary" -> Map.get(map, :module_summary)
        "composition_summary" -> Map.get(map, :composition_summary)
        "compiler_summary" -> Map.get(map, :compiler_summary)
        "compiler_listing" -> Map.get(map, :compiler_listing)
        "name" -> Map.get(map, :name)
        "route" -> Map.get(map, :route)
        "layout" -> Map.get(map, :layout)
        "extension_points" -> Map.get(map, :extension_points)
        "construct_families" -> Map.get(map, :construct_families)
        _other -> nil
      end
  end
end
