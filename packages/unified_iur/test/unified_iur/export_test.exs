defmodule UnifiedIUR.ExportTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Export, Fixtures, Validate}

  defmodule LiveUi.NativePreview do
    defstruct [:id]
  end

  test "exports stable fixture and snapshot representations" do
    assert {:ok, fixture_export} = Export.fixture("forms--profile_editor")
    assert fixture_export =~ "forms--profile_editor"
    assert fixture_export =~ "profile-editor"

    assert {:ok, snapshot_export} = Export.fixture("forms--profile_editor", :snapshot)
    assert snapshot_export =~ "kind: :form_builder"
    assert snapshot_export =~ "name: :profile"

    assert {:ok, navigation_export} =
             Export.navigation_fixture("screen_transition--settings_profile")

    assert navigation_export =~ "screen_transition--settings_profile"
    assert navigation_export =~ "action: :navigate_to"
    assert navigation_export =~ "screen: :settings"

    assert {:ok, navigation_snapshot} =
             Export.navigation_fixture("history_transition--back", :snapshot)

    assert navigation_snapshot =~ "action: :go_back"
    assert navigation_snapshot =~ "kind: :history_transition"
    refute navigation_snapshot =~ "screen:"

    assert {:ok, stacked_modal_export} =
             Export.navigation_fixture("modal_stack--open_confirm_dialog", :inspection)

    assert stacked_modal_export =~ "modal_stack"
    assert stacked_modal_export =~ "stack_effect: :push_modal"
  end

  test "exports diagnostics and diff reports for maintainers" do
    invalid =
      Element.new(:widget, :content,
        id: "invalid-runtime-local",
        attributes: %{extra: %{native: %LiveUi.NativePreview{id: "preview-1"}}}
      )

    diagnostics = Export.diagnostics(invalid)
    assert diagnostics =~ "runtime_local_escape_hatch"
    assert diagnostics =~ "interoperability"

    left = Fixtures.fixture!("foundational--workspace_chrome").element
    right = Fixtures.fixture!("forms--profile_editor").element

    diff = Export.diff(left, right)

    refute diff.equivalent?
    assert diff.text =~ "kind"
  end

  test "validation diagnostics expose actionable construct-family guidance" do
    invalid =
      Element.new(:widget, :content,
        id: "invalid-runtime-local",
        attributes: %{extra: %{native: %LiveUi.NativePreview{id: "preview-1"}}}
      )

    diagnostics = Validate.diagnostics(invalid)

    refute diagnostics.valid?
    assert [%{construct_family: :interoperability, guidance: guidance} | _] = diagnostics.errors
    assert guidance =~ "runtime-native structs"
  end
end
