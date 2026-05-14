defmodule LiveUi.SignalsTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias UnifiedIUR.Interaction

  test "keeps direct native events local unless they cross the canonical boundary" do
    assert {:ok, translation} =
             LiveUi.Signals.from_native(
               family: :click,
               intent: :select_tab,
               screen: :dashboard,
               element_id: :activity_tab,
               widget: :tabs,
               payload: %{tab: "activity"}
             )

    assert translation.boundary == :local
    assert translation.signal == nil
    assert translation.runtime_event == "click:select_tab"
    assert translation.payload == %{tab: "activity"}
  end

  test "translates boundary native events into canonical Jido.Signal envelopes" do
    assert {:ok, translation} =
             LiveUi.Signals.from_native(
               family: :submit,
               intent: :save_profile,
               screen: :profile,
               element_id: :profile_form,
               widget: :form_builder,
               mode: :screen,
               boundary: :boundary,
               payload: %{profile: %{display_name: "Pascal"}},
               target: %{binding: :profile_form_data}
             )

    assert translation.boundary == :boundary
    assert %Signal{} = translation.signal
    assert translation.signal.type == "live_ui.submit.save_profile"
    assert translation.signal.source == "/live_ui/native/screen/profile"
    assert translation.signal.subject == "native/profile/profile_form"
    assert translation.signal.data == %{profile: %{display_name: "Pascal"}}
  end

  test "translates canonical interactions into boundary signals and runtime actions" do
    interaction =
      Interaction.submit(
        intent: :save_profile,
        element_id: :profile_form,
        binding: :profile_form_data,
        mapping: %{profile: :profile_form_data},
        phase: :submit
      )

    assert {:ok, translation} =
             LiveUi.Signals.from_interaction(
               interaction,
               screen: :profile,
               mode: :screen,
               boundary: :boundary,
               payload: %{profile: %{display_name: "Pascal"}}
             )

    assert translation.source == :canonical
    assert translation.runtime_event == "submit:save_profile"
    assert %Signal{} = translation.signal

    assert {:ok, runtime_action} = LiveUi.Signals.to_runtime_action(translation.signal)

    assert runtime_action.family == :submit
    assert runtime_action.intent == :save_profile
    assert runtime_action.runtime_event == "submit:save_profile"
    assert runtime_action.payload.profile == %{display_name: "Pascal"}
    assert runtime_action.payload.mapping == %{profile: :profile_form_data}
  end
end
