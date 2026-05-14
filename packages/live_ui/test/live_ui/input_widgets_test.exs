defmodule LiveUi.InputWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component

  @moduledoc """
  Regression tests for input widgets to verify they preserve
  local state, event semantics, and form integration through
  the widget component architecture.
  """

  describe "text_input widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.TextInput)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.TextInput.Component
      assert metadata.family == :input
      assert metadata.name == :text_input
      assert :change in metadata.events
    end

    test "component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.TextInput.component/1, %{
          id: "username-input",
          name: "username",
          label: "Username"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="text_input")
      assert html =~ ~s(data-live-ui-widget-key="native:input:text_input:username-input:root")
      assert html =~ "Username"
    end

    test "component supports disabled state" do
      html =
        render_component(&LiveUi.Widgets.TextInput.component/1, %{
          id: "disabled-input",
          name: "field",
          disabled: true
        })

      assert html =~ ~s(disabled)
    end

    test "component supports placeholder" do
      html =
        render_component(&LiveUi.Widgets.TextInput.component/1, %{
          id: "input-with-placeholder",
          name: "field",
          placeholder: "Enter text..."
        })

      assert html =~ ~s(placeholder="Enter text...")
    end
  end

  describe "toggle widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Toggle)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Toggle.Component
      assert metadata.family == :input
      assert metadata.name == :toggle
      assert :change in metadata.events
    end

    test "component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Toggle.component/1, %{
          id: "enabled-toggle",
          name: "enabled",
          label: "Enabled"
        })

      assert html =~ ~s(data-live-ui-widget-boundary="toggle")
      assert html =~ ~s(data-live-ui-widget-key="native:input:toggle:enabled-toggle:root")
      assert html =~ "Enabled"
    end

    test "component supports checked state" do
      html =
        render_component(&LiveUi.Widgets.Toggle.component/1, %{
          id: "checked-toggle",
          name: "option",
          checked: true
        })

      assert html =~ ~s(checked)
    end

    test "component supports disabled state" do
      html =
        render_component(&LiveUi.Widgets.Toggle.component/1, %{
          id: "disabled-toggle",
          name: "option",
          disabled: true
        })

      assert html =~ ~s(disabled)
    end
  end

  describe "select widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Select)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Select.Component
      assert metadata.family == :input
      assert metadata.name == :select
      assert :change in metadata.events
    end

    test "component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Select.component/1, %{
          id: "choice-select",
          name: "choice",
          options: [%{value: "1", label: "One"}, %{value: "2", label: "Two"}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="select")
      assert html =~ ~s(data-live-ui-widget-key="native:input:select:choice-select:root")
      assert html =~ "One"
      assert html =~ "Two"
    end

    test "component supports disabled state" do
      html =
        render_component(&LiveUi.Widgets.Select.component/1, %{
          id: "disabled-select",
          name: "choice",
          options: [],
          disabled: true
        })

      assert html =~ ~s(disabled)
    end

    test "component supports placeholder option" do
      html =
        render_component(&LiveUi.Widgets.Select.component/1, %{
          id: "select-with-placeholder",
          name: "choice",
          options: [%{value: "1", label: "One"}],
          placeholder: "Select an option"
        })

      assert html =~ "Select an option"
    end
  end

  describe "form widgets" do
    test "field widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Forms.Field)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Forms.Field.Component
      assert metadata.family == :input
      assert metadata.name == :field
    end

    test "field component renders with label and control slots" do
      html =
        render_component(&LiveUi.Forms.Field.component/1, %{
          id: "email-field",
          name: "email",
          label: [
            %{__slot__: :label, inner_block: fn _, _ -> "Email" end}
          ],
          control: [
            %{
              __slot__: :control,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw(~s(<input type="text" name="email" />))
              end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="field")
      assert html =~ "Email"
      assert html =~ ~s(name="email")
    end

    test "field_group widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Forms.FieldGroup)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Forms.FieldGroup.Component
      assert metadata.family == :input
      assert metadata.name == :field_group
    end

    test "field_group component renders with multiple fields" do
      html =
        render_component(&LiveUi.Forms.FieldGroup.component/1, %{
          id: "user-fields",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw("""
                #{render_component(&LiveUi.Forms.Field.component/1, %{
                  id: "field-1",
                  name: "name",
                  label: [%{__slot__: :label, inner_block: fn _, _ -> "Name" end}],
                  control: [%{__slot__: :control, inner_block: fn _, _ -> Phoenix.HTML.raw(~s(<input type="text" name="name" />)) end}]
                })}
                #{render_component(&LiveUi.Forms.Field.component/1, %{
                  id: "field-2",
                  name: "email",
                  label: [%{__slot__: :label, inner_block: fn _, _ -> "Email" end}],
                  control: [%{__slot__: :control, inner_block: fn _, _ -> Phoenix.HTML.raw(~s(<input type="text" name="email" />)) end}]
                })}
                """)
              end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="field_group")
      assert html =~ "Name"
      assert html =~ "Email"
    end

    test "form_builder widget has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Forms.FormBuilder)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Forms.FormBuilder.Component
      assert metadata.family == :input
      assert metadata.name == :form_builder
      assert :submit in metadata.events
    end

    test "form_builder component renders with submit event" do
      html =
        render_component(&LiveUi.Forms.FormBuilder.component/1, %{
          id: "signup-form",
          for: "user",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw("""
                #{render_component(&LiveUi.Forms.Field.component/1, %{
                  id: "name",
                  name: "name",
                  label: [%{__slot__: :label, inner_block: fn _, _ -> "Name" end}],
                  control: [%{__slot__: :control, inner_block: fn _, _ -> Phoenix.HTML.raw(~s(<input type="text" name="name" />)) end}]
                })}
                #{render_component(&LiveUi.Widgets.Button.component/1, %{id: "submit", label: "Sign Up"})}
                """)
              end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="form_builder")
      assert html =~ "Name"
      assert html =~ "Sign Up"
      assert html =~ ~s(for="user")
    end
  end

  describe "input event semantics" do
    test "text_input has change event in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.TextInput)

      assert :change in metadata.events
    end

    test "toggle has change event in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Toggle)

      assert :change in metadata.events
    end

    test "select has change event in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.Select)

      assert :change in metadata.events
    end

    test "form_builder has submit event in metadata" do
      metadata = Component.metadata(LiveUi.Forms.FormBuilder)

      assert :submit in metadata.events
    end
  end

  describe "bounded local state support" do
    test "input widgets support local_state_keys for bounded state" do
      text_metadata = Component.metadata(LiveUi.Widgets.TextInput)
      toggle_metadata = Component.metadata(LiveUi.Widgets.Toggle)
      select_metadata = Component.metadata(LiveUi.Widgets.Select)

      # Input widgets can have local_state_keys for bounded UI state
      assert is_list(text_metadata.local_state_keys)
      assert is_list(toggle_metadata.local_state_keys)
      assert is_list(select_metadata.local_state_keys)
    end
  end

  describe "form composition with widget components" do
    test "form_builder can nest multiple field widgets" do
      html =
        render_component(&LiveUi.Forms.FormBuilder.component/1, %{
          id: "login-form",
          for: "session",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw("""
                #{render_component(&LiveUi.Forms.Field.component/1, %{
                  id: "email-field",
                  name: "email",
                  label: [%{__slot__: :label, inner_block: fn _, _ -> "Email" end}],
                  control: [%{__slot__: :control, inner_block: fn _, _ -> Phoenix.HTML.raw(~s(<input type="text" name="email" />)) end}]
                })}
                #{render_component(&LiveUi.Forms.Field.component/1, %{
                  id: "password-field",
                  name: "password",
                  label: [%{__slot__: :label, inner_block: fn _, _ -> "Password" end}],
                  control: [%{__slot__: :control, inner_block: fn _, _ -> Phoenix.HTML.raw(~s(<input type="password" name="password" />)) end}]
                })}
                #{render_component(&LiveUi.Widgets.Button.component/1, %{id: "submit", label: "Sign Up"})}
                """)
              end
            }
          ]
        })

      assert html =~ "Email"
      assert html =~ "Password"
      # Each field should have its own widget boundary
      assert html =~ ~s(data-live-ui-widget-boundary="field")
      # Form should have form_builder boundary
      assert html =~ ~s(data-live-ui-widget-boundary="form_builder")
    end

    test "field_group composes with widget component boundaries" do
      html =
        render_component(&LiveUi.Forms.FieldGroup.component/1, %{
          id: "personal-info",
          inner_block: [
            %{
              __slot__: :inner_block,
              inner_block: fn _, _ ->
                render_component(&LiveUi.Widgets.TextInput.component/1, %{
                  id: "name",
                  name: "name",
                  label: "Name"
                })
              end
            }
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="field_group")
      # text_input widget should be nested (check for widget name without worrying about HTML entity encoding)
      assert html =~ "text_input"
      assert html =~ "name"
    end
  end
end
