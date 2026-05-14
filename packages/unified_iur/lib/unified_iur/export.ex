defmodule UnifiedIUR.Export do
  @moduledoc """
  Stable export helpers for canonical fixtures, snapshots, and diff reports.
  """

  alias UnifiedIUR.{Fixtures, Inspect, Interaction, Normalize, Reference, Validate}

  @type export_format :: :fixture | :snapshot | :diagnostics | :tree
  @type navigation_export_format :: :fixture | :snapshot | :inspection

  @spec fixture(String.t(), export_format()) :: {:ok, String.t()} | :error
  def fixture(id, format \\ :fixture) when is_binary(id) do
    case Fixtures.fixture(id) do
      {:ok, fixture} ->
        output =
          case format do
            :fixture ->
              serialize_term(
                id: fixture.id,
                category: fixture.category,
                description: fixture.description,
                semantics: fixture.semantics,
                parity_obligations: fixture.parity_obligations,
                snapshot_path: fixture.snapshot_path,
                snapshot: Reference.snapshot(fixture.element)
              )

            :snapshot ->
              snapshot(fixture.element)

            :diagnostics ->
              diagnostics(fixture.element)

            :tree ->
              Inspect.render_tree(fixture.element)
          end

        {:ok, output}

      :error ->
        :error
    end
  end

  @spec navigation_fixture(String.t(), navigation_export_format()) :: {:ok, String.t()} | :error
  def navigation_fixture(id, format \\ :fixture) when is_binary(id) do
    case Fixtures.navigation_fixture(id) do
      {:ok, fixture} ->
        output =
          case format do
            :fixture ->
              serialize_term(
                id: fixture.id,
                description: fixture.description,
                semantics: fixture.semantics,
                snapshot_path: fixture.snapshot_path,
                snapshot: Reference.snapshot_interaction(fixture.interaction)
              )

            :snapshot ->
              snapshot_interaction(fixture.interaction)

            :inspection ->
              fixture.interaction
              |> Inspect.interaction()
              |> serialize_term()
          end

        {:ok, output}

      :error ->
        :error
    end
  end

  @spec snapshot(UnifiedIUR.Element.t() | map() | keyword()) :: String.t()
  def snapshot(input) do
    input
    |> Reference.snapshot()
    |> serialize_term()
  end

  @spec snapshot_interaction(Interaction.t() | map() | keyword()) :: String.t()
  def snapshot_interaction(input) do
    input
    |> Reference.snapshot_interaction()
    |> serialize_term()
  end

  @spec diagnostics(UnifiedIUR.Element.t() | map() | keyword()) :: String.t()
  def diagnostics(input) do
    input
    |> Validate.diagnostics()
    |> serialize_term()
  end

  @spec diff(
          UnifiedIUR.Element.t() | map() | keyword(),
          UnifiedIUR.Element.t() | map() | keyword()
        ) ::
          %{equivalent?: boolean(), changes: [map()], text: String.t()}
  def diff(left, right) do
    left = Normalize.element!(left)
    right = Normalize.element!(right)
    changes = Reference.shape_diff(left, right)

    %{
      equivalent?: changes == [],
      changes: changes,
      text: format_changes(changes)
    }
  end

  defp format_changes([]), do: "No canonical shape changes detected."

  defp format_changes(changes) do
    Enum.map_join(changes, "\n", fn change ->
      path =
        change.path
        |> Enum.map_join(".", &to_string/1)

      "#{path}: #{Kernel.inspect(change.left)} -> #{Kernel.inspect(change.right)}"
    end)
  end

  defp serialize_term(term) do
    Kernel.inspect(term, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end
end
