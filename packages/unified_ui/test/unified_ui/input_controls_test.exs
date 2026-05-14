defmodule UnifiedUi.InputControlsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Compiler

  defmodule ExpandedInputScreen do
    use UnifiedUi.Dsl

    identity do
      id(:expanded_input_screen)
      authored_ref([:examples, :expanded_input_screen])
    end

    composition do
      root(:expanded_input_root)
      mode(:screen)

      form_builder :expanded_input_form do
        summary("Expanded input-control authoring surface")

        field_group :expanded_input_group do
          legend("Primary inputs")

          field :quantity do
            field_name(:quantity)
            label("Quantity")

            numeric_input :quantity_input do
              placeholder("0")
              min(0)
              max(100)
              step(5)
            end
          end

          field :subscribed do
            field_name(:subscribed)
            label("Subscribed")

            checkbox :subscribed_input do
            end
          end

          field :role do
            field_name(:role)
            label("Role")

            radio_group :role_input do
              options(admin: "Admin", member: "Member")
            end
          end

          field :labels do
            field_name(:labels)
            label("Labels")

            pick_list :labels_input do
              options(alpha: "Alpha", beta: "Beta")
            end
          end

          field :publish_on do
            field_name(:publish_on)
            label("Publish on")

            date_input :publish_on_input do
              min("2026-01-01")
              max("2026-12-31")
            end
          end

          field :publish_at do
            field_name(:publish_at)
            label("Publish at")

            time_input :publish_at_input do
              min("08:00")
              max("18:00")
              step(900)
            end
          end

          field :attachment do
            field_name(:attachment)
            label("Attachment")

            file_input :attachment_input do
              accept(["image/png", "image/jpeg"])
              multiple?(true)
              capture("environment")
            end
          end
        end

        field :region do
          field_name(:region)
          label("Region")

          select :region_input do
            options(us: "United States", eu: "Europe")
          end
        end

        field :enabled do
          field_name(:enabled)
          label("Enabled")

          toggle :enabled_input do
          end
        end
      end
    end
  end

  test "stores the expanded input-control surface in the authored composition tree" do
    [form] = Extension.get_entities(ExpandedInputScreen, [:composition])

    assert form.kind == :form_builder

    [group, region, enabled] = form.children

    assert group.kind == :field_group

    assert Enum.map(group.children, &control_kind/1) == [
             :numeric_input,
             :checkbox,
             :radio_group,
             :pick_list,
             :date_input,
             :time_input,
             :file_input
           ]

    assert control_kind(region) == :select
    assert control_kind(enabled) == :toggle
  end

  test "compiler lowers the expanded input-control surface into canonical UnifiedIUR widgets" do
    {:ok, result} = Compiler.compile(ExpandedInputScreen)

    [form_child] = result.iur.children
    form = form_child.element
    [group_child | standalone_fields] = form.children
    group = group_child.element

    assert Enum.map(group.children, &control_kind_from_iur/1) == [
             :numeric_input,
             :checkbox,
             :radio_group,
             :pick_list,
             :date_input,
             :time_input,
             :file_input
           ]

    assert Enum.map(standalone_fields, &control_kind_from_iur/1) == [:select, :toggle]

    attachment_field = Enum.at(group.children, 6).element
    control = control_element(attachment_field)

    assert control.kind == :file_input
    assert get_in(control.attributes, [:file, :accept]) == ["image/png", "image/jpeg"]
    assert get_in(control.attributes, [:file, :multiple?]) == true
    assert get_in(control.attributes, [:file, :capture]) == "environment"
  end

  defp control_kind(field_node) do
    field_node.children |> List.first() |> Map.fetch!(:kind)
  end

  defp control_kind_from_iur(field_child) do
    field_child.element |> control_element() |> Map.fetch!(:kind)
  end

  defp control_element(field_element) do
    field_element.children
    |> Enum.find(fn child -> child.slot == :control end)
    |> Map.fetch!(:element)
  end
end
