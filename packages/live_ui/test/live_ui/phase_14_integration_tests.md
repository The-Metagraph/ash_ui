# Phase 14 Integration Tests

## Test Scenarios

### 1. Overlay Widget Integration
**Test**: Overlay widgets compose correctly in demo screens

Verifies that:
- Dialog widget renders with title and content
- Toast widget displays status messages
- Overlay boundaries are preserved in container composition
- Widget boundaries are rendered correctly

### 2. Operational Widget Integration
**Test**: Operational widgets compose correctly in monitoring screens

Verifies that:
- Status widget shows operational view state
- StreamWidget displays system stream entries
- ProcessMonitor shows process information
- Real-time update support is preserved

### 3. Display System Widget Integration
**Test**: Display widgets compose correctly in layout screens

Verifies that:
- Viewport widget provides scrollable container
- SplitPane widget divides content into regions
- Display system interactions work correctly
- Nested widget composition is preserved

### 4. Widget Identity Preservation for Overlay Widgets
**Test**: Widget identities include mode differentiation

Verifies that:
- Native and canonical modes produce different identity keys
- Widget identity is stable across renders
- Mode is correctly included in identity key

### 5. Widget Identity Preservation for Operational Widgets
**Test**: Widget identities include mode differentiation

Verifies that:
- Native and canonical modes produce different identity keys
- Widget identity is stable across renders
- Mode is correctly included in identity key

### 6. Widget Identity Preservation for Display Widgets
**Test**: Widget identities include mode differentiation

Verifies that:
- Native and canonical modes produce different identity keys
- Widget identity is stable across renders
- Mode is correctly included in identity key

### 7. Bounded Local State for Overlay Widgets
**Test**: Overlay widgets support local_state_keys

Verifies that:
- Dialog, ContextMenu, and Toast support local state
- Local state keys are defined for open, expanded, placement, etc.
- Widget lifecycle can manage bounded state

### 8. Bounded Local State for Operational Widgets
**Test**: Operational widgets support local_state_keys

Verifies that:
- StreamWidget, ProcessMonitor, and SupervisionTreeViewer support local state
- Local state keys are defined for real-time updates
- Widget lifecycle can manage bounded state

### 9. Bounded Local State for Display Widgets
**Test**: Display widgets support local_state_keys

Verifies that:
- Viewport, ScrollBar, and SplitPane support local state
- Local state keys are defined for scroll position, split ratio, etc.
- Widget lifecycle can manage bounded state
