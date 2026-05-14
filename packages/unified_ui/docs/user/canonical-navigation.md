# Canonical Navigation

`UnifiedUi` navigation describes portable UI intent. It does not describe a
Phoenix route, an Elm message, a desktop module, a terminal screen id, or a
browser-history operation directly.

Author navigation with the `:navigation` interaction family and a canonical
`target_intent`. The compiler lowers that intent into `UnifiedIUR` interaction
descriptors that each runtime can resolve through its own navigation model.

## When to Use Canonical Navigation

Use canonical navigation for three common cases:

| Case | Authoring Shape | Meaning |
| --- | --- | --- |
| In-screen movement | `binding` plus `destination` | Change a tab, panel, filter, or section inside the current screen |
| Screen transition | `action` plus `screen` | Move to another top-level screen |
| Modal transition | `action` plus `modal`, or targetless close | Open or close a modal using stack semantics |

Use normal `:click`, `:change`, `:submit`, `:selection`, or `:command`
interactions when the event is not navigation.

## In-Screen Navigation

In-screen navigation does not change the active top-level surface. It updates a
local binding or destination within the current screen.

```elixir
signals do
  data_binding do
    id(:active_tab)
    path([:navigation, :active_tab])
    scope([:screen])
    default(:overview)
  end

  interaction do
    id(:navigate_activity)
    family(:navigation)
    intent(:navigate_dashboard)
    source_context(element_id: :dashboard_tabs)
    target_intent(binding: :active_tab, destination: :activity)
    payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
  end
end
```

This stays canonical because the authored module says "activity destination",
not "push this route" or "send this renderer callback".

## Screen Transitions

Screen transitions use an `action` and a symbolic `screen`.

```elixir
interaction do
  id(:open_settings_screen)
  family(:navigation)
  intent(:open_settings_screen)
  source_context(element_id: :open_settings_screen_button, scope: :screen)
  target_intent(action: :navigate_to, screen: :settings, params: %{tab: :profile})
  payload_mapping(tab: :profile)
end
```

Supported screen actions:

| Action | Required Target | Meaning |
| --- | --- | --- |
| `:navigate_to` | `screen` | Navigate to a symbolic screen and add the current screen to history |
| `:replace_with` | `screen` | Replace the current screen without adding a history entry |
| `:go_back` | none | Move backward through runtime-owned history |
| `:go_forward` | none | Move forward through runtime-owned history |

Runtimes own symbolic resolution. For example, `live_ui` may resolve
`:settings` to a LiveView route, `desktop_ui` may resolve it through a screen
registry, and `terminal_ui` may realize it as a bounded terminal screen
transition.

## Modal Transitions

Modal navigation uses symbolic modal targets. Opening a modal pushes a modal
entry onto the active modal stack.

```elixir
interaction do
  id(:open_settings)
  family(:navigation)
  intent(:open_settings_modal)
  source_context(element_id: :open_settings_button, scope: :screen)
  target_intent(action: :open_modal, modal: :settings_dialog, params: %{source: :button})
  payload_mapping(source: :button)
end
```

Closing can be targetless or targeted.

```elixir
interaction do
  id(:close_top_modal)
  family(:navigation)
  intent(:close_top_modal)
  source_context(element_id: :close_top_modal_button, scope: :modal)
  target_intent(action: :close_modal, metadata: %{reason: :cancel})
  payload_mapping(reason: :cancel)
end

interaction do
  id(:close_settings_modal)
  family(:navigation)
  intent(:close_settings_modal)
  source_context(element_id: :close_settings_button, scope: :screen)
  target_intent(action: :close_modal, modal: :settings_dialog, metadata: %{reason: :done})
  payload_mapping(reason: :done)
end
```

Targetless `close_modal` means "close the topmost modal". Targeted
`close_modal` means "close the named open modal if the runtime supports named
close".

## Stacked Modals

Stacked modal flows do not require nested modal definitions. Author each modal
transition independently and let the canonical stack semantics preserve order.

```elixir
interaction do
  id(:open_settings_confirmation)
  family(:navigation)
  intent(:open_settings_confirmation_modal)
  source_context(element_id: :open_confirm_settings_button, scope: :modal)

  target_intent(
    action: :open_modal,
    modal: :settings_confirm_dialog,
    params: %{from: :settings_dialog}
  )

  payload_mapping(source: :settings_dialog)
end
```

The compiler records this as another `open_modal` transition. A targetless
`close_modal` after that closes `:settings_confirm_dialog` first and restores
`:settings_dialog` as the current modal.

## What Not to Put in Target Intent

Keep host and runtime details out of canonical navigation descriptors.

Do not author:

```elixir
target_intent(action: :navigate_to, route: "/settings")
target_intent(action: :navigate_to, router: MyApp.Router)
target_intent(action: :navigate_to, runtime_module: MyApp.SettingsLive)
target_intent(action: :open_modal, modal: :settings, stack_id: "runtime-stack")
```

Use symbolic canonical targets instead:

```elixir
target_intent(action: :navigate_to, screen: :settings)
target_intent(action: :open_modal, modal: :settings_dialog)
```

The forbidden host fields include URL/path fields, router/helper names,
runtime modules, browser route fields, and runtime-local modal stack ids.

## Inspect Navigation Output

Use the maintained `themed_signal_workspace` example as the reference for
screen, modal, and stacked modal navigation:

```bash
mix unified_ui.inspect --example themed_signal_workspace
mix unified_ui.export --example themed_signal_workspace --format signals
mix unified_ui.validate
```

The exported signal output should show canonical `:navigation` interactions,
symbolic screens or modals, and stack metadata for modal transitions without
host-router details.
