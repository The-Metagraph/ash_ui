defmodule LiveUi.AlignedExamplesTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "aligned inventory matches the root examples directory one for one" do
    root_ids = LiveUi.Examples.repository_example_ids()
    aligned_ids = LiveUi.Examples.aligned_example_ids() |> Enum.sort()

    assert aligned_ids == root_ids
    refute Enum.any?(aligned_ids, &String.starts_with?(Atom.to_string(&1), "native_"))
    refute Enum.any?(aligned_ids, &String.starts_with?(Atom.to_string(&1), "canonical_"))
    refute Enum.any?(aligned_ids, &String.ends_with?(Atom.to_string(&1), "_compare"))
  end

  test "aligned catalog entries point at package-local live_ui screen modules" do
    for example <- LiveUi.Examples.aligned_catalog() do
      module_name = Atom.to_string(example.module)

      assert String.starts_with?(module_name, "Elixir.LiveUi.Examples.Aligned.")
      assert example.path == :aligned
      assert example.package_specialization?
      assert example.runtime_obligations.server_authoritative?
      assert example.runtime_obligations.direct_native?
      assert example.runtime_obligations.root_example_id == example.id
      assert is_list(example.runtime_obligations.native_widget_kinds)
      assert example.runtime_obligations.native_widget_kinds != []

      exported = example.module.__info__(:functions)

      assert {:render, 1} in exported
      assert {:id, 0} in exported
      assert {:metadata, 0} in exported
    end
  end

  test "aligned screens render native live_ui widget surfaces instead of root example wrappers" do
    for example <- LiveUi.Examples.aligned_catalog() do
      module = example.module
      html = render_component(fn assigns -> module.render(assigns) end, module.mount_defaults())

      assert html =~ ~s(data-live-ui-widget=)
      refute html =~ "UnifiedExamples."
      refute html =~ "data-unified-ui"
      refute html =~ "data-unified-iur"
    end
  end

  test "aligned screens keep representative specialized widget mappings visible" do
    assert {:ok, checkbox} = LiveUi.Examples.find_aligned(:checkbox)
    assert {:ok, overlay} = LiveUi.Examples.find_aligned("overlay")
    assert {:ok, field_group} = LiveUi.Examples.find_aligned(:field_group)
    assert {:ok, grid} = LiveUi.Examples.find_aligned(:grid)
    assert {:ok, pick_list} = LiveUi.Examples.find_aligned(:pick_list)

    checkbox_html =
      render_component(
        fn assigns -> checkbox.module.render(assigns) end,
        checkbox.module.mount_defaults()
      )

    overlay_html =
      render_component(
        fn assigns -> overlay.module.render(assigns) end,
        overlay.module.mount_defaults()
      )

    field_group_html =
      render_component(
        fn assigns -> field_group.module.render(assigns) end,
        field_group.module.mount_defaults()
      )

    grid_html =
      render_component(
        fn assigns -> grid.module.render(assigns) end,
        grid.module.mount_defaults()
      )

    pick_list_html =
      render_component(
        fn assigns -> pick_list.module.render(assigns) end,
        pick_list.module.mount_defaults()
      )

    assert checkbox_html =~ ~s(data-live-ui-widget="toggle")
    assert overlay_html =~ ~s(data-live-ui-widget="overlay-surface")
    assert field_group_html =~ ~s(data-live-ui-widget="field-group")
    assert grid_html =~ ~s(data-live-ui-widget="grid")
    assert pick_list_html =~ ~s(data-live-ui-widget="select")
  end
end
