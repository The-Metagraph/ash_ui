defmodule UnifiedUi.Export do
  @moduledoc """
  Review-friendly export helpers for maintained examples and authored modules.
  """

  alias UnifiedIUR.Reference, as: IURReference
  alias UnifiedUi.{Compiler, Examples, Info, Tooling}

  @type export_format ::
          :inspection | :snapshot | :signals | :summary | :diagnostics | :coverage

  @spec example(atom(), export_format()) :: {:ok, String.t()} | :error
  def example(id, format \\ :inspection) when is_atom(id) do
    with {:ok, example} <- Examples.example(id) do
      module(example.module, format)
    end
  end

  @spec module(module(), export_format()) :: {:ok, String.t()} | {:error, map()}
  def module(module, format \\ :inspection) when is_atom(module) do
    case format do
      :inspection ->
        {:ok, Compiler.render_inspection(module)}

      :snapshot ->
        {:ok, module |> Compiler.iur!() |> IURReference.snapshot() |> inspect_term()}

      :signals ->
        {:ok, module |> Info.inspect_module() |> Map.fetch!(:signal_catalog) |> inspect_term()}

      :summary ->
        {:ok, module |> Compiler.summary() |> inspect_term()}

      :diagnostics ->
        {:ok, module |> Tooling.module_diagnostics() |> Tooling.render_diagnostics()}

      :coverage ->
        {:ok, Tooling.coverage_summary()}
    end
  rescue
    error ->
      {:error,
       %{
         status: :error,
         module: module,
         error: error.__struct__,
         message: Exception.message(error)
       }}
  end

  @spec coverage() :: {:ok, String.t()}
  def coverage do
    {:ok, Tooling.coverage_summary()}
  end

  defp inspect_term(term) do
    inspect(term, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end
end
