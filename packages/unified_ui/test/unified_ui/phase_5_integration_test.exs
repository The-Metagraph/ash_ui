defmodule UnifiedUi.Phase5IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Reference, as: IURReference
  alias UnifiedUi.{Compiler, Parity}

  defmodule IntegratedWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:integrated_workspace)
      title("Integrated Workspace")
      authored_ref([:integration, :integrated_workspace])
      tags([:integration, :phase_5])
    end

    themes do
      default_theme(:workspace)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end

        semantic_role do
          id(:primary_text)
          value(named_color(:white))
        end

        component_style do
          id(:panel_shell)
          component(:box)

          style(
            style_value(
              background: token_ref(:surface),
              foreground: role_ref(:primary_text)
            )
          )
        end
      end
    end

    composition do
      root(:integrated_workspace_root)
      mode(:screen)

      box :shell do
        theme_ref(:workspace)
        style_refs([:panel_shell])

        text :headline do
          value("Phase 5 integration")
        end

        button :save_button do
          label("Save")
          interaction_refs([:save_profile])
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:shell)
        trigger_ref(:save_button)
        visible?(true)
        confirm_intent(:save_profile)
      end

      scroll_bar :workspace_scroll do
        target_ref(:shell)
        position(8)
        viewport_size(24)
        content_size(240)
      end
    end

    signals do
      namespace(:workspace)

      data_binding do
        id(:profile_data)
        path([:profile])
        scope([:screen])
        default(%{display_name: ""})
      end

      interaction do
        id(:save_profile)
        family(:submit)
        intent(:save_profile)
        source_context(element_id: :save_button, scope: :screen)
        target_intent(binding: :profile_data, entity: :profile)
        payload_mapping(profile: binding_ref(:profile_data))
        binding_refs([:profile_data])
      end
    end
  end

  test "produces deterministic canonical output and stable signal summaries for equivalent authored input" do
    {:ok, result} = Compiler.compile(IntegratedWorkspace)
    {:ok, result_again} = Compiler.compile(IntegratedWorkspace)

    assert IURReference.snapshot(result.iur) == IURReference.snapshot(result_again.iur)

    assert Compiler.listing(IntegratedWorkspace).signals == %{
             ids: [:save_profile],
             families: [:submit],
             intents: [:save_profile],
             source_element_ids: [:save_button],
             target_bindings: [:profile_data]
           }
  end

  test "exposes deterministic inspection output and authored traceability without runtime services" do
    inspection = Compiler.inspection(IntegratedWorkspace)
    rendered = Compiler.render_inspection(IntegratedWorkspace)
    validation = Parity.validate_module(IntegratedWorkspace)

    assert UnifiedUi.required_runtime_services() == []
    assert inspection.summary.identity_id == :integrated_workspace

    assert inspection.listing.authored.authored_ids == [
             :headline,
             :save_button,
             :settings_dialog,
             :shell,
             :workspace_scroll
           ]

    assert Enum.any?(inspection.listing.trace.authored_to_compiled, fn trace ->
             trace == %{authored_id: :shell, compiled_id: :shell, type: :layout, kind: :box}
           end)

    assert inspection.render_tree ==
             String.trim_trailing("""
             - integrated_workspace_root [composite:screen]
               @default
                 - shell [layout:box]
                   @default
                     - headline [widget:text]
                   @default
                     - save_button [widget:button]
               @default
                 - settings_dialog [layer:dialog]
                   @content
                     - shell [layout:box]
                       @default
                         - headline [widget:text]
                       @default
                         - save_button [widget:button]
               @default
                 - workspace_scroll [widget:scroll_bar]
             """)

    assert rendered =~ "UnifiedUi compiler inspection"
    assert rendered =~ "trace authored->compiled:"
    assert validation.valid?
    assert validation.deterministic?
    assert validation.diagnostics == []
  end

  test "parity validation reports actionable diagnostics for canonical gaps" do
    gap_catalog = %{Parity.catalog() | advanced_widgets: []}

    assert {:error, issues} = Parity.validate(gap_catalog)

    assert Enum.any?(
             issues,
             &(&1.category == :advanced_widgets and &1.kind == :missing_in_unified_ui)
           )

    report = Parity.validation_report(Parity.example_modules(), gap_catalog)

    refute report.valid?
    refute report.parity.synchronized?
    assert report.example_compilation.all_valid?
    assert report.example_compilation.deterministic?

    summary = Parity.validation_summary(report)
    assert summary =~ "overall valid?: false"
    assert summary =~ "advanced_widgets"
  end

  test "rejects renderer-local signal leakage during authored validation" do
    assert_compile_dsl_error(
      """
      identity do
        id(:leaky_workspace)
        authored_ref([:integration, :leaky_workspace])
      end

      composition do
        root(:leaky_workspace_root)
        mode(:screen)
      end

      signals do
        interaction do
          id(:bad_click)
          family(:click)
          intent(:save_profile)
          source_context(element_id: :shell, phx_click: "save")
        end
      end
      """,
      "renderer-local key :phx_click is not allowed"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    code = """
    defmodule #{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """

    [{module, _bytecode}] = Code.compile_string(code)
    module
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
