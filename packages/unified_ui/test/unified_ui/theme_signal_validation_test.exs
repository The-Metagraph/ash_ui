defmodule UnifiedUi.ThemeSignalValidationTest do
  use ExUnit.Case, async: true

  test "rejects default_theme values that do not reference a declared theme" do
    assert_compile_dsl_error(
      """
      identity do
        id(:missing_theme_screen)
      end

      composition do
        root(:missing_theme_root)
      end

      themes do
        default_theme(:workspace)

        theme do
          id(:fallback)

          palette_color do
            id(:surface)
            color(named_color(:black))
          end
        end
      end
      """,
      "themes.default_theme must reference a declared theme id"
    )
  end

  test "rejects invalid style references and unsupported state variants" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_style_screen)
      end

      composition do
        root(:invalid_style_root)

        button :primary do
          label("Primary")
          theme_ref(:workspace)
          style_refs([:missing_component])

          style(
            style_value(
              state_variants: %{
                hovered: style_value(border_color: named_color(:cyan))
              }
            )
          )
        end
      end

      themes do
        default_theme(:workspace)

        theme do
          id(:workspace)

          palette_color do
            id(:surface)
            color(named_color(:black))
          end
        end
      end
      """,
      "style_refs must reference declared component styles"
    )
  end

  test "rejects invalid style opacity values" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_opacity_screen)
      end

      composition do
        root(:invalid_opacity_root)

        box :shell do
          style(
            style_value(
              visibility: %{opacity: 2}
            )
          )
        end
      end
      """,
      "visibility.opacity must be between 0.0 and 1.0"
    )
  end

  test "rejects empty binding paths and renderer-local signal keys" do
    assert_compile_dsl_error(
      """
      identity do
        id(:invalid_signal_screen)
      end

      composition do
        root(:invalid_signal_root)
      end

      signals do
        data_binding do
          id(:bad_binding)
          path([])
        end
      end
      """,
      "binding path must not be empty"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:renderer_local_signal_screen)
      end

      composition do
        root(:renderer_local_signal_root)
      end

      signals do
        interaction do
          id(:bad_interaction)
          family(:click)
          intent(:save_profile)
          source_context(phx_click: \"save\")
        end
      end
      """,
      "renderer-local key :phx_click is not allowed"
    )
  end

  test "rejects unknown binding refs in interactions and node signal refs" do
    assert_compile_dsl_error(
      """
      identity do
        id(:unknown_binding_ref_screen)
      end

      composition do
        root(:unknown_binding_ref_root)

        button :save_button do
          label("Save")
          interaction_refs([:save_profile])
        end
      end

      signals do
        interaction do
          id(:save_profile)
          family(:submit)
          intent(:save_profile)
          payload_mapping(profile: binding_ref(:missing_binding))
        end
      end
      """,
      "payload mapping references unknown binding"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:unknown_interaction_ref_screen)
      end

      composition do
        root(:unknown_interaction_ref_root)

        button :save_button do
          label("Save")
          interaction_refs([:missing_interaction])
        end
      end
      """,
      "interaction_refs must reference declared interactions"
    )
  end

  test "rejects host-route leakage and malformed canonical navigation targets" do
    assert_compile_dsl_error(
      """
      identity do
        id(:host_route_navigation_screen)
      end

      composition do
        root(:host_route_navigation_root)
      end

      signals do
        interaction do
          id(:navigate_activity)
          family(:navigation)
          intent(:navigate_activity)
          target_intent(binding: :active_tab, route: :activity)
        end
      end
      """,
      "canonical navigation must not declare host-route key :route"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:missing_screen_target_screen)
      end

      composition do
        root(:missing_screen_target_root)
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
        id(:invalid_modal_navigation_screen)
      end

      composition do
        root(:invalid_modal_navigation_root)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :open_modal, modal: :settings_dialog, screen: :settings)
        end
      end
      """,
      "unsupported fields [:screen] for navigation action :open_modal"
    )
  end

  test "rejects url-like and runtime-module navigation identifiers" do
    assert_compile_dsl_error(
      """
      identity do
        id(:url_navigation_screen)
      end

      composition do
        root(:url_navigation_root)
      end

      signals do
        interaction do
          id(:open_settings)
          family(:navigation)
          intent(:open_settings)
          target_intent(action: :navigate_to, screen: \"/settings\")
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
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.ThemeSignalValidationTest.#{module_name} do
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
