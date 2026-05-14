defmodule UnifiedIUR.Phase5IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Extension, Interoperability, Normalize, Reference}
  alias UnifiedIUR.Forms
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Widgets.{Foundational, Input}

  defmodule ElmUi.NativeNode do
    defstruct [:id]
  end

  test "phase 5 normalizes equivalent authored input into identical canonical runtime-consumable shape" do
    left =
      Layout.column(
        [
          {:content,
           Forms.form_builder(
             [
               {:fields,
                Forms.field(
                  Input.text_input(
                    id: "email-input",
                    name: :email,
                    path: [:profile, :email],
                    value: "user@example.com"
                  ),
                  id: "email-field",
                  label: "Email"
                )},
               {:actions,
                Foundational.button("Save", id: "save-button", action: [intent: :save_profile])}
             ],
             id: "profile-form",
             name: :profile,
             path: [:profile],
             submit_intent: :save_profile
           )}
        ],
        id: "profile-screen"
      )

    right = %{
      "id" => "profile-screen",
      "type" => :layout,
      "kind" => :column,
      "layout" => %{"direction" => :vertical},
      "children" => [
        %{
          "slot" => :content,
          "element" => %{
            "id" => "profile-form",
            "type" => :composite,
            "kind" => :form_builder,
            "form" => %{"mode" => :grouped, "autocomplete?" => true},
            "bindings" => [
              %{"name" => :profile, "path" => [:profile]}
            ],
            "interactions" => [
              %{
                "family" => :submit,
                "intent" => :save_profile,
                "source" => %{"element_id" => "profile-form"},
                "target" => %{"binding" => [:profile]},
                "metadata" => %{"phase" => :submit}
              }
            ],
            "children" => [
              %{
                "slot" => :fields,
                "element" => %{
                  "id" => "email-field",
                  "type" => :composite,
                  "kind" => :field,
                  "field" => %{"control_id" => "email-input", "label_slot" => :label},
                  "children" => [
                    %{
                      "slot" => :label,
                      "element" => %{
                        "id" => "email-input-label",
                        "type" => :widget,
                        "kind" => :label,
                        "content" => %{"text" => "Email"},
                        "label" => %{"for" => "email-input", "relationship" => :field_label}
                      }
                    },
                    %{
                      "slot" => :control,
                      "element" => %{
                        "id" => "email-input",
                        "type" => :widget,
                        "kind" => :text_input,
                        "input" => %{
                          "value_kind" => :text,
                          "multiline?" => false,
                          "input_mode" => :text
                        },
                        "binding" => %{
                          "name" => :email,
                          "path" => [:profile, :email],
                          "value" => "user@example.com"
                        }
                      }
                    }
                  ]
                }
              },
              %{
                "slot" => :actions,
                "element" => %{
                  "id" => "save-button",
                  "type" => :widget,
                  "kind" => :button,
                  "content" => %{"text" => "Save"},
                  "interactions" => [
                    %{
                      "family" => :click,
                      "intent" => :save_profile,
                      "source" => %{"element_id" => "save-button"}
                    }
                  ]
                }
              }
            ]
          }
        }
      ]
    }

    normalized_left = Normalize.element!(left)
    normalized_right = Normalize.element!(right)

    assert Reference.equivalent?(normalized_left, normalized_right)
    assert Reference.snapshot(normalized_left) == Reference.snapshot(normalized_right)

    assert Interoperability.identity(normalized_left) == %{
             id: "profile-screen",
             type: :layout,
             kind: :column
           }

    assert Enum.map(Interoperability.widgets(normalized_right), & &1.kind) == [
             :label,
             :text_input,
             :button
           ]

    assert Enum.map(Interoperability.interactions(normalized_right), &{&1.family, &1.intent}) == [
             submit: :save_profile,
             click: :save_profile
           ]
  end

  test "phase 5 rejects runtime-local escape hatches from canonical structures" do
    unsafe = %{
      id: "unsafe-screen",
      type: :widget,
      kind: :content,
      content: %{text: "Native"},
      extra: %{native: %ElmUi.NativeNode{id: "native-1"}}
    }

    refute Interoperability.runtime_safe?(unsafe)
    refute Interoperability.compatibility_report(unsafe).valid?

    assert Enum.any?(
             Interoperability.compatibility_report(unsafe).issues,
             &(&1.code == :runtime_local_escape_hatch)
           )
  end

  test "phase 5 additive extension fields preserve traversal shape and diff stability" do
    base =
      %{
        id: "toolbar",
        type: :layout,
        kind: :row,
        children: [
          %{
            slot: :content,
            element: %{id: "save-button", type: :widget, kind: :button, content: %{text: "Save"}}
          }
        ]
      }
      |> Normalize.element!()

    extended =
      %{
        id: "toolbar",
        type: :layout,
        kind: :row,
        metadata: %{extra: %{release: "v1"}},
        attributes: %{extra: %{surface: :toolbar}},
        children: [
          %{
            slot: :content,
            element: %{
              id: "save-button",
              type: :widget,
              kind: :button,
              content: %{text: "Save"},
              metadata: %{extra: %{variant: :primary}}
            }
          }
        ]
      }
      |> Normalize.element!()

    assert Reference.snapshot(base) == Reference.snapshot(Normalize.element!(base))
    assert Interoperability.identity(base) == Interoperability.identity(extended)

    assert Enum.map(Interoperability.walk(base), &{&1.id, &1.kind}) ==
             Enum.map(Interoperability.walk(extended), &{&1.id, &1.kind})

    assert Enum.all?(Reference.shape_diff(base, extended), fn diff ->
             hd(diff.path) in [:metadata, :attributes, :children]
           end)
  end

  test "phase 5 parity safeguards catch unsynchronized unified_ui updates" do
    assert {:error, issues} =
             Extension.validate_unified_ui_parity(%{
               foundational_widgets: [:text, :button],
               input_widgets: [:text_input],
               layout_constructs: [:column, :row],
               layer_constructs: [:dialog]
             })

    assert Enum.any?(issues, &(&1.kind == :missing_in_unified_ui))
    refute Extension.parity_report(%{}).synchronized?
  end
end
