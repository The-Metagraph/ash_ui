defmodule UnifiedIUR.ValidateTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Binding, Element, Interaction, Style, Validate}
  alias UnifiedIUR.Widgets.Components

  defmodule LiveUi.NativeButton do
    defstruct [:id]
  end

  test "accepts canonical normalized attachment shapes" do
    element =
      Element.new(:widget, :button,
        id: "save-button",
        attributes: %{
          content: %{text: "Save"},
          style: Style.new(%{foreground: :accent}),
          interactions: [Interaction.click(intent: :save_profile)],
          bindings: [Binding.new(%{name: :profile, path: [:profile]})]
        },
        children: []
      )

    assert :ok = Validate.element(element)
  end

  test "rejects malformed attachment types with typed validation errors" do
    element =
      Element.new(:widget, :button,
        id: "save-button",
        attributes: %{
          style: %{foreground: :accent},
          interactions: [%{family: :click}]
        },
        children: []
      )

    assert {:error, errors} = Validate.element(element)

    assert Enum.any?(errors, &(&1.code == :invalid_style_attachment))
    assert Enum.any?(errors, &(&1.code == :invalid_interaction_attachment))
  end

  test "rejects runtime-local structs embedded in canonical values" do
    element =
      Element.new(:widget, :content,
        id: "native-wrapper",
        attributes: %{
          extra: %{native: %LiveUi.NativeButton{id: "button-1"}}
        },
        children: []
      )

    assert {:error, [error]} = Validate.element(element)
    assert error.code == :runtime_local_escape_hatch
  end

  test "validates redline and code component text safety shapes without rejecting plain text markup" do
    safe_redline =
      Components.redline_inline([
        %{state: :insert, text: "<script>alert(1)</script>"}
      ])

    invalid_redline =
      Components.redline_inline([
        %{state: :markup, text: "<b>unsafe state</b>"}
      ])

    invalid_code =
      Components.code_block_syntax_highlighted(:elixir, [
        %{type: :html, text: "<strong>bad token type</strong>"}
      ])

    assert :ok = Validate.element(safe_redline)
    assert {:error, [redline_error]} = Validate.element(invalid_redline)
    assert redline_error.code == :invalid_text_segment

    assert {:error, [code_error]} = Validate.element(invalid_code)
    assert code_error.code == :invalid_code_token
  end

  test "validates required component accessible names and progress ranges" do
    missing_panel_name = Components.slide_over_panel([], id: "panel")
    invalid_meter = Components.meter_thin(120, minimum: 0, maximum: 100)

    assert {:error, [panel_error]} = Validate.element(missing_panel_name)
    assert panel_error.code == :missing_accessible_name

    assert {:error, [meter_error]} = Validate.element(invalid_meter)
    assert meter_error.code == :invalid_progress_value
  end

  test "validates segmented control and list repeat required shapes" do
    invalid_segmented = Components.segmented_button_group([%{label: "Missing value"}])
    invalid_repeat = Components.list_repeat(nil, row_fields: [:id])

    assert {:error, [segmented_error]} = Validate.element(invalid_segmented)
    assert segmented_error.code == :invalid_selection_option

    assert {:error, [repeat_error]} = Validate.element(invalid_repeat)
    assert repeat_error.code == :invalid_repeat_binding
  end

  test "validates first-class artifact row fields" do
    valid_artifact =
      Components.artifact_row("ADR", [],
        row_identity: :adr,
        artifact_kind: :spec,
        status_badges: [%{label: "Accepted", tone: :positive}],
        counts: [%{key: :comments, value: 3, label: "Comments"}]
      )

    invalid_artifact =
      Element.new(:widget, :artifact_row,
        attributes: %{
          component: %{family: :row_and_artifact, kind: :artifact_row},
          artifact: %{
            title: "ADR",
            row_identity: :adr,
            kind: :conversation,
            status_badges: [%{tone: :unknown}],
            counts: %{comments: 3}
          }
        }
      )

    assert :ok = Validate.element(valid_artifact)
    assert {:error, errors} = Validate.element(invalid_artifact)

    assert Enum.map(errors, & &1.code) == [
             :invalid_artifact_kind,
             :invalid_artifact_status_badge,
             :invalid_artifact_count
           ]
  end
end
