defmodule AshUI.Resource.ContextSelectorTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  describe "context_selector authoring admission" do
    test "admits context_selector as a canonical baseline widget type" do
      assert Storage.valid_widget_type?("context_selector")
      assert Storage.canonical_widget_type(:context_selector) == {:ok, "context_selector"}

      definition = %{
        type: :context_selector,
        props: %{selector_id: "workspace-context", groups: []}
      }

      assert Authoring.validate_element_definition!(definition) == definition
    end

    test "allows list bindings and semantic change actions" do
      definition = %{type: :context_selector, props: %{selector_id: "workspace-context"}}

      binding = %{
        id: :selected_contexts,
        binding_type: :list,
        source: %{resource: "Demo.Context", action: "list"},
        target: "selected_contexts"
      }

      action = %{
        id: :select_context,
        signal: :change,
        source: %{resource: "Demo.Context", action: "select"},
        target: "selected_contexts"
      }

      assert :ok = Authoring.validate_element_authority!(definition, [binding], [action])
    end

    test "rejects unsupported submit actions" do
      definition = %{type: :context_selector, props: %{selector_id: "workspace-context"}}

      assert_raise ArgumentError, ~r/supported signals/, fn ->
        Authoring.validate_element_authority!(
          definition,
          [],
          [%{id: :submit_context, signal: :submit, source: "context", target: "selected"}]
        )
      end
    end
  end
end
