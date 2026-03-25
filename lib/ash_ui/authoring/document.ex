defmodule AshUI.Authoring.Document do
  @moduledoc """
  Persisted-screen authoring bridge for upstream `UnifiedUi.Dsl` modules.

  Phase 9 stores authored `UnifiedUi` modules as JSON-safe documents in
  `Screen.unified_dsl`. This keeps `UnifiedUi` authoritative for widgets,
  layouts, themes, and signals while allowing Ash UI to add route metadata,
  screen metadata, and Ash-specific binding metadata around the authored module.
  """

  alias AshUI.Authoring

  @format "ash_ui/unified_ui_module"
  @version 1

  @type t :: map()

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
           "module" => encode_module(module),
           "package" => encode_value(Authoring.package_identity()),
           "module_summary" => encode_value(module_summary),
           "composition_summary" => encode_value(composition_summary),
           "compiler_summary" => encode_value(compiler_summary),
           "compiler_listing" => encode_value(compiler_listing)
         },
         "ash_ui" => %{
           "screen" => %{
             "name" => screen_name,
             "layout" => encode_value(Keyword.get(opts, :layout, :default)),
             "route" => opts[:route]
           },
           "metadata" => encode_value(Keyword.get(opts, :metadata, %{})),
           "binding_metadata" => encode_value(Keyword.get(opts, :binding_metadata, %{})),
           "extension_points" => encode_value(Authoring.extension_points()),
           "construct_families" => encode_value(Authoring.construct_families())
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
  Returns true when the given map is an Ash UI persisted authoring document.
  """
  @spec authoring_document?(term()) :: boolean()
  def authoring_document?(%{"format" => @format, "version" => @version}), do: true
  def authoring_document?(%{format: @format, version: @version}), do: true
  def authoring_document?(_other), do: false

  @doc """
  Validates a persisted authoring document shape.
  """
  @spec validate(term()) :: :ok | {:error, String.t()}
  def validate(document) when is_map(document) do
    with true <-
           authoring_document?(document) or
             {:error, "must declare the ash_ui unified_ui document format"},
         :ok <- validate_nested_map(document, "authoring"),
         :ok <- validate_nested_map(document, "ash_ui"),
         :ok <- validate_authoring_payload(fetch(document, "authoring")),
         :ok <- validate_ash_ui_payload(fetch(document, "ash_ui")) do
      :ok
    else
      false -> {:error, "must declare the ash_ui unified_ui document format"}
      error -> error
    end
  end

  def validate(_other), do: {:error, "must be a map"}

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
    required = [
      "module",
      "package",
      "module_summary",
      "composition_summary",
      "compiler_summary",
      "compiler_listing"
    ]

    case Enum.find(required, &(not Map.has_key?(authoring, &1))) do
      nil ->
        if is_binary(authoring["module"]) and is_map(authoring["module_summary"]) and
             is_list(authoring["composition_summary"]) and is_map(authoring["compiler_summary"]) and
             is_map(authoring["compiler_listing"]) do
          :ok
        else
          {:error,
           "authoring payload must include JSON-safe module, summary, composition, and compiler metadata"}
        end

      missing ->
        {:error, "authoring payload is missing #{missing}"}
    end
  end

  defp validate_ash_ui_payload(ash_ui) do
    with :ok <- validate_nested_map(ash_ui, "screen"),
         :ok <- validate_nested_map(ash_ui, "metadata"),
         :ok <- validate_nested_map(ash_ui, "binding_metadata") do
      screen = ash_ui["screen"]

      cond do
        not is_binary(screen["name"]) or screen["name"] == "" ->
          {:error, "ash_ui.screen.name must be a non-empty string"}

        not (is_nil(screen["route"]) or is_binary(screen["route"])) ->
          {:error, "ash_ui.screen.route must be nil or a string"}

        true ->
          :ok
      end
    end
  end

  defp validate_nested_map(map, key) do
    case fetch(map, key) do
      value when is_map(value) -> :ok
      _other -> {:error, "#{key} must be a map"}
    end
  end

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
    if Keyword.keyword?(value) do
      value
      |> Enum.map(fn {key, item} -> {encode_key(key), encode_value(item)} end)
      |> Enum.into(%{})
    else
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
        "screen" -> Map.get(map, :screen)
        "metadata" -> Map.get(map, :metadata)
        "binding_metadata" -> Map.get(map, :binding_metadata)
        "module" -> Map.get(map, :module)
        "package" -> Map.get(map, :package)
        "module_summary" -> Map.get(map, :module_summary)
        "composition_summary" -> Map.get(map, :composition_summary)
        "compiler_summary" -> Map.get(map, :compiler_summary)
        "compiler_listing" -> Map.get(map, :compiler_listing)
        "name" -> Map.get(map, :name)
        "route" -> Map.get(map, :route)
        _other -> nil
      end
  end
end
