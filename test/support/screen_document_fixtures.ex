defmodule AshUI.Test.ScreenDocumentFixtures do
  @moduledoc false

  alias AshUI.Authoring.Migrator
  alias AshUI.DSL.Builder

  def resource_screen_attrs(name, opts \\ []) do
    layout = Keyword.get(opts, :layout, :row)
    route = Keyword.get(opts, :route)
    metadata = Keyword.get(opts, :metadata, %{})

    Migrator.screen_attrs!(
      Builder.screen() |> Builder.to_store(),
      name: name,
      layout: layout,
      route: route,
      metadata: metadata
    )
  end

  def migrated_screen_attrs(name, dsl, opts \\ []) do
    layout = Keyword.get(opts, :layout, :row)
    route = Keyword.get(opts, :route)
    metadata = Keyword.get(opts, :metadata, %{})

    Migrator.screen_attrs!(
      Builder.to_store(dsl),
      name: name,
      layout: layout,
      route: route,
      metadata: metadata
    )
  end

  def resource_screen_document(name, opts \\ []) do
    resource_screen_attrs(name, opts).unified_dsl
  end

  def migrated_screen_document(name, dsl, opts \\ []) do
    migrated_screen_attrs(name, dsl, opts).unified_dsl
  end
end
