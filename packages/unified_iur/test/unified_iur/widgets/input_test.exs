defmodule UnifiedIUR.Widgets.InputTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Widgets.Input

  test "exposes the canonical input widget family" do
    assert %{
             foundational: UnifiedIUR.Widgets.Foundational,
             input: Input
           } = Widgets.modules()

    assert [
             :text_input,
             :numeric_input,
             :toggle,
             :checkbox,
             :radio_group,
             :select,
             :pick_list,
             :slider,
             :date_input,
             :time_input,
             :file_input
           ] == Widgets.input_kinds()

    assert Widgets.input_kinds() == Input.kinds()
  end

  test "builds scalar and boolean input controls with binding and validation metadata" do
    text_input =
      Input.text_input(
        id: "username-input",
        name: :username,
        path: [:profile, :username],
        value: "pascal",
        placeholder: "Username",
        required?: true,
        constraints: %{min_length: 3},
        style_refs: [:input],
        accessibility_label: "Username"
      )

    numeric_input =
      Input.numeric_input(
        id: "age-input",
        name: :age,
        min: 0,
        max: 120,
        step: 1,
        value: 42
      )

    toggle =
      Input.toggle(
        id: "notifications-toggle",
        name: :notifications,
        value: true,
        disabled?: false
      )

    checkbox =
      Input.checkbox(
        id: "terms-checkbox",
        label_text: "I agree to the terms",
        checked_value: :accepted,
        unchecked_value: :pending
      )

    assert %Element{
             kind: :text_input,
             attributes: %{
               input: %{
                 value_kind: :text,
                 placeholder: "Username",
                 multiline?: false,
                 input_mode: :text
               },
               bindings: [
                 %Binding{name: :username, path: [:profile, :username], value: "pascal"}
               ],
               validation: %{required?: true, constraints: %{min_length: 3}},
               accessibility: %{label: "Username"},
               theme: %{
                 component: :text_input,
                 token_refs: [%{kind: :token_ref, path: [:input]}]
               }
             }
           } = text_input

    assert %Element{
             kind: :numeric_input,
             attributes: %{
               input: %{value_kind: :numeric, min: 0, max: 120, step: 1},
               bindings: [%Binding{name: :age, value: 42}]
             }
           } = numeric_input

    assert %Element{
             kind: :toggle,
             attributes: %{
               input: %{
                 value_kind: :boolean,
                 presentation: :toggle,
                 checked_value: true,
                 unchecked_value: false
               },
               bindings: [%Binding{name: :notifications, value: true}],
               state: %{disabled?: false}
             }
           } = toggle

    assert %Element{
             kind: :checkbox,
             attributes: %{
               input: %{
                 presentation: :checkbox,
                 checked_value: :accepted,
                 unchecked_value: :pending
               },
               label: %{text: "I agree to the terms"}
             }
           } = checkbox
  end

  test "accepts value_path and default_value as binding aliases for authored DSL compilation" do
    text_input =
      Input.text_input(
        id: "draft-note-input",
        value_path: [:note],
        default_value: "",
        placeholder: "Type your note"
      )

    assert %Element{
             kind: :text_input,
             attributes: %{
               bindings: [%Binding{path: [:note], default: ""}],
               input: %{placeholder: "Type your note"}
             }
           } = text_input
  end

  test "builds selection and specialized inputs with stable canonical option shape" do
    radio_group =
      Input.radio_group(
        [
          [id: :standard, value: :standard, label: "Standard"],
          [id: :pro, value: :pro, label: "Pro", selected?: true]
        ],
        id: "plan-choice",
        name: :plan
      )

    select =
      Input.select(
        [
          [value: "en", label: "English"],
          [value: "fr", label: "French", disabled?: true]
        ],
        id: "language-select",
        name: :language
      )

    pick_list =
      Input.pick_list(
        [
          [value: :specs, label: "Specs", selected?: true],
          [value: :tests, label: "Tests"]
        ],
        id: "artifact-picks",
        multiple?: true
      )

    slider = Input.slider(id: "volume-slider", name: :volume, min: 0, max: 10, step: 2, value: 6)
    date_input = Input.date_input(id: "start-date", min: ~D[2026-01-01], max: ~D[2026-12-31])
    time_input = Input.time_input(id: "start-time", step: 900)
    file_input = Input.file_input(id: "avatar-file", accept: [".png", ".jpg"], multiple?: false)

    assert %Element{
             kind: :radio_group,
             attributes: %{
               selection: %{
                 multiple?: false,
                 presentation: :radio_group,
                 options: [
                   %{id: :standard, value: :standard, label: "Standard"},
                   %{id: :pro, value: :pro, label: "Pro", selected?: true}
                 ]
               },
               bindings: [%Binding{name: :plan}]
             }
           } = radio_group

    assert %Element{
             kind: :select,
             attributes: %{
               selection: %{
                 multiple?: false,
                 presentation: :select,
                 options: [
                   %{value: "en", label: "English"},
                   %{value: "fr", label: "French", disabled?: true}
                 ]
               }
             }
           } = select

    assert %Element{
             kind: :pick_list,
             attributes: %{
               selection: %{
                 multiple?: true,
                 presentation: :pick_list,
                 options: [
                   %{value: :specs, label: "Specs", selected?: true},
                   %{value: :tests, label: "Tests"}
                 ]
               }
             }
           } = pick_list

    assert %Element{
             kind: :slider,
             attributes: %{
               input: %{value_kind: :range, min: 0, max: 10, step: 2},
               bindings: [%Binding{name: :volume, value: 6}]
             }
           } = slider

    assert %Element{
             kind: :date_input,
             attributes: %{
               input: %{
                 value_kind: :date,
                 format: :iso8601,
                 min: ~D[2026-01-01],
                 max: ~D[2026-12-31]
               }
             }
           } = date_input

    assert %Element{
             kind: :time_input,
             attributes: %{input: %{value_kind: :time, format: :iso8601, step: 900}}
           } = time_input

    assert %Element{
             kind: :file_input,
             attributes: %{file: %{accept: [".png", ".jpg"], multiple?: false}}
           } = file_input
  end
end
