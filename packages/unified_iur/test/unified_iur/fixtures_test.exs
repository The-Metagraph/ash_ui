defmodule UnifiedIUR.FixturesTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Fixtures, Interaction, Interoperability}

  test "exposes stable fixture ids, categories, and naming conventions" do
    assert Fixtures.naming_rules() == %{
             fixture_id_pattern: "category--scenario",
             snapshot_suffix: ".snapshot",
             categories: [:foundational, :forms, :data, :display, :advanced, :components]
           }

    assert Enum.all?(Fixtures.ids(), &Fixtures.valid_id?/1)

    assert Enum.sort(Fixtures.categories()) == [
             :advanced,
             :components,
             :data,
             :display,
             :forms,
             :foundational
           ]
  end

  test "loads fixture catalog entries with semantics, parity obligations, and canonical elements" do
    assert {:ok, fixture} = Fixtures.fixture("forms--profile_editor")

    assert fixture.id == "forms--profile_editor"
    assert fixture.category == :forms
    assert fixture.snapshot_path == "fixtures/forms--profile_editor.snapshot"
    assert :input_widgets in fixture.parity_obligations
    assert length(fixture.semantics) >= 3

    assert Interoperability.identity(fixture.element) == %{
             id: "profile-editor",
             type: :composite,
             kind: :form_builder
           }
  end

  test "covers the full canonical catalog across the reference fixture suite" do
    report = Fixtures.coverage_report()

    assert report.complete?
    assert "advanced--operations_center" in report.fixture_ids
    assert "components--accessibility_and_safety" in report.fixture_ids
    assert :dialog in report.covered_kinds
    assert :canvas in report.covered_kinds
    assert :redline_inline in report.covered_kinds
    assert :list_repeat in report.covered_kinds
    assert :text_input in report.covered_kinds
    assert report.attachment_families.style_semantics.covered?
    assert report.attachment_families.theme_semantics.covered?
    assert report.attachment_families.interaction_semantics.covered?
    assert report.attachment_families.binding_semantics.covered?

    assert Enum.all?(report.categories, fn {_category, category_report} ->
             category_report.missing == []
           end)
  end

  test "exposes dedicated canonical navigation transition fixtures" do
    assert Fixtures.navigation_ids() == [
             "screen_transition--settings_profile",
             "replace_transition--home",
             "history_transition--back",
             "modal_transition--settings_dialog",
             "modal_stack--open_confirm_dialog",
             "modal_stack--close_top",
             "modal_stack--close_named_settings"
           ]

    assert {:ok, history_fixture} = Fixtures.navigation_fixture("history_transition--back")

    assert history_fixture.snapshot_path ==
             "fixtures/navigation/history_transition--back.snapshot"

    assert "targetless history traversal" in history_fixture.semantics

    assert %Interaction{
             family: :navigation,
             intent: :go_back_history,
             target: %{navigation: %{action: :go_back, kind: :history_transition}}
           } = history_fixture.interaction

    refute Map.has_key?(Interaction.navigation_descriptor(history_fixture.interaction), :screen)

    assert {:ok, stacked_close} = Fixtures.navigation_fixture("modal_stack--close_top")

    assert Interaction.navigation_descriptor(stacked_close.interaction) == %{
             action: :close_modal,
             kind: :modal_transition,
             metadata: %{reason: :cancel},
             modal_stack: %{
               operation: :close,
               target: :topmost_modal,
               target_required?: false,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :close_topmost_or_named_modal
             }
           }

    assert %{
             id: "modal_transition--settings_dialog",
             snapshot_path: "fixtures/navigation/modal_transition--settings_dialog.snapshot"
           } =
             Enum.find(
               Fixtures.navigation_catalog(),
               &(&1.id == "modal_transition--settings_dialog")
             )
  end
end
