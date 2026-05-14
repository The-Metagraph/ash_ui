defmodule ElmUi.Export do
  @moduledoc """
  Review-friendly export helpers for `elm_ui` example workflows.
  """

  @spec artifact(atom() | String.t()) :: {:ok, map()} | {:error, :unknown_example}
  def artifact(id) do
    with {:ok, preview} <- ElmUi.Inspect.preview(id) do
      {:ok,
       %{
         id: preview.id,
         artifact_names: preview.metadata.artifact_names,
         metadata: preview.metadata,
         payload: preview.surface
       }}
    end
  end

  @spec catalog() :: [map()]
  def catalog do
    ElmUi.Examples.catalog()
    |> Enum.map(fn metadata ->
      %{
        id: metadata.id,
        artifact_names: metadata.artifact_names,
        category: metadata.category,
        workflow: metadata.workflow
      }
    end)
  end

  @spec example(atom() | String.t(), atom()) :: {:ok, String.t()} | {:error, :unknown_example}
  def example(id, format \\ :report) do
    with {:ok, artifact} <- artifact(id) do
      {:ok, format_artifact(artifact, format)}
    end
  end

  defp format_artifact(artifact, :report) do
    Kernel.inspect(artifact, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_artifact(artifact, :metadata) do
    payload = %{
      id: artifact.id,
      artifact_names: artifact.artifact_names,
      metadata: artifact.metadata
    }

    Kernel.inspect(payload, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_artifact(artifact, :comparison) do
    payload =
      case artifact.metadata.category do
        :mixed ->
          %{
            id: artifact.id,
            artifact_names: artifact.artifact_names,
            metadata: artifact.metadata,
            payload: artifact.payload
          }

        _other ->
          %{
            id: artifact.id,
            artifact_names: artifact.artifact_names,
            metadata: artifact.metadata,
            review_artifact: artifact.payload
          }
      end

    Kernel.inspect(payload, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_artifact(artifact, :diagnostics) do
    payload = %{
      id: artifact.id,
      category: artifact.metadata.category,
      workflow: artifact.metadata.workflow,
      artifact_names: artifact.artifact_names,
      traceability: artifact.metadata.traceability,
      payload_summary: payload_summary(artifact)
    }

    Kernel.inspect(payload, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp payload_summary(%{metadata: %{category: :mixed}, payload: payload}) do
    %{
      continuity: Map.get(payload, :continuity, %{}),
      review_artifact: Map.get(payload, :review_artifact, %{})
    }
  end

  defp payload_summary(%{payload: payload}) do
    %{
      runtime: Map.get(payload, :runtime, %{}),
      server: Map.get(payload, :server, %{}),
      frontend: Map.get(payload, :frontend, %{})
    }
  end
end
