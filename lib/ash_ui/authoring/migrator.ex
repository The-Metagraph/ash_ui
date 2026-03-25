defmodule AshUI.Authoring.Migrator do
  @moduledoc """
  Deterministic migration helpers for legacy builder-shaped `unified_dsl`.

  Phase 10 uses this module to rewrite repo-owned screens and example seeds from
  raw builder maps into the persisted authoring document contract while carrying
  a temporary legacy compiler snapshot in the compatibility payload.
  """

  alias AshUI.Authoring.Document
  alias AshUI.DSL.{Builder, Storage}

  @type migration_report :: %{
          status: :ok | :unsupported,
          source_format: String.t(),
          source_version: pos_integer(),
          root_type: String.t() | nil,
          widget_types: [String.t()],
          unsupported_types: [String.t()],
          construct_families: [String.t()],
          node_count: non_neg_integer(),
          signal_count: non_neg_integer()
        }

  @doc """
  Returns a dry-run report for a legacy builder DSL payload.
  """
  @spec dry_run(map(), keyword()) :: migration_report()
  def dry_run(dsl, _opts \\ []) when is_map(dsl) do
    normalized = Builder.from_store(dsl)
    widget_types = Storage.widget_types(normalized) |> Enum.uniq()
    unsupported_types = Enum.reject(widget_types, &Storage.valid_widget_type?/1)
    construct_families = normalized |> collect_construct_families() |> Enum.uniq() |> Enum.sort()

    %{
      status: if(unsupported_types == [], do: :ok, else: :unsupported),
      source_format: "ash_ui.dsl.builder",
      source_version: 1,
      root_type: node_type(normalized),
      widget_types: widget_types,
      unsupported_types: unsupported_types,
      construct_families: construct_families,
      node_count: count_nodes(normalized),
      signal_count: length(Storage.signal_references(normalized))
    }
  end

  @doc """
  Builds a Phase 10 persisted document from a legacy builder DSL payload.
  """
  @spec document(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def document(dsl, opts \\ []) when is_map(dsl) and is_list(opts) do
    normalized = Builder.from_store(dsl)
    report = dry_run(normalized, opts)

    with :ok <- validate_migration_target(report),
         {:ok, document} <-
           Document.migration_document(
             serialize_document(normalized, opts),
             Builder.to_store(normalized),
             report,
             opts
           ) do
      {:ok, document}
    end
  end

  @doc """
  Same as `document/2`, but raises on migration failure.
  """
  @spec document!(map(), keyword()) :: map()
  def document!(dsl, opts \\ []) when is_map(dsl) and is_list(opts) do
    case document(dsl, opts) do
      {:ok, document} ->
        document

      {:error, reason} ->
        raise ArgumentError, "legacy unified_dsl migration failed: #{inspect(reason)}"
    end
  end

  @doc """
  Builds `Screen` attributes for a migrated legacy DSL payload.
  """
  @spec screen_attrs(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def screen_attrs(dsl, opts \\ []) when is_map(dsl) and is_list(opts) do
    name = Keyword.fetch!(opts, :name)
    layout = Keyword.get(opts, :layout, :default)
    route = Keyword.get(opts, :route)
    metadata = Keyword.get(opts, :metadata, %{})

    with {:ok, unified_dsl} <- document(dsl, opts) do
      {:ok,
       %{
         name: name,
         route: route,
         layout: layout,
         metadata: metadata,
         unified_dsl: unified_dsl,
         active: Keyword.get(opts, :active, true),
         version: Keyword.get(opts, :version, 1)
       }}
    end
  end

  @doc """
  Same as `screen_attrs/2`, but raises on migration failure.
  """
  @spec screen_attrs!(map(), keyword()) :: map()
  def screen_attrs!(dsl, opts \\ []) when is_map(dsl) and is_list(opts) do
    case screen_attrs(dsl, opts) do
      {:ok, attrs} ->
        attrs

      {:error, reason} ->
        raise ArgumentError, "legacy screen attr migration failed: #{inspect(reason)}"
    end
  end

  defp validate_migration_target(%{status: :ok}), do: :ok

  defp validate_migration_target(report) do
    {:error, {:unsupported_legacy_dsl, report}}
  end

  defp serialize_document(dsl, opts) do
    screen_name = Keyword.fetch!(opts, :name)
    metadata = Keyword.get(opts, :metadata, %{})

    %{
      "identity" => %{
        "id" => screen_name,
        "title" => Map.get(metadata, "title") || Map.get(metadata, :title),
        "description" => Map.get(metadata, "description") || Map.get(metadata, :description),
        "authored_ref" => ["ash_ui", "migration", screen_name]
      },
      "composition" => %{
        "mode" => "screen",
        "root" => serialize_node(dsl, [0]),
        "summary" => "Migrated from AshUI.DSL.Builder",
        "construct_families" => collect_construct_families(dsl)
      }
    }
  end

  defp serialize_node(dsl, path) do
    %{
      "id" => node_identifier(dsl, path),
      "family" => node_family(dsl),
      "kind" => node_type(dsl),
      "props" => node_props(dsl),
      "signals" => node_signals(dsl),
      "metadata" => node_metadata(dsl),
      "children" =>
        dsl
        |> node_children()
        |> Enum.with_index()
        |> Enum.map(fn {child, index} -> serialize_node(child, path ++ [index]) end)
    }
  end

  defp node_identifier(dsl, path) do
    metadata = node_metadata(dsl)

    Map.get(metadata, "id") ||
      ["legacy", node_type(dsl) || "node" | Enum.map(path, &Integer.to_string/1)]
      |> Enum.join("_")
  end

  defp node_type(dsl) do
    Map.get(dsl, :type) || Map.get(dsl, "type")
  end

  defp node_props(dsl) do
    Map.get(dsl, :props) || Map.get(dsl, "props") || %{}
  end

  defp node_signals(dsl) do
    Map.get(dsl, :signals) || Map.get(dsl, "signals") || []
  end

  defp node_metadata(dsl) do
    Map.get(dsl, :metadata) || Map.get(dsl, "metadata") || %{}
  end

  defp node_children(dsl) do
    Map.get(dsl, :children) || Map.get(dsl, "children") || []
  end

  defp count_nodes(dsl) do
    1 + Enum.reduce(node_children(dsl), 0, fn child, acc -> acc + count_nodes(child) end)
  end

  defp collect_construct_families(dsl) do
    [node_family(dsl) | Enum.flat_map(node_children(dsl), &collect_construct_families/1)]
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp node_family(dsl) do
    type = node_type(dsl)

    cond do
      type in ["screen", "row", "column", "grid", "stack", "fragment", "container"] ->
        "layout"

      type in ["text", "button", "image", "icon", "divider", "spacer", "card"] ->
        "foundational"

      type in ["input", "textarea", "checkbox", "radio", "switch", "slider", "select"] ->
        "input"

      type in ["list", "table"] ->
        "data"

      is_binary(type) and String.starts_with?(type, "custom:") ->
        "advanced"

      true ->
        "unknown"
    end
  end
end
