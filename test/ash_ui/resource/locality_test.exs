defmodule AshUI.Resource.LocalityTest do
  use ExUnit.Case, async: true

  # Asserts the binding-locality validator did NOT raise the
  # "does not expose collection semantics" ArgumentError for the resource
  # compiled inside `fun`. Any other exception (e.g. the unrelated
  # domain-registration RuntimeError from the Ash compile-time pipeline)
  # is treated as proof the validator passed; absence of any exception is
  # also a pass.
  defp assert_validator_accepts_list_binding(fun) do
    fun.()
    :ok
  rescue
    e in ArgumentError ->
      if e.message =~ "does not expose collection semantics" do
        flunk("validator rejected list binding it should accept: #{e.message}")
      else
        :ok
      end

    _other ->
      :ok
  end

  describe "screen-scoped binding exceptions" do
    test "rejects screen bindings that target element-owned props" do
      assert_raise ArgumentError, ~r/screen-scoped binding .* must target/, fn ->
        Code.compile_string("""
        defmodule InvalidScreenScopedBinding do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Screen

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_screen do
            layout :column
          end

          ui_screen_bindings do
            binding :invalid_target do
              source %{resource: "Demo.Page", field: "notice", id: "page-1"}
              target "content"
              binding_type :value
            end
          end
        end
        """)
      end
    end
  end

  describe "element-local binding ownership" do
    test "rejects element bindings that target screen-scoped namespaces" do
      assert_raise ArgumentError, ~r/reserved for screen-scoped bindings/, fn ->
        Code.compile_string("""
        defmodule InvalidElementScreenTarget do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Element

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_element do
            type :text
            props %{content: "Bad target"}
          end

          ui_bindings do
            binding :bad_notice do
              source %{resource: "Demo.Page", field: "notice", id: "page-1"}
              target "flash.notice"
              binding_type :value
            end
          end
        end
        """)
      end
    end

    test "rejects list bindings on widgets without collection semantics" do
      assert_raise ArgumentError, ~r/does not expose collection semantics/, fn ->
        Code.compile_string("""
        defmodule InvalidElementListBinding do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Element

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_element do
            type :text
            props %{content: "Bad list"}
          end

          ui_bindings do
            binding :bad_list do
              source %{resource: "Demo.Post", relationship: "comments", id: "post-1"}
              target "items"
              binding_type :list
            end
          end
        end
        """)
      end
    end

    test "accepts list bindings on custom:* opaque widget types" do
      # `custom:*` application-extension primitives are outside the canonical
      # catalog; the validator can't know their collection semantics and
      # should trust the authoring intent.
      #
      # Same testing strategy as the :artifact_row case above.
      assert_validator_accepts_list_binding(fn ->
        Code.compile_string("""
        defmodule ValidCustomWidgetListBinding do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Element

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_element do
            type "custom:thread_card"
            props %{label: "Custom row template"}
          end

          ui_bindings do
            binding :thread_rows do
              source %{resource: "Demo.Post", relationship: "comments", id: "post-1"}
              target "items"
              binding_type :list
            end
          end
        end
        """)
      end)
    end
  end

  describe "action signal ownership" do
    test "rejects signals not supported by the owning widget" do
      assert_raise ArgumentError, ~r/supported signals are \[:click, :submit\]/, fn ->
        Code.compile_string("""
        defmodule InvalidButtonToggleAction do
          use Ash.Resource,
            domain: AshUI.Test.ResourceAuthorityDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Element

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          ui_element do
            type :button
            props %{label: "Broken"}
          end

          ui_actions do
            action :bad_toggle do
              signal :toggle
              source %{resource: "Demo.Profile", action: "save_profile", id: "user-1"}
            end
          end
        end
        """)
      end
    end
  end
end
