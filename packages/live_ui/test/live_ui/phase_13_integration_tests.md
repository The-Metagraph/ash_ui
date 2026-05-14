# Phase 13 Integration Tests

## Test Scenarios

### 1. Data Dashboard Integration
**Test**: Data and feedback widgets compose correctly in dashboard screens

Verifies that:
- Status widgets can display dashboard state
- Table widgets display structured data
- Progress widgets show completion status
- Widget boundaries are preserved across nested compositions
- Styling attributes (tone, variant) propagate correctly

### 2. Document Viewer Integration
**Test**: Document and log widgets compose correctly in viewer screens

Verifies that:
- MarkdownViewer widgets render document content
- LogViewer widgets display activity logs
- Widget boundaries are preserved across nested compositions
- Content is correctly rendered through component boundaries

### 3. Widget Identity Preservation for Data Widgets
**Test**: Widget identities are stable across re-renders

Verifies that:
- Widget identity keys include correct mode (native vs canonical)
- Widget identity keys include path for nested widgets
- Widget identity is stable across multiple renders

### 4. Widget Identity Preservation for Feedback Widgets
**Test**: Widget identities are stable across re-renders

Verifies that:
- Widget identity keys include correct mode (native vs canonical)
- Widget identity keys include path for nested widgets
- Widget identity is stable across multiple renders

### 5. Event Routing Through Data Widget Boundaries
**Test**: Widget-targeted events route through the runtime correctly

Verifies that:
- Selection events on lists route to the correct component
- Click events on table rows route correctly
- Event routing preserves widget identity

### 6. Styling Propagation Through Feedback Widgets
**Test**: Styling attributes propagate through widget boundaries

Verifies that:
- Tone and variant styling are preserved
- Style attributes render correctly in HTML
- Styling propagates through nested compositions

### 7. Bounded Local State for Data Widgets
**Test**: Data widgets support bounded local state

Verifies that:
- Local state keys are defined for list, table, and tree_view
- Widgets support mountable component boundaries
- Local state is scoped to component boundaries

### 8. Bounded Local State for Feedback Widgets
**Test**: Feedback widgets support bounded local state

Verifies that:
- Local state keys are defined for progress and gauge
- Widgets support mountable component boundaries
- Local state is scoped to component boundaries
