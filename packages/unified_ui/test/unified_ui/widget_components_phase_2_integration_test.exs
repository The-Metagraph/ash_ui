defmodule UnifiedUi.WidgetComponentsPhase2IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Export, Fixtures, Interaction, Interoperability, Tree, Validate}
  alias UnifiedUi.Compiler

  defmodule EndToEndWidgetScreen do
    use UnifiedUi.Dsl

    identity do
      id(:widget_components_phase_2_screen)
      authored_ref([:tests, :widget_components_phase_2_screen])
    end

    signals do
      data_binding do
        id(:artifact_rows)
        path([:artifacts])
        collection?(true)
        default([%{id: "adr-1", title: "Widget ADR", status: :accepted}])
      end
    end

    composition do
      root(:widget_components_phase_2_root)
      mode(:screen)

      inline_rich_text_heading :headline do
        level(:h2)
        segments([%{type: :text, value: "Widget components"}])
      end

      segmented_button_group :status_filter do
        options([%{value: :all, label: "All"}, %{value: :open, label: "Open"}])
        active_value(:all)
        selection_intent(:select_status)
      end

      runtime_form_shell :settings_form do
        fields([%{name: :title, type: :text, label: "Title"}])
        submit_label("Save")
        submit_intent(:save_settings)
        change_intent(:validate_settings)
      end

      sidebar_item :build_item do
        label("build/widget-adr")
        glyph("◇")
        meta("accepted")
        state(:blocked)
        item_kind(:build)
        item_id("adr-1")
        action_intent(:open_artifact)
        unread_count(2)
      end

      sidebar_section :builds_section do
        title("Builds")
        action_glyph("+")
        action_label("New build")
        action_intent(:new_build)

        sidebar_item :nested_build_item do
          label("build/widget-adr-nested")
          glyph("◇")
          meta("queued")
          state(:default)
          item_kind(:build)
          item_id("adr-1-nested")
          action_intent(:open_nested_artifact)
          unread_count(1)
        end
      end

      slide_over_panel :details_panel do
        accessibility_label("Details")
        open?(true)
        dismiss_intent(:close_details)
      end

      redline_inline :copy_redline do
        segments([%{state: :insert, text: "<script>safe text</script>"}])
      end

      code_block_syntax_highlighted :code_sample do
        language(:elixir)
        tokens([%{type: :keyword, text: "defmodule"}, %{type: :text, text: " Demo"}])
      end

      list_repeat :artifact_repeat do
        repeat_binding(:artifact_rows)
        row_fields([:id, :title, :status])
        template_identity(:artifact_template)

        artifact_row_template :artifact_template do
          title("Artifact")
          row_identity(:id)
          meta(%{status: :status})
          action_intent(:open_artifact)
        end
      end
    end
  end

  test "compiles expanded widget components into valid deterministic IUR snapshots" do
    result = Compiler.compile!(EndToEndWidgetScreen)
    listing = Compiler.listing(EndToEndWidgetScreen)
    snapshot = Export.snapshot(result.iur)

    assert :ok = Validate.element(result.iur)

    for kind <- [
          :inline_rich_text_heading,
          :segmented_button_group,
          :runtime_form_shell,
          :sidebar_section,
          :slide_over_panel,
          :redline_inline,
          :code_block_syntax_highlighted,
          :list_repeat,
          :artifact_row,
          :sidebar_item
        ] do
      assert kind in listing.compiled.widget_kinds
      assert snapshot =~ to_string(kind)
    end

    refute snapshot =~ "AshUi"
    refute snapshot =~ "phx_"
  end

  test "preserves interaction descriptors and repeat hydration end to end" do
    iur = Compiler.iur!(EndToEndWidgetScreen)

    segmented = Tree.find_by_id(iur, :status_filter)
    form = Tree.find_by_id(iur, :settings_form)
    section = Tree.find_by_id(iur, :builds_section)
    panel = Tree.find_by_id(iur, :details_panel)
    repeat = Tree.find_by_id(iur, :artifact_repeat)

    assert [%Interaction{family: :selection, intent: :select_status}] =
             segmented.attributes.interactions

    assert Enum.map(form.attributes.interactions, &{&1.family, &1.intent}) == [
             {:submit, :save_settings},
             {:change, :validate_settings}
           ]

    assert [%Interaction{family: :click, intent: :new_build}] = section.attributes.interactions
    assert Enum.map(section.children, & &1.element.kind) == [:sidebar_item]

    assert [%Interaction{family: :close, intent: :close_details}] = panel.attributes.interactions

    assert repeat.attributes.repeat.hydrated? == true
    assert repeat.attributes.repeat.row_count == 1
    assert [%{element: hydrated}] = repeat.children
    assert hydrated.id == "artifact_repeat:adr-1:artifact_template"
    assert hydrated.attributes.artifact.row_identity == "adr-1"
    assert hydrated.attributes.artifact.meta == %{status: :accepted}
  end

  test "component fixture gives runtimes shared validation and parity evidence" do
    fixture = Fixtures.fixture!("components--accessibility_and_safety")
    kinds = fixture.element |> Interoperability.walk() |> Enum.map(& &1.kind)

    assert :ok = Validate.element(fixture.element)
    assert fixture.category == :components
    assert "redline and code plain-text safety" in fixture.semantics
    assert :redline_inline in kinds
    assert :slide_over_panel in kinds
    assert :list_repeat in kinds
  end
end
