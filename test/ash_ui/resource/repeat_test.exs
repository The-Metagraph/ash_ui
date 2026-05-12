defmodule AshUI.Resource.RepeatTest do
  @moduledoc """
  Covers the `ui_relationship ... repeat <binding_id>` DSL primitive that
  composes per-row child instances at hydration time.

  Layered scope:

    * DSL admission — `Info.composition_edges/1` exposes the `:repeat`
      semantic on the composition edge.
    * Authority payload — `Authority.payload/2` carries the repeat field in
      `composition.roots[].relationship.repeat`.
    * Validator — repeat must reference a `:list`-typed binding on the parent
      module (screen or owning element).
    * Cardinality — repeat requires a `has_many` Ash relationship, not
      `has_one`.
  """
  use ExUnit.Case, async: true

  alias AshUI.Resource.Authority
  alias AshUI.Resource.Info
  alias AshUI.Test.RepeatRowElement
  alias AshUI.Test.RepeatScreen

  describe "Info.composition_edges/1 with a repeat-bearing relationship" do
    test "exposes the repeat directive on the edge" do
      assert {:ok, [edge]} = Info.composition_edges(RepeatScreen)
      assert edge.name == :manuscript_blocks
      assert edge.destination == RepeatRowElement
      assert edge.type == :has_many
      assert edge.kind == :child
      assert edge.slot == :body
      assert edge.repeat == :manuscript_block_rows
    end
  end

  describe "Authority.payload/2 with a repeat-bearing relationship" do
    test "encodes the repeat field on the composition node's relationship" do
      assert {:ok, payload} = Authority.payload(RepeatScreen, name: "repeat_screen")

      assert [root] = payload["composition"]["roots"]
      assert root["module"] == "Elixir.AshUI.Test.RepeatRowElement"
      assert root["relationship"]["repeat"] == "manuscript_block_rows"
      assert root["relationship"]["type"] == "has_many"
    end

    test "non-repeat relationships carry repeat as nil" do
      alias AshUI.Test.ResourceAuthorityScreen

      assert {:ok, payload} =
               Authority.payload(ResourceAuthorityScreen, name: "non_repeat_screen")

      Enum.each(payload["composition"]["roots"], fn root ->
        assert Map.has_key?(root["relationship"], "repeat")
        assert is_nil(root["relationship"]["repeat"])
      end)
    end
  end

  describe "validator — repeat must reference a list binding on the parent module" do
    test "rejects a repeat that points at an unknown binding id at payload time" do
      assert {:error, {:unknown_repeat_binding, encoded_module, :rows, :nonexistent_binding}} =
               Authority.payload(AshUI.Test.RepeatMissingBindingScreen, name: "missing_binding")

      assert encoded_module == "Elixir.AshUI.Test.RepeatMissingBindingScreen"
    end

    test "rejects a repeat that points at a non-list binding at payload time" do
      assert {:error,
              {:invalid_repeat_binding_type, _module, :rows, :a_value_binding, binding_type}} =
               Authority.payload(AshUI.Test.RepeatNonListBindingScreen, name: "non_list")

      assert binding_type in [:value, "value"]
    end

    test "rejects repeat values that are not strings or atoms" do
      assert_raise ArgumentError, ~r/repeat must be a non-empty string or atom/, fn ->
        AshUI.Resources.Validations.Authoring.validate_relationship_definition!(%{
          name: :bad,
          kind: :child,
          slot: :body,
          placement: :append,
          order: 0,
          repeat: 42
        })
      end
    end

    test "accepts string repeat identifiers" do
      assert %{repeat: "rows_binding"} =
               AshUI.Resources.Validations.Authoring.validate_relationship_definition!(%{
                 name: :good,
                 kind: :child,
                 slot: :body,
                 placement: :append,
                 order: 0,
                 repeat: "rows_binding"
               })
    end

    test "accepts a missing repeat field (it is optional)" do
      assert %{} =
               AshUI.Resources.Validations.Authoring.validate_relationship_definition!(%{
                 name: :good,
                 kind: :child,
                 slot: :body,
                 placement: :append,
                 order: 0
               })
    end
  end

  describe "BindingSource — row-scoped sources" do
    alias AshUI.Resources.Validations.BindingSource

    test "accepts %{scope: :row, field: \"...\"} for :value bindings" do
      assert :ok = BindingSource.validate_source(%{scope: :row, field: "title"}, :value)
    end

    test "rejects row-scoped sources for :list bindings" do
      assert {:error, "row-scoped bindings are only valid for :value bindings"} =
               BindingSource.validate_source(%{scope: :row, field: "title"}, :list)
    end

    test "rejects row-scoped sources without a field" do
      assert {:error, "row-scoped bindings must include a non-empty field"} =
               BindingSource.validate_source(%{scope: :row}, :value)
    end

    test "still accepts the legacy resource-anchored shape" do
      assert :ok =
               BindingSource.validate_source(
                 %{resource: "Demo.User", field: "name", id: "user-1"},
                 :value
               )
    end
  end
end
