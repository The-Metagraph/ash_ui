defmodule AshUI.DSLIntegrationTest do
  use AshUI.DataCase, async: false

  defmodule ScreenDSLFixture do
    use AshUI.DSL.Screen

    def attrs do
      ui_screen do
        layout :row
        route "/dsl-screen"
        metadata %{title: "DSL Screen", priority: 1}
      end
      |> AshUI.DSL.Screen.to_attributes()
    end
  end

  defmodule ElementDSLFixture do
    use AshUI.DSL.Element

    def attrs do
      ui_element do
        type :button
        props %{label: "Save"}
        variants [:primary, :large]
      end
      |> AshUI.DSL.Element.to_attributes()
    end
  end

  defmodule BindingDSLFixture do
    use AshUI.DSL.Binding

    def attrs do
      ui_binding do
        source %{resource: "User", field: "name"}
        target "value"
        binding_type :value
        transform %{default: "Anonymous"}
      end
      |> AshUI.DSL.Binding.to_attributes()
    end
  end

  defmodule CompatScreenDSLFixture do
    use AshUI.Resource.DSL.Screen

    def attrs do
      ui_screen do
        layout :grid
        route "/compat-screen"
      end
      |> AshUI.Resource.DSL.Screen.to_attributes()
    end
  end

  defmodule CompatElementDSLFixture do
    use AshUI.Resource.DSL.Element

    def attrs do
      ui_element do
        type :text
        props %{label: "Compat"}
      end
      |> AshUI.Resource.DSL.Element.to_attributes()
    end
  end

  defmodule CompatBindingDSLFixture do
    use AshUI.Resource.DSL.Binding

    def attrs do
      ui_binding do
        source %{resource: "User", field: "email"}
        target "value"
        binding_type :value
      end
      |> AshUI.Resource.DSL.Binding.to_attributes()
    end
  end

  alias AshUI.Resources.Screen
  alias AshUI.Resources.Element
  alias AshUI.Resources.Binding
  alias AshUI.Test.ScreenDocumentFixtures

  describe "ui_screen DSL extension" do
    test "builds validated attributes at compile time" do
      attrs = ScreenDSLFixture.attrs()

      assert attrs.layout == :row
      assert attrs.route == "/dsl-screen"
      assert attrs.metadata == %{title: "DSL Screen", priority: 1}
    end

    test "creates valid resource attributes" do
      # Screen resource should be properly configured
      attrs = %{
        name: "dsl_screen_test"
      }

      assert {:ok, screen} =
               AshUI.Data.create(Screen,
                 attrs:
                   ScreenDocumentFixtures.resource_screen_attrs(attrs.name,
                     layout: :row,
                     route: "/dsl-test"
                   )
               )
      assert screen.layout == :row
      assert screen.route == "/dsl-test"
      assert is_map(screen.unified_dsl)
    end

    test "stores DSL options in resource attributes" do
      attrs = %{
        name: "dsl_metadata_test",
        metadata: %{"custom" => "value", "priority" => 1}
      }

      assert {:ok, screen} =
               AshUI.Data.create(Screen,
                 attrs:
                   ScreenDocumentFixtures.resource_screen_attrs(attrs.name,
                     metadata: attrs.metadata
                   )
               )
      assert screen.metadata == %{"custom" => "value", "priority" => 1}
    end

    test "invalid screen DSL fails at compile time" do
      assert_raise ArgumentError, ~r/ui_screen layout must be one of/, fn ->
        Code.compile_string("""
        defmodule InvalidScreenDSLFixture do
          use AshUI.DSL.Screen

          def attrs do
            ui_screen do
              layout :unknown_layout
            end
          end
        end
        """)
      end
    end

    test "compatibility namespace exposes screen DSL helpers" do
      assert CompatScreenDSLFixture.attrs() == %{layout: :grid, route: "/compat-screen"}
    end
  end

  describe "ui_element DSL extension" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.resource_screen_attrs("element_dsl_test", layout: :row)
        )

      %{screen: screen}
    end

    test "builds validated element attributes at compile time" do
      attrs = ElementDSLFixture.attrs()

      assert attrs.type == :button
      assert attrs.props == %{label: "Save"}
      assert attrs.variants == [:primary, :large]
    end

    test "creates valid element with type validation", %{screen: screen} do
      # Valid widget types from unified-ui spec
      valid_types = [
        :text,
        :button,
        :textinput,
        :textarea,
        :select,
        :checkbox,
        :radio,
        :switch,
        :slider,
        :row,
        :column,
        :grid,
        :stack,
        :card,
        :list,
        :table
      ]

      Enum.each(valid_types, fn type ->
        attrs = %{
          type: type,
          props: %{},
          screen_id: screen.id,
          position: 1
        }

        assert {:ok, _element} = AshUI.Data.create(Element, attrs: attrs)
      end)
    end

    test "stores element props and variants", %{screen: screen} do
      attrs = %{
        type: :button,
        props: %{"label" => "Click me", "disabled" => false},
        variants: [:primary, :large],
        screen_id: screen.id,
        position: 1
      }

      assert {:ok, element} = AshUI.Data.create(Element, attrs: attrs)
      assert element.props == %{"label" => "Click me", "disabled" => false}
      assert element.variants == [:primary, :large]
    end

    test "invalid element DSL fails at compile time" do
      assert_raise ArgumentError, ~r/ui_element type must be a known widget type/, fn ->
        Code.compile_string("""
        defmodule InvalidElementDSLFixture do
          use AshUI.DSL.Element

          def attrs do
            ui_element do
              type :made_up_widget
            end
          end
        end
        """)
      end
    end

    test "compatibility namespace exposes element DSL helpers" do
      assert CompatElementDSLFixture.attrs() == %{type: :text, props: %{label: "Compat"}}
    end
  end

  describe "ui_binding DSL extension" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs: ScreenDocumentFixtures.resource_screen_attrs("binding_dsl_test", layout: :row)
        )

      {:ok, element} =
        AshUI.Data.create(Element,
          attrs: %{
            type: :textinput,
            props: %{},
            screen_id: screen.id,
            position: 1
          }
        )

      %{screen: screen, element: element}
    end

    test "builds validated binding attributes at compile time" do
      attrs = BindingDSLFixture.attrs()

      assert attrs.source == %{resource: "User", field: "name"}
      assert attrs.target == "value"
      assert attrs.binding_type == :value
      assert attrs.transform == %{default: "Anonymous"}
    end

    test "validates binding_type is one of :value, :list, :action", %{
      screen: screen,
      element: element
    } do
      valid_types = [:value, :list, :action]

      Enum.each(valid_types, fn type ->
        source =
          case type do
            :value -> %{"resource" => "Test", "field" => "test"}
            :list -> %{"resource" => "Test", "relationship" => "items"}
            :action -> %{"resource" => "Test", "action" => "submit"}
          end

        attrs = %{
          source: source,
          target: "target",
          binding_type: type,
          element_id: element.id,
          screen_id: screen.id
        }

        assert {:ok, _binding} = AshUI.Data.create(Binding, attrs: attrs)
      end)
    end

    test "stores transform configuration", %{screen: screen, element: element} do
      attrs = %{
        source: %{"resource" => "User", "field" => "name"},
        target: "value",
        binding_type: :value,
        transform: %{"function" => "uppercase", "args" => []},
        element_id: element.id,
        screen_id: screen.id
      }

      assert {:ok, binding} = AshUI.Data.create(Binding, attrs: attrs)
      assert binding.transform == %{"function" => "uppercase", "args" => []}
    end

    test "invalid binding DSL fails at compile time" do
      assert_raise ArgumentError, ~r/ui_binding binding_type must be one of/, fn ->
        Code.compile_string("""
        defmodule InvalidBindingDSLFixture do
          use AshUI.DSL.Binding

          def attrs do
            ui_binding do
              binding_type :invalid
            end
          end
        end
        """)
      end
    end

    test "compatibility namespace exposes binding DSL helpers" do
      assert CompatBindingDSLFixture.attrs() == %{
               source: %{resource: "User", field: "email"},
               target: "value",
               binding_type: :value
             }
    end
  end

  describe "Invalid DSL options" do
    setup do
      {:ok, screen} =
        AshUI.Data.create(Screen,
          attrs:
            ScreenDocumentFixtures.resource_screen_attrs("invalid_dsl_binding_test",
              layout: :row
            )
        )

      {:ok, element} =
        AshUI.Data.create(Element,
          attrs: %{
            type: :textinput,
            props: %{},
            screen_id: screen.id,
            position: 1
          }
        )

      %{screen: screen, element: element}
    end

    test "invalid binding_type produces validation error", %{screen: screen, element: element} do
      attrs = %{
        source: %{"resource" => "Test", "field" => "test"},
        target: "test",
        binding_type: :invalid_type,
        element_id: element.id,
        screen_id: screen.id
      }

      assert {:error, error} = AshUI.Data.create(Binding, attrs: attrs)
      assert Exception.message(error) =~ "binding_type"
    end
  end
end
