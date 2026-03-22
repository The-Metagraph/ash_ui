defmodule DesktopUI.Renderer do
  @moduledoc """
  Minimal desktop instruction renderer used by Ash UI in external renderer mode.
  """

  @spec render(map(), keyword()) :: {:ok, map()}
  def render(canonical_iur, opts \\ []) when is_map(canonical_iur) do
    {:ok, generate_instructions(canonical_iur, opts)}
  end

  defp generate_instructions(%{"type" => "screen"} = iur, opts) do
    %{
      "type" => "desktop_screen",
      "id" => iur["id"],
      "name" => iur["name"],
      "window" => %{
        "width" => Keyword.get(opts, :window_width, 1280),
        "height" => Keyword.get(opts, :window_height, 720),
        "resizable" => Keyword.get(opts, :window_resizable, true),
        "title" => Keyword.get(opts, :window_title, Map.get(iur, "name", "AshUI App")),
        "fullscreen" => Keyword.get(opts, :fullscreen, false),
        "borderless" => Keyword.get(opts, :borderless, false),
        "position" => Keyword.get(opts, :window_position, :center)
      },
      "menu_bar" => %{
        "enabled" => Keyword.get(opts, :native_menu_bar, true)
      },
      "platform" => %{
        "target" => Keyword.get(opts, :platform, :linux)
      },
      "events" => %{
        "handlers" => extract_handlers(iur)
      },
      "content" => Enum.map(iur["children"] || [], &generate_widget/1)
    }
  end

  defp generate_instructions(widget, _opts), do: generate_widget(widget)

  defp generate_widget(%{"type" => "row"} = widget) do
    %{
      "type" => "hbox",
      "id" => widget["id"],
      "spacing" => Map.get(widget["props"] || %{}, "spacing", 8),
      "align" => Map.get(widget["props"] || %{}, "align", :start),
      "children" => Enum.map(widget["children"] || [], &generate_widget/1)
    }
  end

  defp generate_widget(%{"type" => "column"} = widget) do
    %{
      "type" => "vbox",
      "id" => widget["id"],
      "spacing" => Map.get(widget["props"] || %{}, "spacing", 8),
      "align" => Map.get(widget["props"] || %{}, "align", :start),
      "children" => Enum.map(widget["children"] || [], &generate_widget/1)
    }
  end

  defp generate_widget(%{"type" => "text"} = widget) do
    %{
      "type" => "label",
      "id" => widget["id"],
      "text" => Map.get(widget["props"] || %{}, "content", ""),
      "font_size" => Map.get(widget["props"] || %{}, "size", 14),
      "font_weight" => Map.get(widget["props"] || %{}, "weight", :normal)
    }
  end

  defp generate_widget(%{"type" => "button"} = widget) do
    %{
      "type" => "button",
      "id" => widget["id"],
      "label" => Map.get(widget["props"] || %{}, "label", "Button"),
      "on_click" => Map.get(widget["props"] || %{}, "on_click"),
      "variant" => Map.get(widget["props"] || %{}, "variant", :primary)
    }
  end

  defp generate_widget(%{"type" => "input"} = widget) do
    %{
      "type" => "text_input",
      "id" => widget["id"],
      "name" => Map.get(widget["props"] || %{}, "name", "input"),
      "placeholder" => Map.get(widget["props"] || %{}, "placeholder", "")
    }
  end

  defp generate_widget(%{"type" => "checkbox"} = widget) do
    %{
      "type" => "checkbox",
      "id" => widget["id"],
      "name" => Map.get(widget["props"] || %{}, "name", "checkbox")
    }
  end

  defp generate_widget(%{"type" => "select"} = widget) do
    %{
      "type" => "dropdown",
      "id" => widget["id"],
      "name" => Map.get(widget["props"] || %{}, "name", "select"),
      "options" => Map.get(widget["props"] || %{}, "options", [])
    }
  end

  defp generate_widget(%{"type" => type} = widget) do
    %{
      "type" => "container",
      "id" => widget["id"],
      "widget_type" => type,
      "children" => Enum.map(widget["children"] || [], &generate_widget/1)
    }
  end

  defp extract_handlers(iur) do
    Enum.map(iur["bindings"] || [], fn binding ->
      %{
        "event" => binding["target"],
        "action" => get_in(binding, ["source", "action"]),
        "element_id" => binding["element_id"]
      }
    end)
  end
end
