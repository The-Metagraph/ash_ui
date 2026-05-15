defmodule AshUI.Phase31ResourceAdmissionTest do
  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Resources.Validations.Authoring

  @moduletag :conformance

  describe "Section 31.2 - resource and persisted DSL admission" do
    test "resource element validation admits every canonical widget component" do
      for kind <- AshUI.WidgetComponents.kinds() do
        definition = %{
          type: kind,
          props: %{},
          variants: [],
          metadata: %{}
        }

        assert Authoring.validate_element_definition!(definition) == definition
      end
    end

    test "persisted DSL validation admits every canonical widget component" do
      for kind <- AshUI.WidgetComponents.kinds() do
        dsl = %{
          type: Atom.to_string(kind),
          props: %{},
          children: [],
          signals: [],
          metadata: %{}
        }

        assert Storage.validate_write(dsl) == :ok
      end
    end

    test "compatibility aliases are accepted and normalize to canonical component names" do
      assert Storage.canonical_widget_type(:phoenix_form) == {:ok, "runtime_form_shell"}
      assert Storage.canonical_widget_type("repeat") == {:ok, "list_repeat"}
      assert Storage.canonical_widget_type(:ui_relationship_repeat) == {:ok, "list_repeat"}

      for {alias_name, canonical_kind} <- AshUI.WidgetComponents.aliases() do
        definition = %{type: alias_name, props: %{}, variants: [], metadata: %{}}

        assert Authoring.validate_element_definition!(definition) == definition
        assert Storage.valid_widget_type?(Atom.to_string(alias_name))
        assert Storage.canonical_widget_type(alias_name) == {:ok, Atom.to_string(canonical_kind)}
      end
    end

    test "invalid component names still fail resource and persisted DSL validation" do
      assert_raise ArgumentError, ~r/ui_element type must be a known widget type/, fn ->
        Authoring.validate_element_definition!(%{
          type: :not_in_catalog,
          props: %{},
          variants: [],
          metadata: %{}
        })
      end

      dsl = %{type: "not_in_catalog", props: %{}, children: [], signals: [], metadata: %{}}

      assert {:error, errors} = Storage.validate_write(dsl)
      assert Enum.any?(errors, &String.contains?(&1, "Invalid widget types"))
    end

    test "existing widgets, layouts, and custom extension names remain valid" do
      assert Storage.canonical_widget_type("row") == {:ok, "row"}
      assert Storage.canonical_widget_type("button") == {:ok, "button"}

      assert Storage.canonical_widget_type("custom:domain_specific") ==
               {:ok, "custom:domain_specific"}
    end
  end
end
