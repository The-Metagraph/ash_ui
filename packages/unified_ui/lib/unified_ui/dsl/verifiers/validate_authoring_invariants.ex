defmodule UnifiedUi.Dsl.Verifiers.ValidateAuthoringInvariants do
  @moduledoc false

  use Spark.Dsl.Verifier

  alias UnifiedUi.Dsl.{Identity, Placement}

  @spec verify(map()) :: :ok | {:error, Spark.Error.DslError.t()}
  def verify(dsl) do
    module = Spark.Dsl.Verifier.get_persisted(dsl, :module)
    identity_id = Spark.Dsl.Verifier.get_option(dsl, [:identity], :id, nil)
    root = Spark.Dsl.Verifier.get_option(dsl, [:composition], :root, nil)
    authored_ref = Spark.Dsl.Verifier.get_option(dsl, [:identity], :authored_ref, [])
    mode = Spark.Dsl.Verifier.get_option(dsl, [:composition], :mode, :screen)
    default_slot = Spark.Dsl.Verifier.get_option(dsl, [:composition], :default_slot, nil)

    cond do
      identity_id in Identity.reserved_ids() ->
        dsl_error(
          module,
          [:identity],
          "identity.id #{inspect(identity_id)} is reserved for DSL structure and cannot be used as a module identifier"
        )

      identity_id == root and not is_nil(identity_id) ->
        dsl_error(
          module,
          [:composition],
          "composition.root must differ from identity.id so module identity and root node identity remain distinct"
        )

      authored_ref != [] and List.last(authored_ref) != identity_id ->
        dsl_error(
          module,
          [:identity],
          "identity.authored_ref must end with identity.id so authored traceability remains stable"
        )

      not Placement.valid_default_slot?(mode, default_slot) ->
        dsl_error(
          module,
          [:composition],
          "composition.default_slot may only be declared when composition.mode is :fragment"
        )

      true ->
        :ok
    end
  end

  defp dsl_error(module, path, message) do
    {:error, %Spark.Error.DslError{module: module, path: path, message: message}}
  end
end
