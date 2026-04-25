defmodule AshUI.Examples.Phase20 do
  @moduledoc """
  Phase 20 example-suite definitions and path helpers.

  The standalone example directories under `examples/` are generated from these
  definitions so the checked-in projects, tests, and planning artifacts stay in
  sync while the advanced example families land section by section.
  """

  @type definition :: %{
          directory: String.t(),
          section: atom(),
          family: atom(),
          title: String.t(),
          subject_type: atom(),
          subject_props: map(),
          story_text: String.t(),
          signal_text: String.t(),
          seed_state: map(),
          preview_field: atom() | nil,
          preview_title: String.t() | nil,
          subject_binding: map() | nil,
          subject_action: map() | nil,
          subject_children: [map()],
          support_notice: String.t() | nil,
          notes: String.t() | nil
        }

  @sections [
    :overlay_layered_flows,
    :data_surfaces,
    :feedback_charts,
    :operational_monitoring,
    :runtime_realism,
    :integration
  ]

  defp overlay_definitions do
    [
      %{
        directory: "overlay",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Overlay Example",
        subject_type: :"custom:overlay",
        subject_props: %{
          title: "Inspection overlay",
          description: "A layered review surface that opens and dismisses through nested controls.",
          class: "ashui-example-overlay-shell"
        },
        story_text:
          "Meaningful Interaction Story: open the overlay, inspect the layered body copy, and dismiss it again without losing the shared Ash HQ shell around the example.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.enabled -> overlay visibility and status copy inside the explicit `custom:overlay` shell.",
        seed_state: %{
          id: "state-overlay",
          enabled: false,
          status: "Overlay closed until the nested trigger opens it."
        },
        preview_field: :status,
        preview_title: "Overlay state",
        subject_binding: %{
          id: :overlay_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :overlay_status_copy,
            "Overlay closed until the nested trigger opens it.",
            "ashui-example-surface-copy",
            0,
            field: :status,
            state_id: "state-overlay"
          ),
          state_button(
            :open_overlay_button,
            "Open overlay",
            "state-overlay",
            %{enabled: true, status: "Overlay opened from the nested trigger."},
            :actions,
            0
          ),
          state_button(
            :dismiss_overlay_button,
            "Dismiss",
            "state-overlay",
            %{enabled: false, status: "Overlay dismissed without leaving the review shell."},
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The overlay shell remains explicit `custom:overlay`; open and dismiss semantics stay on nested public button resources.",
        notes: "Uses body and action slots inside an example-only layered surface."
      },
      %{
        directory: "dialog",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Dialog Example",
        subject_type: :"custom:dialog",
        subject_props: %{
          title: "Confirm handoff",
          description: "A composed dialog shell with nested confirm and cancel controls.",
          class: "ashui-example-dialog-shell"
        },
        story_text:
          "Meaningful Interaction Story: confirm or cancel the dialog and verify that the result lands in persisted runtime state rather than living only inside ephemeral shell markup.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value and ExampleState.status -> dialog summary copy and preview stat.",
        seed_state: %{
          id: "state-dialog",
          enabled: true,
          selected_value: "awaiting decision",
          status: "Dialog is awaiting a handoff decision."
        },
        preview_field: :selected_value,
        preview_title: "Dialog result",
        subject_binding: %{
          id: :dialog_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :dialog_summary,
            "awaiting decision",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-dialog"
          ),
          slot_text(
            :footer,
            :dialog_status,
            "Dialog is awaiting a handoff decision.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-dialog"
          ),
          state_button(
            :confirm_dialog_button,
            "Confirm handoff",
            "state-dialog",
            %{
              enabled: false,
              selected_value: "confirmed",
              status: "Dialog confirmed and dismissed from the nested action row."
            },
            :actions,
            0
          ),
          state_button(
            :cancel_dialog_button,
            "Cancel",
            "state-dialog",
            %{
              enabled: false,
              selected_value: "cancelled",
              status: "Dialog cancelled and dismissed from the nested action row."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The dialog shell stays explicit `custom:dialog` while the decision buttons own the action declarations.",
        notes: "Uses body, actions, and footer slots."
      },
      %{
        directory: "alert_dialog",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Alert Dialog Example",
        subject_type: :"custom:alert_dialog",
        subject_props: %{
          title: "Escalation required",
          description: "A higher-severity confirmation flow with explicit recovery actions.",
          class: "ashui-example-alert-dialog-shell"
        },
        story_text:
          "Meaningful Interaction Story: acknowledge or defer the alert dialog and verify that the persisted status copy shows which recovery path the reviewer chose.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.selected_value -> alert decision summary plus dismissal state on the explicit `custom:alert_dialog` shell.",
        seed_state: %{
          id: "state-alert_dialog",
          enabled: true,
          selected_value: "pending acknowledgement",
          status: "Alert dialog is waiting for an escalation choice."
        },
        preview_field: :selected_value,
        preview_title: "Alert decision",
        subject_binding: %{
          id: :alert_dialog_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :alert_dialog_summary,
            "pending acknowledgement",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-alert_dialog"
          ),
          slot_text(
            :footer,
            :alert_dialog_status,
            "Alert dialog is waiting for an escalation choice.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-alert_dialog"
          ),
          state_button(
            :acknowledge_alert_dialog_button,
            "Acknowledge",
            "state-alert_dialog",
            %{
              enabled: false,
              selected_value: "acknowledged",
              status: "Alert acknowledged and the dialog closed through the destructive action."
            },
            :actions,
            0
          ),
          state_button(
            :defer_alert_dialog_button,
            "Keep for later",
            "state-alert_dialog",
            %{
              enabled: false,
              selected_value: "deferred",
              status: "Alert deferred and the dialog closed with a recovery note."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The alert-dialog shell remains explicit `custom:alert_dialog`; severity semantics stay readable in persisted state and nested action resources.",
        notes: "Uses the same layered shell contract with stronger alert copy."
      },
      %{
        directory: "context_menu",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Context Menu Example",
        subject_type: :"custom:context_menu",
        subject_props: %{
          title: "Row actions",
          description: "A focused action menu that opens around one review target.",
          class: "ashui-example-context-menu-shell"
        },
        story_text:
          "Meaningful Interaction Story: open the context menu, choose one action, and verify the chosen operation is reflected in persisted summary copy and preview state.",
        signal_text:
          "Canonical Signal Preview: nested menu button click -> ExampleState.selected_value -> context-menu summary text and footer status.",
        seed_state: %{
          id: "state-context_menu",
          enabled: true,
          selected_value: "inspect record",
          status: "Context menu is focused on one record-level action set."
        },
        preview_field: :selected_value,
        preview_title: "Chosen action",
        subject_binding: %{
          id: :context_menu_open,
          field: :enabled,
          target: "open",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          state_button(
            :inspect_record_button,
            "Inspect record",
            "state-context_menu",
            %{
              selected_value: "inspect record",
              status: "Inspect record selected from the nested context menu."
            },
            :menu,
            0,
            "ashui-example-nav-button"
          ),
          state_button(
            :reassign_owner_button,
            "Reassign owner",
            "state-context_menu",
            %{
              selected_value: "reassign owner",
              status: "Reassign owner selected from the nested context menu."
            },
            :menu,
            10,
            "ashui-example-nav-button"
          ),
          state_button(
            :add_watcher_button,
            "Add watcher",
            "state-context_menu",
            %{
              selected_value: "add watcher",
              status: "Add watcher selected from the nested context menu."
            },
            :menu,
            20,
            "ashui-example-nav-button"
          ),
          slot_text(
            :body,
            :context_menu_summary,
            "inspect record",
            "ashui-example-surface-copy",
            0,
            field: :selected_value,
            state_id: "state-context_menu"
          ),
          slot_text(
            :footer,
            :context_menu_status,
            "Context menu is focused on one record-level action set.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-context_menu"
          )
        ],
        support_notice:
          "The context-menu shell stays explicit `custom:context_menu`; the menu items remain plain button resources with persisted action outcomes.",
        notes: "Uses menu, body, and footer slots."
      },
      %{
        directory: "toast",
        section: :overlay_layered_flows,
        family: :overlay,
        title: "Toast Example",
        subject_type: :"custom:toast",
        subject_props: %{
          title: "Activity toast",
          description: "A transient-style notification shell driven by persisted runtime fields.",
          class: "ashui-example-toast-shell"
        },
        story_text:
          "Meaningful Interaction Story: trigger different toast variants and confirm the visible message and status copy update through nested controls instead of hard-coded shell text.",
        signal_text:
          "Canonical Signal Preview: nested button click -> ExampleState.current_value and ExampleState.status -> toast body copy and preview stat inside the explicit `custom:toast` shell.",
        seed_state: %{
          id: "state-toast",
          enabled: true,
          current_value: "No toast triggered yet.",
          status: "Toast example is waiting for a nested trigger."
        },
        preview_field: :current_value,
        preview_title: "Toast message",
        subject_binding: %{
          id: :toast_visible,
          field: :enabled,
          target: "visible",
          transform: %{}
        },
        subject_action: nil,
        subject_children: [
          slot_text(
            :body,
            :toast_copy,
            "No toast triggered yet.",
            "ashui-example-surface-copy",
            0,
            field: :current_value,
            state_id: "state-toast"
          ),
          slot_text(
            :footer,
            :toast_status,
            "Toast example is waiting for a nested trigger.",
            "ashui-example-surface-meta",
            0,
            field: :status,
            state_id: "state-toast"
          ),
          state_button(
            :send_success_toast_button,
            "Send success toast",
            "state-toast",
            %{
              current_value: "Deployment verified. Success toast delivered.",
              status: "Success toast triggered from the nested action row."
            },
            :actions,
            0
          ),
          state_button(
            :send_risk_toast_button,
            "Send risk toast",
            "state-toast",
            %{
              current_value: "Risk signal elevated. Recovery toast delivered.",
              status: "Risk toast triggered from the nested action row."
            },
            :actions,
            10,
            "ashui-example-secondary-cta"
          )
        ],
        support_notice:
          "The toast shell remains explicit `custom:toast`; trigger semantics stay on nested button resources and persisted runtime fields.",
        notes: "Uses body, footer, and action slots."
      }
    ]
  end

  defp state_button(key, label, state_id, params, slot, position, class \\ "ashui-example-primary-cta") do
    %{
      key: key,
      type: :button,
      props: %{
        label: label,
        variant: "secondary",
        class: class
      },
      slot: slot,
      position: position,
      actions: [
        %{
          id: String.to_atom("action_#{key}"),
          signal: :click,
          source: %{resource: "ExampleState", action: "update", id: state_id},
          target: "submit",
          transform: %{params: static_params(params)},
          metadata: %{intent: "update_example_state", success_message: "Layered state updated"}
        }
      ],
      children: []
    }
  end

  defp static_params(params) do
    Map.new(params, fn {key, value} ->
      {key, %{"from" => "static", "value" => value}}
    end)
  end

  defp slot_text(slot, key, content, class, position) do
    slot_text(slot, key, content, class, position, [])
  end

  defp slot_text(slot, key, content, class, position, opts) do
    text = %{
      key: key,
      type: :text,
      props: %{content: content, class: class},
      slot: slot,
      position: position,
      children: []
    }

    case Keyword.fetch(opts, :field) do
      {:ok, field} ->
        state_id = Keyword.fetch!(opts, :state_id)
        target = Keyword.get(opts, :target, "content")
        metadata = Keyword.get(opts, :metadata, %{owner: Atom.to_string(slot)})

        Map.put(text, :bindings, [
          %{
            id: :"#{key}_binding",
            source: %{resource: "ExampleState", field: field, id: state_id},
            target: target,
            binding_type: :value,
            transform: %{},
            metadata: metadata
          }
        ])

      :error ->
        text
    end
  end

  @doc """
  Returns every currently authored Phase 20 definition.
  """
  @spec definitions() :: [definition()]
  def definitions do
    overlay_definitions()
  end

  @doc """
  Returns the authored sections known to Phase 20.
  """
  @spec sections() :: [atom()]
  def sections, do: @sections

  @doc """
  Returns the definitions for one section.
  """
  @spec definitions_for(atom()) :: [definition()]
  def definitions_for(section) when section in @sections do
    Enum.filter(definitions(), &(&1.section == section))
  end

  @doc """
  Fetches one definition by directory name.
  """
  @spec definition!(String.t()) :: definition()
  def definition!(directory) when is_binary(directory) do
    Enum.find(definitions(), &(&1.directory == directory)) ||
      raise ArgumentError, "unknown Phase 20 example directory: #{inspect(directory)}"
  end

  @doc """
  Returns the app atom for a generated standalone example.
  """
  @spec app_atom(String.t()) :: atom()
  def app_atom(directory) when is_binary(directory) do
    String.to_atom("ash_ui_example_#{directory}")
  end

  @doc """
  Returns the root Elixir module for a generated standalone example.
  """
  @spec example_module(String.t()) :: module()
  def example_module(directory) when is_binary(directory) do
    directory
    |> Macro.camelize()
    |> then(&Module.concat([AshUIExamples, &1]))
  end

  @doc """
  Returns the canonical screen name for one example directory.
  """
  @spec screen_name(String.t()) :: String.t()
  def screen_name(directory) when is_binary(directory), do: "example/#{directory}"

  @doc """
  Returns the on-disk example project path for a directory.
  """
  @spec project_path(String.t()) :: String.t()
  def project_path(directory) when is_binary(directory) do
    Path.expand("../../../examples/#{directory}", __DIR__)
  end

  @doc """
  Returns every currently authored example directory.
  """
  @spec directories() :: [String.t()]
  def directories do
    definitions()
    |> Enum.map(& &1.directory)
    |> Enum.sort()
  end
end
