defmodule Mix.Tasks.UnifiedIur.Inspect do
  use Mix.Task

  @shortdoc "Prints maintainer-facing inspection output for a canonical UnifiedIUR fixture"

  @moduledoc """
  Prints inspection output for a canonical `UnifiedIUR` fixture.

      mix unified_iur.inspect forms--profile_editor
      mix unified_iur.inspect forms--profile_editor --format tree
      mix unified_iur.inspect forms--profile_editor --format diagnostics
      mix unified_iur.inspect forms--profile_editor --format extensions
  """

  alias UnifiedIUR.{Export, Inspect}

  @impl Mix.Task
  def run(args) do
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case {format, positional} do
      {"extensions", _} ->
        Inspect.extension_metadata()
        |> Kernel.inspect(pretty: true, width: 100, limit: :infinity, sort_maps: true)
        |> Mix.shell().info()

      {_format, [fixture_id]} ->
        output =
          case format do
            "report" ->
              case Inspect.fixture(fixture_id) do
                {:ok, report} ->
                  Kernel.inspect(report,
                    pretty: true,
                    width: 100,
                    limit: :infinity,
                    sort_maps: true
                  )

                :error ->
                  Mix.raise("unknown fixture #{inspect(fixture_id)}")
              end

            "tree" ->
              case Export.fixture(fixture_id, :tree) do
                {:ok, tree} -> tree
                :error -> Mix.raise("unknown fixture #{inspect(fixture_id)}")
              end

            "diagnostics" ->
              case Export.fixture(fixture_id, :diagnostics) do
                {:ok, diagnostics} -> diagnostics
                :error -> Mix.raise("unknown fixture #{inspect(fixture_id)}")
              end

            other ->
              Mix.raise("unsupported inspect format #{inspect(other)}")
          end

        Mix.shell().info(output)

      _ ->
        Mix.raise(
          "usage: mix unified_iur.inspect FIXTURE_ID [--format report|tree|diagnostics|extensions]"
        )
    end
  end
end
