defmodule LiveUi.ThemeTest do
  use ExUnit.Case, async: true

  test "default theme exposes canonical and native component profiles" do
    theme = LiveUi.Theme.default()

    assert theme.id == :live_ui
    assert LiveUi.Theme.token(theme, [:surface, :panel]).background
    assert LiveUi.Theme.component_profile(theme, :button).tone == :accent

    assert LiveUi.Theme.component_profile(theme, :overlay_surface).attrs["data-live-ui-layered"] ==
             "true"
  end

  test "custom themes normalize canonical and native surfaces together" do
    theme =
      LiveUi.Theme.new(%{
        id: :workspace,
        defaults: %{emphasis: %{tone: :surface}},
        components: %{
          button: %{
            default: %{emphasis: %{tone: :accent}}
          }
        },
        native: %{
          components: %{
            button: %{
              tone: :accent,
              variant: :quiet,
              class: "workspace-button"
            }
          }
        }
      })

    assert theme.id == :workspace
    assert LiveUi.Theme.component_profile(theme, :button).variant == :quiet
    assert LiveUi.Theme.resolve_style(theme, :button, variant: :quiet).emphasis[:tone] == :accent
  end
end
