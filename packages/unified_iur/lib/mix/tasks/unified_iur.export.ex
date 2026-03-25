defmodule Mix.Tasks.UnifiedIur.Export do
  use Mix.Task

  @shortdoc "Prints a stable exported representation of a canonical UnifiedIUR fixture"

  @moduledoc """
  Prints a stable exported representation of a canonical `UnifiedIUR` fixture.

      mix unified_iur.export forms--profile_editor
      mix unified_iur.export forms--profile_editor --format snapshot
      mix unified_iur.export forms--profile_editor --format diagnostics
  """

  alias UnifiedIUR.Export

  @impl Mix.Task
  def run(args) do
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "fixture")

    case positional do
      [fixture_id] ->
        export_format =
          case format do
            "fixture" -> :fixture
            "snapshot" -> :snapshot
            "diagnostics" -> :diagnostics
            other -> Mix.raise("unsupported export format #{inspect(other)}")
          end

        case Export.fixture(fixture_id, export_format) do
          {:ok, output} -> Mix.shell().info(output)
          :error -> Mix.raise("unknown fixture #{inspect(fixture_id)}")
        end

      _ ->
        Mix.raise(
          "usage: mix unified_iur.export FIXTURE_ID [--format fixture|snapshot|diagnostics]"
        )
    end
  end
end
