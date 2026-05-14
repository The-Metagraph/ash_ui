defmodule UnifiedUi.CanonicalNavigationIntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport
  alias UnifiedUi.{Compiler, Export, Signals, Tooling}

  defmodule CanonicalNavigationScreen do
    use UnifiedUi.Dsl

    identity do
      id(:canonical_navigation_screen)
      title("Canonical Navigation Screen")
      authored_ref([:integration, :canonical_navigation_screen])
      tags([:integration, :canonical_navigation])
    end

    composition do
      root(:canonical_navigation_root)
      mode(:screen)

      box :settings_panel do
        text :settings_title do
          value("Settings")
        end

        button :close_settings_button do
          label("Close settings")
          interaction_refs([:close_settings_modal])
        end
      end

      row :navigation_shell do
        tabs :dashboard_tabs do
          items(overview: "Overview", activity: "Activity")
          active_item(:overview)
          interaction_refs([:navigate_activity])
        end

        button :open_settings_screen_button do
          label("Go to settings screen")
          interaction_refs([:open_settings_screen])
        end

        button :replace_home_button do
          label("Replace with home")
          interaction_refs([:replace_with_home])
        end

        button :back_button do
          label("Back")
          interaction_refs([:go_back_history])
        end

        button :forward_button do
          label("Forward")
          interaction_refs([:go_forward_history])
        end

        button :open_settings_button do
          label("Open settings modal")
          interaction_refs([:open_settings_modal])
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:settings_panel)
        trigger_ref(:open_settings_button)
        visible?(true)
      end
    end

    signals do
      namespace(:workspace)

      data_binding do
        id(:active_tab)
        path([:navigation, :active_tab])
        scope([:screen])
        default(:overview)
      end

      interaction do
        id(:navigate_activity)
        family(:navigation)
        intent(:navigate_dashboard)
        source_context(element_id: :dashboard_tabs)
        target_intent(binding: :active_tab, destination: :activity)
        payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
      end

      interaction do
        id(:open_settings_screen)
        family(:navigation)
        intent(:open_settings_screen)
        source_context(element_id: :open_settings_screen_button, scope: :screen)
        target_intent(action: :navigate_to, screen: :settings, params: %{tab: :profile})
        payload_mapping(tab: :profile)
      end

      interaction do
        id(:replace_with_home)
        family(:navigation)
        intent(:replace_with_home)
        source_context(element_id: :replace_home_button, scope: :screen)
        target_intent(action: :replace_with, screen: :home, params: %{source: :launcher})
        payload_mapping(source: :launcher)
      end

      interaction do
        id(:go_back_history)
        family(:navigation)
        intent(:go_back_history)
        source_context(element_id: :back_button, scope: :screen)
        target_intent(action: :go_back, metadata: %{source: :header})
        payload_mapping(source: :header)
      end

      interaction do
        id(:go_forward_history)
        family(:navigation)
        intent(:go_forward_history)
        source_context(element_id: :forward_button, scope: :screen)
        target_intent(action: :go_forward, metadata: %{source: :header})
        payload_mapping(source: :header)
      end

      interaction do
        id(:open_settings_modal)
        family(:navigation)
        intent(:open_settings_modal)
        source_context(element_id: :open_settings_button, scope: :screen)
        target_intent(action: :open_modal, modal: :settings_dialog, params: %{source: :button})
        payload_mapping(source: :button)
      end

      interaction do
        id(:close_settings_modal)
        family(:navigation)
        intent(:close_settings_modal)
        source_context(element_id: :close_settings_button, scope: :screen)
        target_intent(action: :close_modal, modal: :settings_dialog, metadata: %{reason: :done})
        payload_mapping(reason: :done)
      end
    end
  end

  test "accepts canonical navigation descriptors across transitions, history, and local destinations" do
    summary = Signals.module_summary(CanonicalNavigationScreen)
    interactions = Map.new(summary.interactions, &{&1.id, &1})

    assert summary.namespace == :workspace
    assert Enum.map(summary.bindings, & &1.id) == [:active_tab]

    assert interactions[:navigate_activity].target_intent == %{
             binding: :active_tab,
             destination: :activity
           }

    assert interactions[:open_settings_screen].target_intent == %{
             action: :navigate_to,
             screen: :settings,
             params: %{tab: :profile}
           }

    assert interactions[:replace_with_home].target_intent == %{
             action: :replace_with,
             screen: :home,
             params: %{source: :launcher}
           }

    assert interactions[:go_back_history].target_intent == %{
             action: :go_back,
             metadata: %{source: :header}
           }

    assert interactions[:go_forward_history].target_intent == %{
             action: :go_forward,
             metadata: %{source: :header}
           }

    assert interactions[:open_settings_modal].target_intent == %{
             action: :open_modal,
             modal: :settings_dialog,
             params: %{source: :button}
           }

    assert interactions[:close_settings_modal].target_intent == %{
             action: :close_modal,
             modal: :settings_dialog,
             metadata: %{reason: :done}
           }

    assert Enum.into(summary.interactions, %{}, fn interaction ->
             {interaction.id, Signals.navigation_target_kind(interaction)}
           end) == %{
             navigate_activity: :local_destination,
             open_settings_screen: :screen_transition,
             replace_with_home: :replace_transition,
             go_back_history: :history_transition,
             go_forward_history: :history_transition,
             open_settings_modal: :modal_transition,
             close_settings_modal: :modal_transition
           }

    assert summary.navigation_descriptors == [
             %{
               id: :close_settings_modal,
               kind: :modal_transition,
               action: :close_modal,
               modal: :settings_dialog,
               metadata: %{reason: :done},
               modal_stack: %{
                 operation: :close,
                 target: :topmost_modal,
                 target_required?: false,
                 named_target_allowed?: true,
                 containment_required?: false,
                 stack_effect: :close_topmost_or_named_modal
               }
             },
             %{
               id: :go_back_history,
               kind: :history_transition,
               action: :go_back,
               metadata: %{source: :header}
             },
             %{
               id: :go_forward_history,
               kind: :history_transition,
               action: :go_forward,
               metadata: %{source: :header}
             },
             %{
               id: :navigate_activity,
               kind: :local_destination,
               binding: :active_tab,
               destination: :activity
             },
             %{
               id: :open_settings_modal,
               kind: :modal_transition,
               action: :open_modal,
               modal: :settings_dialog,
               params: %{source: :button},
               modal_stack: %{
                 operation: :push,
                 target: :symbolic_modal,
                 target_required?: true,
                 named_target_allowed?: true,
                 containment_required?: false,
                 stack_effect: :push_modal
               }
             },
             %{
               id: :open_settings_screen,
               kind: :screen_transition,
               action: :navigate_to,
               screen: :settings,
               params: %{tab: :profile}
             },
             %{
               id: :replace_with_home,
               kind: :replace_transition,
               action: :replace_with,
               screen: :home,
               params: %{source: :launcher}
             }
           ]
  end

  test "accepts targetless top-modal close descriptors" do
    assert [{module, _bytecode}] =
             compile_module("""
             identity do
               id(:targetless_close_screen)
             end

             composition do
               root(:targetless_close_root)
               mode(:screen)
             end

             signals do
               interaction do
                 id(:close_top_modal)
                 family(:navigation)
                 intent(:close_top_modal)
                 target_intent(action: :close_modal)
               end
             end
             """)

    assert [interaction] = Signals.interactions(module)

    assert Signals.navigation_descriptor(interaction) == %{
             id: :close_top_modal,
             kind: :modal_transition,
             action: :close_modal,
             modal_stack: %{
               operation: :close,
               target: :topmost_modal,
               target_required?: false,
               named_target_allowed?: true,
               containment_required?: false,
               stack_effect: :close_topmost_or_named_modal
             }
           }
  end

  test "rejects host-specific navigation leakage and malformed authored target shapes" do
    assert_compile_dsl_error(
      """
      identity do
        id(:history_leak_screen)
      end

      composition do
        root(:history_leak_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:bad_history)
          family(:navigation)
          intent(:bad_history)
          target_intent(history: :back)
        end
      end
      """,
      "canonical navigation must not declare host-route key :history"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:missing_screen_target_screen)
      end

      composition do
        root(:missing_screen_target_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :navigate_to)
        end
      end
      """,
      "navigation action :navigate_to requires fields [:screen]"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:route_helper_navigation_screen)
      end

      composition do
        root(:route_helper_navigation_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :navigate_to, screen: :settings, route_helper: :settings_path)
        end
      end
      """,
      "canonical navigation must not declare host-route key :route_helper"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:unsupported_navigation_action_screen)
      end

      composition do
        root(:unsupported_navigation_action_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:push_settings)
          family(:navigation)
          intent(:push_settings)
          target_intent(action: :push_screen, screen: :settings)
        end
      end
      """,
      "unsupported navigation action :push_screen"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:missing_modal_target_screen)
      end

      composition do
        root(:missing_modal_target_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :open_modal)
        end
      end
      """,
      "navigation action :open_modal requires fields [:modal]"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:url_navigation_screen)
      end

      composition do
        root(:url_navigation_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :navigate_to, screen: "/settings")
        end
      end
      """,
      "navigation screen must be a symbolic identifier and must not use URL or path syntax"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:module_navigation_screen)
      end

      composition do
        root(:module_navigation_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :navigate_to, screen: UnifiedUi.Signal)
        end
      end
      """,
      "navigation screen must be a symbolic identifier and must not reference a runtime module"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:modal_url_navigation_screen)
      end

      composition do
        root(:modal_url_navigation_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:close_modal)
          family(:navigation)
          intent(:close_modal)
          target_intent(action: :close_modal, modal: "/settings")
        end
      end
      """,
      "navigation modal must be a symbolic identifier and must not use URL or path syntax"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:ambiguous_local_navigation_screen)
      end

      composition do
        root(:ambiguous_local_navigation_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:ambiguous_navigation)
          family(:navigation)
          intent(:ambiguous_navigation)
          target_intent(binding: :active_tab)
        end
      end
      """,
      "navigation interaction must declare either a local destination pair (:binding and :destination) or a supported transition action"
    )
  end

  test "reports canonical navigation intent through export, tooling, and maintained examples" do
    assert {:ok, rendered_signals} = Export.module(CanonicalNavigationScreen, :signals)
    assert {:ok, rendered_signals_again} = Export.module(CanonicalNavigationScreen, :signals)

    assert rendered_signals == rendered_signals_again
    assert rendered_signals =~ "navigation_descriptors"
    assert rendered_signals =~ "navigate_activity"
    assert rendered_signals =~ "destination: :activity"
    assert rendered_signals =~ "action: :navigate_to"
    assert rendered_signals =~ "screen: :settings"
    assert rendered_signals =~ "action: :replace_with"
    assert rendered_signals =~ "action: :go_back"
    assert rendered_signals =~ "action: :go_forward"
    assert rendered_signals =~ "action: :open_modal"
    assert rendered_signals =~ "modal: :settings_dialog"
    assert rendered_signals =~ "action: :close_modal"

    assert {:ok, report} = Tooling.inspect_example(:themed_signal_workspace)
    assert {:ok, example_signals} = Export.example(:themed_signal_workspace, :signals)

    assert report.signal_coverage.interaction_target_kinds[:navigate_activity] ==
             :local_destination

    assert report.signal_coverage.interaction_target_kinds[:open_settings_screen] ==
             :screen_transition

    assert report.signal_coverage.interaction_target_kinds[:open_settings] == :modal_transition

    assert report.signal_coverage.interaction_target_kinds[:open_settings_confirmation] ==
             :modal_transition

    assert report.signal_coverage.interaction_target_kinds[:close_top_modal] ==
             :modal_transition

    assert report.signal_coverage.interaction_target_kinds[:close_settings_modal] ==
             :modal_transition

    assert Enum.find(report.signal_coverage.navigation_descriptors, &(&1.id == :open_settings))
           |> Map.fetch!(:modal_stack)
           |> Map.fetch!(:stack_effect) == :push_modal

    assert Enum.find(report.signal_coverage.navigation_descriptors, &(&1.id == :close_top_modal))
           |> Map.fetch!(:modal_stack)
           |> Map.fetch!(:target) == :topmost_modal

    assert example_signals =~ "open_settings_screen"
    assert example_signals =~ "screen: :settings"
    assert example_signals =~ "navigate_activity"
    assert example_signals =~ "destination: :activity"
    assert example_signals =~ "open_settings"
    assert example_signals =~ "open_settings_confirmation"
    assert example_signals =~ "close_top_modal"
    assert example_signals =~ "close_settings_modal"
    assert example_signals =~ "modal: :settings_dialog"
    assert example_signals =~ "modal: :settings_confirm_dialog"
  end

  test "keeps the user guidance aligned with canonical screen-transition authoring" do
    guide =
      Path.expand("../../docs/user/bindings-and-interactions.md", __DIR__)
      |> File.read!()

    assert guide =~ "`UnifiedUi` owns portable navigation intent, not host-router configuration."
    assert guide =~ "Use `binding` plus `destination`"
    assert guide =~ "Use `action` plus `screen`"
    assert guide =~ "Use `action` plus `modal`"
    assert guide =~ "targetless `close_modal` closes the"
    assert guide =~ "target_intent(binding: :active_tab, destination: :activity)"

    assert guide =~
             "target_intent(action: :navigate_to, screen: :settings, params: %{tab: :profile})"

    assert guide =~ "target_intent(action: :open_modal, modal: :settings_dialog"
    assert guide =~ "target_intent(action: :close_modal, metadata: %{reason: :cancel})"
    assert guide =~ "Focus trapping, backdrop behavior, and terminal degradation are runtime"
    refute guide =~ "target_intent(binding: :active_tab, route: :activity)"
  end

  test "maintained stacked-modal example compiles into portable navigation descriptors" do
    assert {:ok, result} = Compiler.compile(UnifiedUi.Examples.ThemedSignalWorkspace)
    assert {:ok, snapshot} = Export.example(:themed_signal_workspace, :snapshot)

    targets =
      Map.new(result.interactions, fn interaction ->
        {interaction.intent, interaction.target}
      end)

    assert targets[:open_settings_confirmation_modal] == %{
             navigation: %{
               action: :open_modal,
               kind: :modal_transition,
               modal_stack: modal_stack_push(),
               modal: :settings_confirm_dialog,
               params: %{from: :settings_dialog}
             }
           }

    assert targets[:close_top_modal] == %{
             navigation: %{
               action: :close_modal,
               kind: :modal_transition,
               modal_stack: modal_stack_close(),
               metadata: %{reason: :cancel}
             }
           }

    open_interaction =
      Enum.find(result.interactions, &(&1.intent == :open_settings_confirmation_modal))

    close_interaction = Enum.find(result.interactions, &(&1.intent == :close_top_modal))

    open_extensions = BoundaryTransport.boundary_extensions(open_interaction)
    close_extensions = BoundaryTransport.boundary_extensions(close_interaction)

    assert :ok = BoundaryTransport.validate_boundary_extensions(open_extensions)
    assert :ok = BoundaryTransport.validate_boundary_extensions(close_extensions)
    assert open_extensions.unified_iur_boundary_summary.modal_stack_effect == :push_modal

    assert close_extensions.unified_iur_boundary_summary.modal_stack_effect ==
             :close_topmost_or_named_modal

    assert close_extensions.unified_iur_boundary_summary.targetless?

    refute snapshot =~ "route_helper"
    refute snapshot =~ "stack_id"
  end

  test "compiles canonical navigation screens into stable IUR descriptors and deterministic review exports" do
    assert {:ok, first_result} = Compiler.compile(CanonicalNavigationScreen)
    assert {:ok, second_result} = Compiler.compile(CanonicalNavigationScreen)
    assert {:ok, first_snapshot} = Export.module(CanonicalNavigationScreen, :snapshot)
    assert {:ok, second_snapshot} = Export.module(CanonicalNavigationScreen, :snapshot)

    assert first_result.interactions == second_result.interactions
    assert first_snapshot == second_snapshot

    targets =
      Map.new(first_result.interactions, fn interaction ->
        {interaction.intent, interaction.target}
      end)

    assert targets[:open_settings_screen] == %{
             navigation: %{
               action: :navigate_to,
               kind: :screen_transition,
               params: %{tab: :profile},
               screen: :settings
             }
           }

    assert targets[:go_back_history] == %{
             navigation: %{
               action: :go_back,
               kind: :history_transition,
               metadata: %{source: :header}
             }
           }

    assert targets[:close_settings_modal] == %{
             navigation: %{
               action: :close_modal,
               kind: :modal_transition,
               modal_stack: modal_stack_close(),
               metadata: %{reason: :done},
               modal: :settings_dialog
             }
           }

    refute first_snapshot =~ "route:"
    refute first_snapshot =~ "\"/settings\""
  end

  defp modal_stack_push do
    %{
      operation: :push,
      target: :symbolic_modal,
      target_required?: true,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :push_modal
    }
  end

  defp modal_stack_close do
    %{
      operation: :close,
      target: :topmost_modal,
      target_required?: false,
      named_target_allowed?: true,
      containment_required?: false,
      stack_effect: :close_topmost_or_named_modal
    }
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.CanonicalNavigationIntegrationTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
