defmodule LiveUi.Widgets.Foundational do
  @moduledoc """
  Reference surface for foundational native `live_ui` widgets.
  """

  @modules [
    LiveUi.Widgets.Text,
    LiveUi.Widgets.Label,
    LiveUi.Widgets.Image,
    LiveUi.Widgets.Icon,
    LiveUi.Widgets.Button,
    LiveUi.Widgets.Link,
    LiveUi.Widgets.Separator,
    LiveUi.Widgets.Spacer,
    LiveUi.Widgets.Content,
    LiveUi.Widgets.Container,
    LiveUi.Widgets.Box,
    LiveUi.Widgets.ScreenShell
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
