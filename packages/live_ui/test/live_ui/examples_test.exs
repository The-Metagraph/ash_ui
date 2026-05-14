defmodule LiveUi.ExamplesTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "public example catalog now exposes aligned focused ids only" do
    catalog = LiveUi.Examples.catalog()
    example_ids = Enum.map(catalog, & &1.id)

    assert :button in example_ids
    assert :table in example_ids
    assert :command_palette in example_ids
    assert :overlay in example_ids
    refute Enum.any?(example_ids, &String.starts_with?(Atom.to_string(&1), "native_"))
    refute Enum.any?(example_ids, &String.starts_with?(Atom.to_string(&1), "canonical_"))
    refute Enum.any?(example_ids, &String.ends_with?(Atom.to_string(&1), "_compare"))
  end

  test "public example lookup resolves aligned ids and rejects retired package-only ids" do
    assert {:ok, button} = LiveUi.Examples.find(:button)
    assert button.path == :aligned
    assert button.module == LiveUi.Examples.Aligned.Button

    assert {:ok, table} = LiveUi.Examples.find("table")
    assert table.path == :aligned

    assert :error = LiveUi.Examples.find(:native_display)
    assert :error = LiveUi.Examples.find("canonical_form")
    assert :error = LiveUi.Examples.find("styled_continuity_compare")
  end

  test "aligned examples keep native rendering and canonical review on the same ids" do
    assert {:ok, button} = LiveUi.Examples.find(:button)
    assert {:ok, button_canonical} = LiveUi.Examples.canonical_element(:button)

    native_html =
      render_component(
        fn assigns -> button.module.render(assigns) end,
        button.module.mount_defaults()
      )

    canonical_html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: button_canonical
      })

    assert native_html =~ "data-live-ui-widget=\"button\""
    assert canonical_html =~ "data-live-ui-widget=\"button\""
  end

  test "tooling exposes aligned example metadata" do
    example_ids = Enum.map(LiveUi.Tooling.examples(), & &1.id)

    assert :button in example_ids
    assert :checkbox in example_ids
    assert :table in example_ids
    assert :command_palette in example_ids
    refute :native_display in example_ids
  end
end
