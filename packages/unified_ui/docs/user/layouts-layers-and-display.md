# Layouts, Layers, and Display

`UnifiedUi` separates ordinary layout from layered presentation and display
systems. That distinction matters because layout children, overlays, viewports,
and canvas surfaces compile into different canonical `UnifiedIUR` constructs.

## Layout Containers

The main layout entities are:

- `box`: generic container
- `row`: horizontal flow
- `column`: vertical flow
- `grid`: row/column matrix
- `stack`: overlapping layout stack

These entities are recursive and can contain widgets from the foundational,
input, navigation, data, feedback, advanced, overlay, display, and canvas
families.

Example:

```elixir
column :dashboard do
  gap(:md)

  row :toolbar do
    gap(:sm)

    button :refresh do
      label("Refresh")
      action_intent(:refresh)
    end

    button :open_settings do
      label("Settings")
      action_intent(:open_settings)
    end
  end

  grid :content_grid do
    columns(2)
    gap(:md)
  end
end
```

## Layered and Overlay Constructs

Use the overlay family when one surface is positioned conceptually above
another:

- `dialog`
- `alert_dialog`
- `context_menu`
- `toast`
- `overlay`
- `absolute`

These constructs usually work by reference:

- `trigger_ref` points at the authored source of the interaction
- `content_ref` points at already-authored content
- `base_ref` / `layer_refs` assemble a layered scene

Example:

```elixir
box :settings_panel do
  text :title do
    value("Workspace settings")
  end
end

button :open_settings do
  label("Open settings")
  action_intent(:open_settings)
end

dialog :settings_dialog do
  title("Settings")
  content_ref(:settings_panel)
  trigger_ref(:open_settings)
  visible?(true)
end

overlay :workspace_overlay do
  base_ref(:dashboard)
  layer_refs([:settings_dialog])
  background_fill(:scrim)
end
```

## Display-System Constructs

Use the display family when the authored model needs scrolling, clipping,
resizing, or reference-based viewport behavior:

- `scroll_bar`
- `split_pane`
- `viewport`
- `scroll_region`

Example:

```elixir
split_pane :workspace_split do
  primary_ref(:sidebar)
  secondary_ref(:main_panel)
  ratio(0.3)
  orientation(:horizontal)
end

viewport :activity_viewport do
  content_ref(:activity_feed)
  width(80)
  height(24)
  offset({0, 4})
  clip?(true)
end
```

## Canvas

Use `canvas` when the authored surface needs explicit drawing operations rather
than ordinary layout-driven widgets.

```elixir
canvas :status_canvas do
  width(20)
  height(8)

  operations([
    [kind: :cell, position: {0, 0}, text: "S"],
    [kind: :fragment, position: {2, 1}, text: "SYNC"]
  ])
end
```

## Practical Modeling Rules

- Use layout entities for ordinary hierarchy.
- Use overlays when a surface conceptually layers on top of another.
- Use display constructs when a surface depends on clipping, scrolling, or pane splitting.
- Use references like `content_ref`, `target_ref`, `trigger_ref`, `base_ref`, and `layer_refs` instead of duplicating authored content.
- Keep leaf widgets as leaves; use layout containers when you need children.

For a full reference workflow, inspect
`UnifiedUi.Examples.OverlayWorkspace` and
`UnifiedUi.Examples.ThemedSignalWorkspace`.
