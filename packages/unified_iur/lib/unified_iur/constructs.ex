defmodule UnifiedIUR.Constructs do
  @moduledoc """
  Namespace anchor for canonical widget, layout, layering, styling, and theming
  construct families.
  """

  alias UnifiedIUR.{Container, Display, Forms, Layout, Widgets}

  @spec modules() :: %{
          container: module(),
          display: module(),
          forms: module(),
          layout: module(),
          widgets: module()
        }
  def modules do
    %{
      widgets: Widgets,
      container: Container,
      forms: Forms,
      layout: Layout,
      display: Display
    }
  end
end
