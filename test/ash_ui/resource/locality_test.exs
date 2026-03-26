defmodule AshUI.Resource.LocalityTest do
  use ExUnit.Case, async: true

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
