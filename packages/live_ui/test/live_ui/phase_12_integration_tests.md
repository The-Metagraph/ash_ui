# Phase 12 Integration Tests

## Test Scenarios

### 1. Foundational and Input Widget Integration
**Test**: Foundational and input widgets compose correctly in realistic screens

Verifies that:
- Foundational widgets (text, button, link, container) can be used together
- Input widgets (text_input, toggle) can be nested in forms
- Widget boundaries are preserved across nested compositions
- Styling attributes (tone, variant, state) propagate correctly

### 2. Navigation Widget Integration
**Test**: Navigation widgets compose correctly with foundational widgets

Verifies that:
- Menu and tabs can contain button widgets as items
- Command palette can be composed with input widgets
- Navigation events (click, navigate, patch) route correctly
- Active/disabled state management works

### 3. Form Widget Integration
**Test**: Form widgets compose correctly with input and foundational widgets

Verifies that:
- FormBuilder can compose multiple Field widgets
- FieldGroup can nest input widgets
- Submit events route correctly through widget boundaries
- Form validation state propagates correctly

### 4. Widget Identity Preservation
**Test**: Widget identities are stable across re-renders

Verifies that:
- Widget identity keys include correct mode (native vs canonical)
- Widget identity keys include path for nested widgets
- Widget identity is stable across multiple renders

### 5. Event Routing Through Widget Boundaries
**Test**: Widget-targeted events route through the runtime correctly

Verifies that:
- Click events on buttons route to the correct component
- Change events on inputs route correctly
- Navigation events (navigate, patch) route correctly
- Submit events on forms route correctly
