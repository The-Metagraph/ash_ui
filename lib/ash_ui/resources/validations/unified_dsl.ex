defmodule AshUI.Resources.Validations.UnifiedDSL do
  @moduledoc """
  Validates persisted `unified_dsl` payloads before they are stored on screens.

  Phase 13 accepts resource-authority payloads as the preferred format while
  still tolerating the superseded Phase 10 authored-screen document during the
  cutover period.
  """

  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidAttribute
  alias Ash.Subject
  alias AshUI.Authoring.Document
  alias AshUI.Resource.Authority

  @doc false
  @impl true
  def supports(_opts), do: [Ash.Changeset, Ash.ActionInput]

  @doc false
  @impl true
  def validate(subject, _opts, _context) do
    dsl = Subject.get_attribute(subject, :unified_dsl)

    with :ok <- validate_map(dsl) do
      cond do
        Authority.authority_payload?(dsl) ->
          case Authority.validate_payload(dsl) do
            :ok -> :ok
            {:error, message} -> invalid_dsl(dsl, message)
          end

        Document.authoring_document?(dsl) ->
          case Document.validate_write(dsl) do
            :ok -> :ok
            {:error, message} -> invalid_dsl(dsl, message)
          end

        true ->
          invalid_dsl(
            dsl,
            "must declare the ash_ui resource_authority format or the superseded Phase 10 authored document format"
          )
      end
    end
  end

  defp validate_map(dsl) when is_map(dsl), do: :ok

  defp validate_map(dsl) do
    invalid_dsl(dsl, "must be a map")
  end

  defp invalid_dsl(value, message) do
    {:error, InvalidAttribute.exception(field: :unified_dsl, value: value, message: message)}
  end
end
