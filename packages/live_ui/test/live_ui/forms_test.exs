defmodule LiveUi.FormsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "form builder and grouped fields compose baseline native form flows" do
    html =
      render_component(&LiveUi.Forms.FormBuilder.render/1, %{
        id: "account-form",
        autocomplete: false,
        inner_block: [
          %{
            __slot__: :inner_block,
            inner_block: fn _, _ ->
              Phoenix.HTML.raw(
                render_component(&LiveUi.Forms.FieldGroup.render/1, %{
                  id: "identity",
                  legend: "Identity",
                  inner_block: [
                    %{
                      __slot__: :inner_block,
                      inner_block: fn _, _ ->
                        Phoenix.HTML.raw(
                          render_component(&LiveUi.Forms.Field.render/1, %{
                            id: "name-field",
                            name: "name",
                            label: [%{__slot__: :label, inner_block: fn _, _ -> "Name" end}],
                            control: [
                              %{
                                __slot__: :control,
                                inner_block: fn _, _ ->
                                  Phoenix.HTML.raw(
                                    render_component(&LiveUi.Widgets.TextInput.render/1, %{
                                      id: "name",
                                      name: "name",
                                      value: "Pascal"
                                    })
                                  )
                                end
                              }
                            ]
                          })
                        )
                      end
                    }
                  ]
                })
              )
            end
          }
        ]
      })

    assert html =~ "data-live-ui-widget=\"form-builder\""
    assert html =~ "data-live-ui-widget=\"field-group\""
    assert html =~ "data-live-ui-widget=\"field\""
    assert html =~ "data-live-ui-widget=\"text-input\""
    assert html =~ "Pascal"
  end

  test "select defaults and field relationships stay visible in rendered markup" do
    html =
      render_component(&LiveUi.Widgets.Select.render/1, %{
        id: "status",
        name: "status",
        options: [
          %{value: "draft", label: "Draft"},
          %{value: "published", label: "Published", selected: true}
        ]
      })

    assert html =~ "data-live-ui-widget=\"select\""
    assert html =~ "Published"
    assert html =~ "selected"
  end
end
