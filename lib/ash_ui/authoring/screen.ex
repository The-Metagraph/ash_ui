defmodule AshUI.Authoring.Screen do
  @moduledoc """
  Persistence helpers for screens authored through upstream `UnifiedUi.Dsl`.

  This module is the Ash UI boundary that application code should use when it
  wants to persist a screen defined in the authoritative upstream DSL while
  still attaching Ash UI-specific route and binding metadata.
  """

  alias AshUI.Authoring.Document
  alias AshUI.Config
  alias AshUI.Data

  @authoring_keys [
    :name,
    :route,
    :layout,
    :metadata,
    :binding_metadata,
    :ui_storage,
    :active,
    :version
  ]

  @doc """
  Builds persisted `Screen` attributes from a `UnifiedUi.Dsl` module.
  """
  @spec screen_attrs(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def screen_attrs(module, opts \\ []) when is_atom(module) and is_list(opts) do
    with {:ok, document} <- Document.new(module, opts) do
      module_summary = UnifiedUi.Info.module_summary(module)
      identity = Map.get(module_summary, :identity, %{})
      screen_name = Keyword.get(opts, :name, default_name(identity, module))
      screen_metadata = build_metadata(identity, Keyword.get(opts, :metadata, %{}))

      {:ok,
       %{
         name: screen_name,
         route: Keyword.get(opts, :route),
         layout: Keyword.get(opts, :layout, :default),
         metadata: screen_metadata,
         unified_dsl: document,
         active: Keyword.get(opts, :active, true),
         version: Keyword.get(opts, :version, 1)
       }}
    end
  end

  @doc """
  Persists a `Screen` resource from a `UnifiedUi.Dsl` module.
  """
  @spec create(module(), keyword()) :: {:ok, struct()} | {:error, term()}
  def create(module, opts \\ []) when is_atom(module) and is_list(opts) do
    ui_storage = Keyword.get(opts, :ui_storage)
    screen_resource = Config.screen_resource(ui_storage)

    with {:ok, attrs} <- screen_attrs(module, opts) do
      screen_resource
      |> Data.create(Keyword.put(persistence_opts(opts), :attrs, attrs))
    end
  end

  defp build_metadata(identity, metadata) do
    title = Map.get(identity, :title)
    description = Map.get(identity, :description)

    metadata
    |> Map.new()
    |> maybe_put("title", title)
    |> maybe_put("description", description)
    |> maybe_put("authored_ref", Map.get(identity, :authored_ref))
    |> maybe_put("tags", Map.get(identity, :tags))
  end

  defp default_name(identity, module) do
    case Map.get(identity, :id) do
      value when is_atom(value) -> Atom.to_string(value)
      value when is_binary(value) -> value
      nil -> module |> Module.split() |> List.last() |> Macro.underscore()
    end
  end

  defp persistence_opts(opts) do
    opts
    |> Keyword.drop(@authoring_keys -- [:ui_storage])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
