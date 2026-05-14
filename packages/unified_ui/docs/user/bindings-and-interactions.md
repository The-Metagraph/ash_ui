# Bindings and Interactions

`UnifiedUi` models interactivity through canonical bindings and interactions.
The goal is to describe event meaning once, without coupling authored modules
to a specific runtime’s callback names or payload format.

## Signals Section

Signals live under:

```elixir
signals do
  namespace(:workspace)
  default_target(:session)
end
```

The section-level options are:

- `namespace`
- `default_target`
- `mode`

`mode` is canonical by default.

## Data Bindings

Use `data_binding` to describe authored state references:

```elixir
data_binding do
  id(:filters)
  path([:filters])
  scope([:screen])
  default(%{query: "", severity: :all})
end
```

Supported binding fields include:

- `id`
- `path`
- `scope`
- `default`
- `format`
- `source`
- `collection?`
- `depends_on`
- `derived`
- `summary`
- `metadata`

Widgets and forms then refer to those bindings by path or by id:

```elixir
form_builder :filters_form do
  binding_refs([:filters])
  interaction_refs([:filters_change, :filters_submit])
end

field :query_field do
  field_name(:query)
  value_path([:filters, :query])
end
```

## Interactions

Use `interaction` to describe canonical event meaning:

```elixir
interaction do
  id(:filters_submit)
  family(:submit)
  intent(:apply_filters)
  source_context(element_id: :filters_form, scope: :screen)
  target_intent(binding: :filters, action: :apply)
  payload_mapping(filters: binding_ref(:filters), action: :apply)
  binding_refs([:filters])
end
```

Supported interaction fields include:

- `id`
- `family`
- `intent`
- `source_context`
- `target_intent`
- `payload_mapping`
- `binding_refs`
- `summary`
- `metadata`

## Standard Interaction Families

The canonical interaction families currently supported are:

- `:click`
- `:change`
- `:submit`
- `:open`
- `:close`
- `:focus`
- `:selection`
- `:navigation`
- `:command`

## Canonical Navigation Model

`UnifiedUi` owns portable navigation intent, not host-router configuration.
For the full authoring guide, see [Canonical Navigation](canonical-navigation.md).

- Use `binding` plus `destination` when the user stays inside the current
  screen and only a local section, tab, or panel changes.
- Use `action` plus `screen` when the user transitions to another top-level
  screen.
- Use `action` plus `modal` when the user opens or closes a modal surface.
- Treat stacked modal flows as ordered modal transitions: each `open_modal`
  pushes a symbolic modal target, and targetless `close_modal` closes the
  topmost modal.
- Keep URL paths, Phoenix route helpers, browser-history directives, and
  runtime module names out of `target_intent`.

Runtimes still own resolution. A web runtime may map `screen: :settings` to a
route, `desktop_ui` may map it to a registered window-local screen, and
`terminal_ui` may map it to a screen swap or bounded history state.

## Common Patterns

### Form Change and Submit

```elixir
interaction do
  id(:filters_change)
  family(:change)
  intent(:update_filters)
  source_context(element_id: :filters_form, scope: :screen)
  target_intent(binding: :filters, entity: :dashboard)
  payload_mapping(filters: binding_ref(:filters), phase: :draft)
end
```

### In-Screen Navigation

```elixir
interaction do
  id(:navigate_activity)
  family(:navigation)
  intent(:navigate_dashboard)
  source_context(element_id: :dashboard_tabs)
  target_intent(binding: :active_tab, destination: :activity)
  payload_mapping(tab: binding_ref(:active_tab), destination: :activity)
end
```

### Screen Transition

```elixir
interaction do
  id(:open_settings_screen)
  family(:navigation)
  intent(:open_settings_screen)
  source_context(element_id: :settings_link, scope: :screen)
  target_intent(action: :navigate_to, screen: :settings, params: %{tab: :profile})
  payload_mapping(tab: :profile)
end
```

### Modal Transitions

```elixir
interaction do
  id(:open_settings)
  family(:navigation)
  intent(:open_settings_modal)
  source_context(element_id: :open_settings_button, scope: :screen)
  target_intent(action: :open_modal, modal: :settings_dialog, params: %{source: :button})
  payload_mapping(source: :button)
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

### Stacked Modal Transitions

Stacked modals do not require nested modal definitions. Author the second modal
as another `open_modal` transition, then use targetless `close_modal` when the
current top modal should close.

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

interaction do
  id(:close_top_modal)
  family(:navigation)
  intent(:close_top_modal)
  source_context(element_id: :close_top_modal_button, scope: :modal)
  target_intent(action: :close_modal, metadata: %{reason: :cancel})
  payload_mapping(reason: :cancel)
end
```

Focus trapping, backdrop behavior, and terminal degradation are runtime
responsibilities. The authored DSL only preserves the portable stack intent.

## Canonical, Not Renderer-Local

Authored interactions should describe meaning, not runtime mechanics.

Good:

- `family(:submit)`
- `target_intent(binding: :filters, action: :apply)`
- `payload_mapping(filters: binding_ref(:filters))`

Not part of the `UnifiedUi` DSL surface:

- `phx-click`
- `phx-submit`
- runtime-local event structs
- runtime-local payload envelope keys

## Review and Inspection

Inspect compiled signal output from `packages/unified-ui`:

```bash
mix unified_ui.inspect --example themed_signal_workspace
mix unified_ui.export --example themed_signal_workspace --format signals
```

Those workflows are the fastest way to confirm your authored bindings and
interactions remain canonical before handing the screen to a runtime package.
