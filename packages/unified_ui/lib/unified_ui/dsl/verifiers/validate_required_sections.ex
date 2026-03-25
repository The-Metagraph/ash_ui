defmodule UnifiedUi.Dsl.Verifiers.ValidateRequiredSections do
  @moduledoc false

  use Spark.Dsl.Verifier

  alias UnifiedUi.Dsl.Identity

  @spec verify(map()) :: :ok | {:error, Spark.Error.DslError.t()}
  def verify(dsl) do
    module = Spark.Dsl.Verifier.get_persisted(dsl, :module)

    missing_section =
      Identity.required_sections()
      |> Enum.find(fn section ->
        key = Map.fetch!(Identity.identifier_fields(), section)
        is_nil(Spark.Dsl.Verifier.get_option(dsl, [section], key, nil))
      end)

    case missing_section do
      nil ->
        :ok

      section ->
        {:error,
         %Spark.Error.DslError{
           module: module,
           path: [section],
           message:
             "#{section} section is required for authored UnifiedUi modules during the Phase 1 DSL backbone"
         }}
    end
  end
end
