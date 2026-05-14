defmodule UnifiedIUR.InteroperabilityTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Interoperability, Interaction, Layout}
  alias UnifiedIUR.Forms
  alias UnifiedIUR.Widgets.{Advanced, Foundational, Input}

  defmodule DesktopUi.NativeWidget do
    defstruct [:id]
  end

  test "walks and classifies canonical trees for runtime-library consumption" do
    form =
      Forms.form_builder(
        [
          {:fields,
           Forms.field(
             Input.text_input(id: "email-input", name: :email, path: [:profile, :email]),
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
      )

    command_palette =
      Advanced.command_palette(
        [
          [id: :open_file, label: "Open File", value: :open_file]
        ],
        id: "command-palette",
        interactions: [Interaction.command(intent: :open_file, command: :open_file)]
      )

    screen =
      Layout.column(
        [
          {:content, form},
          {:content, command_palette}
        ],
        id: "workspace-screen"
      )

    assert Enum.map(Interoperability.walk(screen), & &1.id) == [
             "workspace-screen",
             "profile-form",
             "email-field",
             "email-input-label",
             "email-input",
             "save-button",
             "command-palette"
           ]

    assert Enum.map(Interoperability.widgets(screen), & &1.kind) == [
             :label,
             :text_input,
             :button,
             :command_palette
           ]

    assert Interoperability.identity(screen) == %{
             id: "workspace-screen",
             type: :layout,
             kind: :column
           }

    assert Interoperability.classify(form) == %{
             widget?: false,
             layout?: false,
             layer?: false,
             composite?: true,
             child_shape: :multi,
             attachment_keys: [:bindings, :interactions]
           }

    assert length(Interoperability.bindings(screen)) == 2

    assert Enum.map(Interoperability.interactions(screen), & &1.family) == [
             :submit,
             :click,
             :command
           ]
  end

  test "reports runtime safety and rejects runtime-local escape hatches" do
    safe =
      Foundational.text("Ready",
        id: "status-text",
        style: %{foreground: :success}
      )

    unsafe = %{
      id: "unsafe-content",
      type: :widget,
      kind: :content,
      content: %{text: "Native"},
      extra: %{native_widget: %DesktopUi.NativeWidget{id: "native-1"}}
    }

    assert Interoperability.runtime_safe?(safe)
    refute Interoperability.runtime_safe?(unsafe)

    report = Interoperability.compatibility_report(unsafe)

    refute report.valid?
    refute report.runtime_safe?
    assert report.consumers == [:live_ui, :elm_ui, :desktop_ui]
    assert Enum.any?(report.issues, &(&1.code == :runtime_local_escape_hatch))
  end

  test "exposes canonical attachment summaries without requiring authored DSL modules" do
    button =
      Foundational.button("Deploy",
        id: "deploy-button",
        action: [intent: :deploy],
        style_refs: [:primary_button],
        variant: :primary
      )

    [summary] = Interoperability.attachments(button)

    assert %{
             id: "deploy-button",
             type: :widget,
             kind: :button,
             attachments: %{
               theme: %{
                 component: :button,
                 token_refs: [%{kind: :token_ref, path: [:primary_button]}],
                 variant: :primary
               },
               interactions: [%Interaction{family: :click, intent: :deploy}]
             }
           } = summary
  end
end
