defmodule LiveUi.Examples.Aligned.Canonical do
  @moduledoc false

  alias UnifiedIUR.{Interaction, Layer}
  alias UnifiedIUR.Widgets.{Advanced, Data, Foundational, Input, Navigation}

  @supported_ids [
    :button,
    :checkbox,
    :command_palette,
    :context_menu,
    :link,
    :list,
    :menu,
    :pick_list,
    :radio_group,
    :select,
    :table,
    :tabs,
    :text_input,
    :toggle,
    :tree_view
  ]

  @spec supported_ids() :: [atom()]
  def supported_ids do
    @supported_ids
  end

  @spec supports?(atom() | String.t()) :: boolean()
  def supports?(id) do
    case normalize_id(id) do
      {:ok, example_id} -> example_id in @supported_ids
      :error -> false
    end
  end

  @spec element(atom() | String.t()) :: {:ok, UnifiedIUR.Element.t()} | {:error, term()}
  def element(id) do
    with {:ok, example_id} <- normalize_id(id),
         true <- example_id in @supported_ids do
      {:ok, build(example_id)}
    else
      false -> {:error, :canonical_review_not_supported}
      :error -> {:error, :unknown_example}
    end
  end

  @spec metadata(atom() | String.t()) :: {:ok, map()} | {:error, term()}
  def metadata(id) do
    with {:ok, example_id} <- normalize_id(id),
         true <- example_id in @supported_ids do
      {:ok,
       %{
         id: example_id,
         review_mode: :canonical,
         preview_id: "aligned:canonical:#{example_id}",
         review_artifact: "live_ui/examples/#{example_id}/canonical"
       }}
    else
      false -> {:error, :canonical_review_not_supported}
      :error -> {:error, :unknown_example}
    end
  end

  defp build(:button) do
    Foundational.button("Run Widget Action",
      id: "aligned-button-button",
      action: [intent: :aligned_button_action]
    )
  end

  defp build(:link) do
    Foundational.link("Open widget docs", "#",
      id: "aligned-link-link",
      interaction: Interaction.navigation(intent: :aligned_link_navigation)
    )
  end

  defp build(:text_input) do
    Input.text_input(
      id: "aligned-text_input-text-input",
      name: :widget_name,
      value: "Live UI",
      placeholder: "Widget name",
      interaction:
        Interaction.change(
          intent: :aligned_text_input_change,
          binding: :widget_name
        )
    )
  end

  defp build(:toggle) do
    Input.toggle(
      id: "aligned-toggle-toggle",
      name: :widget_enabled,
      value: true,
      interaction:
        Interaction.change(
          intent: :aligned_toggle_change,
          binding: :widget_enabled
        )
    )
  end

  defp build(:checkbox) do
    Input.checkbox(
      id: "aligned-checkbox-toggle",
      name: :include_transport,
      value: true,
      interaction:
        Interaction.change(
          intent: :aligned_checkbox_change,
          binding: :include_transport
        )
    )
  end

  defp build(:select) do
    Input.select(
      [
        %{id: "foundational", value: "foundational", label: "Foundational"},
        %{id: "display", value: "display", label: "Display", selected?: true},
        %{id: "overlay", value: "overlay", label: "Overlay"}
      ],
      id: "aligned-select-select",
      name: :widget_category,
      interaction:
        Interaction.change(
          intent: :aligned_select_change,
          binding: :widget_category
        )
    )
  end

  defp build(:pick_list) do
    Input.pick_list(
      [
        %{id: "native", value: "native", label: "Native", selected?: true},
        %{id: "canonical", value: "canonical", label: "Canonical", selected?: true},
        %{id: "transport", value: "transport", label: "Transport"}
      ],
      id: "aligned-pick_list-select",
      name: :review_modes,
      interaction:
        Interaction.change(
          intent: :aligned_pick_list_change,
          binding: :review_modes
        )
    )
  end

  defp build(:radio_group) do
    Input.radio_group(
      [
        %{id: "native", value: "native", label: "Native", selected?: true},
        %{id: "canonical", value: "canonical", label: "Canonical"},
        %{id: "transport", value: "transport", label: "Transport"}
      ],
      id: "aligned-radio_group-select",
      name: :active_lane,
      interaction:
        Interaction.change(
          intent: :aligned_radio_group_change,
          binding: :active_lane
        )
    )
  end

  defp build(:menu) do
    Navigation.menu(
      [
        %{id: "overview", label: "Overview"},
        %{id: "insights", label: "Insights"},
        %{id: "settings", label: "Settings"}
      ],
      id: "aligned-menu-menu",
      active_item: "insights",
      interaction: Interaction.click(intent: :aligned_menu_click)
    )
  end

  defp build(:tabs) do
    Navigation.tabs(
      [
        %{id: "surface", label: "Surface"},
        %{id: "state", label: "State"},
        %{id: "signals", label: "Signals"}
      ],
      id: "aligned-tabs-tabs",
      active_item: "surface",
      interaction: Interaction.selection(intent: :aligned_tabs_selection)
    )
  end

  defp build(:list) do
    Data.list(
      [
        %{id: "button", label: "Button", description: "Primary action surface", selected?: true},
        %{id: "tabs", label: "Tabs", description: "Section navigation"},
        %{id: "toast", label: "Toast", description: "Transient feedback"}
      ],
      id: "aligned-list-list",
      selection_mode: :single,
      interaction: Interaction.selection(intent: :aligned_list_selection)
    )
  end

  defp build(:table) do
    Data.table(
      [
        %{id: "widget", label: "Widget"},
        %{id: "family", label: "Family"},
        %{id: "events", label: "Events"}
      ],
      [
        %{id: "button", cells: ["Button", "Content", "Click"], selected?: true},
        %{id: "tabs", cells: ["Tabs", "Navigation", "Navigate"]},
        %{id: "toast", cells: ["Toast", "Overlay", "None"]}
      ],
      id: "aligned-table-table",
      interaction: Interaction.selection(intent: :aligned_table_selection)
    )
  end

  defp build(:tree_view) do
    Data.tree_view(
      [
        %{
          id: "widgets",
          label: "Widgets",
          expanded?: true,
          children: [
            %{id: "content", label: "Content"},
            %{id: "overlay", label: "Overlay", selected?: true}
          ]
        }
      ],
      id: "aligned-tree_view-tree-view",
      selection_mode: :single,
      interaction: Interaction.selection(intent: :aligned_tree_selection)
    )
  end

  defp build(:context_menu) do
    Layer.context_menu(
      [
        %{id: "inspect", label: "Inspect"},
        %{id: "duplicate", label: "Duplicate"},
        %{id: "archive", label: "Archive"}
      ],
      id: "aligned-context_menu-context-menu",
      active_item: "inspect",
      anchor: %{x: 24, y: 24},
      interaction: Interaction.click(intent: :aligned_context_menu_click)
    )
  end

  defp build(:command_palette) do
    Advanced.command_palette(
      [
        %{id: "widgets", label: "Open widgets", active: true},
        %{id: "workspace", label: "Toggle workspace"},
        %{id: "validate", label: "Run validation"}
      ],
      id: "aligned-command_palette-command-palette",
      query: "wid",
      active_command: "widgets",
      interactions: [
        Interaction.change(
          intent: :aligned_command_palette_query,
          binding: :command_query
        ),
        Interaction.selection(intent: :aligned_command_palette_selection)
      ]
    )
  end

  defp normalize_id(id) when is_atom(id), do: {:ok, id}

  defp normalize_id(id) when is_binary(id) do
    {:ok, String.to_existing_atom(id)}
  rescue
    ArgumentError -> :error
  end
end
