# Scenario Catalog (SCN-*)

This document catalogs all conformance scenarios used to validate Ash UI specifications.

## Purpose

Provides a comprehensive set of scenarios that validate the requirements defined in the specification contracts. Each scenario maps to one or more requirements and serves as acceptance criteria for implementation.

## Scenario Format

Each scenario includes:

- **SCN-ID**: Unique scenario identifier
- **Name**: Human-readable name
- **Requirements**: Linked REQ-* entries
- **Preconditions**: State before scenario execution
- **Steps**: Test execution steps
- **Expected Outcome**: What success looks like
- **Component**: Component being tested

## Scenarios

### Resource Definition Scenarios (SCN-001 to SCN-020)

#### SCN-001: Basic Element Resource Creation

**Requirements**: REQ-RES-001, REQ-RES-002

**Preconditions**:
- Ash UI application is running
- Database is migrated

**Steps**:
1. Define a UI.Element resource with required attributes
2. Execute Ash create action
3. Query the created element

**Expected Outcome**:
- Element is created with valid UUID
- All attributes are persisted correctly
- Element can be queried

#### SCN-002: Element Type Validation

**Requirements**: REQ-RES-002

**Preconditions**:
- UI.Element resource is defined

**Steps**:
1. Attempt to create element with invalid type
2. Attempt to create element with valid type

**Expected Outcome**:
- Invalid type returns validation error
- Valid type creates element successfully

#### SCN-003: Element Relationship Definition

**Requirements**: REQ-RES-003

**Preconditions**:
- UI.Element and UI.Screen resources exist

**Steps**:
1. Create a screen
2. Create elements belonging to screen
3. Query screen with associated elements

**Expected Outcome**:
- Elements load via relationship
- Foreign keys are correct
- Cascade delete works

#### SCN-004: Screen Resource Creation

**Requirements**: REQ-RES-001, REQ-SCREEN-001

**Preconditions**:
- Ash UI application is running

**Steps**:
1. Define a screen resource with `AshUI.Resource.DSL.Screen`
2. Persist it through `AshUI.Resource.Authority`
3. Query the stored `Screen` record

**Expected Outcome**:
- Screen is created with valid UUID
- Layout attribute is set
- `unified_dsl` stores a persisted authority snapshot
- Screen is queryable

#### SCN-005: Screen Element Composition

**Requirements**: REQ-SCREEN-003

**Preconditions**:
- Screen and element resources exist

**Steps**:
1. Define a screen resource with multiple related element resources
2. Declare composition semantics with `ui_relationships`
3. Compile the persisted screen and inspect the composed output

**Expected Outcome**:
- Related elements load in the declared order
- Child and companion placement is preserved
- Relationship semantics survive compilation

#### SCN-006: Binding Resource Creation

**Requirements**: REQ-BIND-001

**Preconditions**:
- An element resource is defined

**Steps**:
1. Declare a `ui_bindings` entry on an element resource
2. Persist a screen that composes that element
3. Compile or mount the screen and inspect the normalized binding metadata

**Expected Outcome**:
- Binding metadata is produced for the owning element
- Source and target are stored in normalized form
- Binding type is correct

#### SCN-007: Binding Value Type

**Requirements**: REQ-BIND-002

**Preconditions**:
- Element and binding resources exist

**Steps**:
1. Declare a value binding on an element resource
2. Bind to an Ash resource attribute
3. Evaluate the normalized binding at runtime

**Expected Outcome**:
- Binding evaluates to source value
- Changes propagate to element
- Type is preserved

#### SCN-008: Binding List Type

**Requirements**: REQ-BIND-002

**Preconditions**:
- Element and binding resources exist

**Steps**:
1. Declare a list binding on an element resource
2. Bind to an Ash resource collection
3. Evaluate the normalized binding at runtime

**Expected Outcome**:
- Binding evaluates to list
- Multiple items are rendered
- Empty list is handled

#### SCN-009: Element Action Type

**Requirements**: REQ-BIND-002, REQ-BIND-008

**Preconditions**:
- Element resource exists

**Steps**:
1. Declare an action through `ui_actions`
2. Trigger the element signal
3. Verify action execution

**Expected Outcome**:
- Action is executed on trigger
- Action receives event data
- Result updates UI

#### SCN-010: Source Resolution

**Requirements**: REQ-BIND-003

**Preconditions**:
- An element binding or action exists

**Steps**:
1. Declare a binding or action with a valid source map
2. Declare a binding or action with an invalid source map
3. Compile both

**Expected Outcome**:
- Valid source compiles successfully
- Invalid source produces error

#### SCN-011: Binding Transformation

**Requirements**: REQ-BIND-005

**Preconditions**:
- Binding resource exists
- Runtime context provides source data

**Steps**:
1. Evaluate a binding with a transformation configured
2. Write through a bidirectional binding with sanitization or validation
3. Verify the transformed result returned to the UI

**Expected Outcome**:
- Transformations apply deterministically
- Sanitization occurs before persistence
- Validation failures return structured errors

### Lifecycle Scenarios (SCN-021 to SCN-040)

#### SCN-021: Screen Mount

**Requirements**: REQ-SCREEN-002

**Preconditions**:
- Screen resource exists
- User is authenticated

**Steps**:
1. Navigate to screen route
2. LiveView mounts screen
3. Verify mount action executes

**Expected Outcome**:
- Mount action is called
- Screen transitions to mounted state
- Initial HTML is rendered

#### SCN-022: Screen Unmount

**Requirements**: REQ-SCREEN-002

**Preconditions**:
- Screen is mounted

**Steps**:
1. Navigate away from screen
2. LiveView unmounts screen
3. Verify unmount action executes

**Expected Outcome**:
- Unmount action is called
- Screen transitions to unmounted state
- Resources are cleaned up

#### SCN-023: Screen Update

**Requirements**: REQ-SCREEN-002

**Preconditions**:
- Screen is mounted

**Steps**:
1. Trigger event on screen
2. Handle event
3. Verify state update

**Expected Outcome**:
- Event is processed
- Screen transitions to updating state
- Screen returns to mounted state

#### SCN-024: Session Isolation

**Requirements**: REQ-SCREEN-006

**Preconditions**:
- Two users are logged in

**Steps**:
1. User A mounts screen
2. User B mounts same screen
3. User A modifies state
4. Verify User B state is unchanged

**Expected Outcome**:
- Sessions are isolated
- Changes don't leak between sessions

#### SCN-025: Concurrent Sessions

**Requirements**: REQ-SCREEN-006

**Preconditions**:
- Multiple users access system

**Steps**:
1. Mount 10 concurrent sessions
2. Perform actions in each
3. Verify all sessions work correctly

**Expected Outcome**:
- All sessions operate independently
- No session interference

#### SCN-026: Screen Data Binding

**Requirements**: REQ-SCREEN-004, REQ-BIND-006, REQ-BIND-007

**Preconditions**:
- Screen is mounted
- Runtime binding exists for a resource-backed field

**Steps**:
1. Load the screen with an evaluated binding
2. Update the underlying Ash resource
3. Verify the UI binding refreshes
4. Write a new value through the UI binding

**Expected Outcome**:
- Initial value is loaded into assigns
- Resource changes propagate back to the UI
- User edits persist through the binding

#### SCN-027: Screen Event Handling

**Requirements**: REQ-SCREEN-007, REQ-BIND-008

**Preconditions**:
- Screen includes event or action bindings

**Steps**:
1. Trigger a UI event
2. Route the event to the bound handler
3. Execute the bound action
4. Verify socket state and feedback are updated

**Expected Outcome**:
- Events are parsed correctly
- Action handlers receive expected parameters
- Success and error feedback are surfaced

### Compilation Scenarios (SCN-041 to SCN-060)

#### SCN-041: Resource Compilation

**Requirements**: REQ-COMP-001

**Preconditions**:
- UI resource is defined

**Steps**:
1. Compile resource to IUR
2. Verify pipeline stages execute
3. Verify IUR is generated

**Expected Outcome**:
- All pipeline stages execute
- Valid IUR is produced
- Compilation completes successfully

#### SCN-042: Schema Validation

**Requirements**: REQ-COMP-002

**Preconditions**:
- Resource with invalid schema exists

**Steps**:
1. Attempt to compile invalid resource
2. Verify validation error

**Expected Outcome**:
- Compilation fails
- Error message is descriptive
- Error includes resource location

#### SCN-043: IUR Generation

**Requirements**: REQ-COMP-003

**Preconditions**:
- Valid resource exists

**Steps**:
1. Compile resource to IUR
2. Verify IUR structure
3. Verify IUR serialization

**Expected Outcome**:
- IUR has valid structure
- IUR can be serialized
- IUR contains all required data

#### SCN-044: Resource Resolution

**Requirements**: REQ-COMP-004

**Preconditions**:
- Resource with references exists

**Steps**:
1. Compile resource with references
2. Verify all references are resolved
3. Test with circular reference

**Expected Outcome**:
- Valid references are resolved
- Circular references are detected
- Unresolved references produce errors

#### SCN-045: Normalization

**Requirements**: REQ-COMP-005

**Preconditions**:
- Two equivalent resources with different formats

**Steps**:
1. Compile both resources
2. Compare generated IUR

**Expected Outcome**:
- IURs are identical
- Normalization is deterministic

#### SCN-046: Compiler Cache

**Requirements**: REQ-COMP-007

**Preconditions**:
- Compiler cache is enabled

**Steps**:
1. Compile resource
2. Compile same resource again
3. Verify cache hit

**Expected Outcome**:
- First compile misses cache
- Second compile hits cache
- Cached IUR is identical

#### SCN-047: Cache Invalidation

**Requirements**: REQ-COMP-007

**Preconditions**:
- Resource is compiled and cached

**Steps**:
1. Modify resource
2. Compile resource again
3. Verify cache miss and recompile

**Expected Outcome**:
- Cache is invalidated
- Resource is recompiled
- New IUR is cached

#### SCN-048: Compilation Error Reporting

**Requirements**: REQ-COMP-008

**Preconditions**:
- Screen with invalid DSL or invalid compilation input exists

**Steps**:
1. Attempt to compile invalid UI input
2. Capture the returned error
3. Verify the error shape is descriptive

**Expected Outcome**:
- Compilation fails safely
- Error details identify the invalid input
- Calling code can branch on the returned error tuple

#### SCN-049: Incremental Compilation

**Requirements**: REQ-COMP-009

**Preconditions**:
- Dependency graph support is enabled
- Screen has dependent elements or bindings

**Steps**:
1. Build the incremental dependency graph
2. Change a dependent resource
3. Verify the compiler marks the screen as affected
4. Check circular dependency detection

**Expected Outcome**:
- Dependency graph records screen-element-binding relationships
- Changed resources trigger the expected recompilation target
- Circular dependencies are reported

#### SCN-050: Persisted Screen Authority Graph

**Requirements**: REQ-SCREEN-001, REQ-COMP-001

**Preconditions**:
- A screen resource module and related element resources are defined through `AshUI.Resource.DSL.*`
- UI storage is configured

**Steps**:
1. Persist the resource-authority screen through `AshUI.Resource.Authority`
2. Read the stored `Screen` record back from UI storage
3. Compile the stored authority payload into Ash UI IUR
4. Verify the canonical metadata preserves the screen resource module identity

**Expected Outcome**:
- The stored `unified_dsl` is a persisted resource-authority payload
- The screen compiles successfully after persistence
- Canonical metadata preserves authoring provenance

#### SCN-051: Relational Compiler Delegation

**Requirements**: REQ-COMP-001, REQ-COMP-007

**Preconditions**:
- A persisted resource-authority screen exists
- Compiler caching is enabled

**Steps**:
1. Compile the screen through `AshUI.Compiler`
2. Recompile with and without cache
3. Verify the compiler produces equivalent canonical output for the relational authority graph
4. Verify cache or incremental recompilation still behaves correctly

**Expected Outcome**:
- Ash UI compiles the persisted relational authority graph deterministically
- Cached and uncached compiles remain equivalent
- Incremental recompilation preserves valid output

#### SCN-052: Example Suite Resource-Authority Flows

**Requirements**: REQ-SCREEN-001, REQ-COMP-001

**Preconditions**:
- The maintained Phase 18-20 example apps are checked in
- Representative example apps can seed and persist screens through `AshUI.Resource.Authority`

**Steps**:
1. Boot representative example apps from each maintained example phase
2. Mount the seeded screen for each app through the normal LiveView integration path
3. Read the stored screen back from UI storage
4. Compile the stored screen and inspect the canonical metadata

**Expected Outcome**:
- Representative example apps boot as independent Mix projects
- Each seeded screen mounts successfully from the persisted authority record
- Compiled output preserves resource-authority provenance for the mounted screen

#### SCN-053: Relationship-Driven Composition Semantics

**Requirements**: REQ-RES-003, REQ-SCREEN-003, REQ-COMP-004

**Preconditions**:
- A screen resource with nested element relationships exists

**Steps**:
1. Compile a screen with child and companion element relationships
2. Inspect the composed IUR tree
3. Verify ordering, slotting, and nesting are derived from declared relationship semantics

**Expected Outcome**:
- Composition order matches the declared relationship semantics
- Nested elements remain attached to the correct owner
- Relationship-driven composition survives regeneration and compilation

#### SCN-054: Shared Example Theme Shell and Review Surfaces

**Requirements**: REQ-RENDER-002, REQ-RENDER-007, REQ-RENDER-008

**Preconditions**:
- The shared Ash HQ theme baseline assets are checked in
- Representative example apps from the maintained suite can render review output

**Steps**:
1. Render representative examples from the maintained example phases
2. Verify the shared shell classes, layout markers, and gradient tokens remain present
3. Verify the `Meaningful Interaction Story` and `Canonical Signal Preview` surfaces remain visible
4. Verify the example's primary subject still stays visible within the shared shell

**Expected Outcome**:
- The shared Ash HQ shell remains consistent across representative examples
- Review surfaces stay present and readable
- The example's primary subject remains foregrounded inside the shared shell

#### SCN-055: Example Suite Governance Drift Detection

**Requirements**: REQ-COMP-008, REQ-RENDER-008

**Preconditions**:
- The maintained example suite docs, release scripts, and validation helpers are checked in
- A writable temporary example-suite copy is available for drift injection

**Steps**:
1. Introduce stale directory or partial project-removal drift in a temporary example root
2. Introduce theme-shell drift in a temporary theme baseline asset
3. Run the maintained example-suite governance and release checks against the drifted copy
4. Inspect the returned failures and reported guidance

**Expected Outcome**:
- Directory drift is reported clearly
- Theme-shell drift is rejected
- Release and maintenance surfaces keep the example-suite validation workflow visible

### Rendering Scenarios (SCN-061 to SCN-080)

#### SCN-061: LiveView Rendering

**Requirements**: REQ-RENDER-002

**Preconditions**:
- IUR is compiled

**Steps**:
1. Render IUR with LiveView renderer
2. Verify output is valid HEEx
3. Verify event bindings

**Expected Outcome**:
- Output is valid HEEx
- Events are bound
- HTML is properly escaped

#### SCN-062: Elm-Backed Web Rendering

**Requirements**: REQ-RENDER-003

**Preconditions**:
- IUR is compiled

**Steps**:
1. Render IUR with static renderer
2. Verify output is valid HTML
3. Verify document structure

**Expected Outcome**:
- Output is valid HTML5
- Document has DOCTYPE
- No interpolation remains

#### SCN-063: Component Rendering

**Requirements**: REQ-RENDER-004

**Preconditions**:
- IUR with multiple elements exists

**Steps**:
1. Render individual component
2. Verify component output

**Expected Outcome**:
- Component renders independently
- Output includes component only

#### SCN-064: Binding Rendering

**Requirements**: REQ-RENDER-005

**Preconditions**:
- IUR with bindings exists

**Steps**:
1. Render IUR with bindings
2. Verify bindings are translated

**Expected Outcome**:
- Value bindings use LiveView assigns
- Action bindings create event handlers

#### SCN-065: Layout Rendering

**Requirements**: REQ-RENDER-007

**Preconditions**:
- Screen with layout exists

**Steps**:
1. Render screen with layout
2. Verify layout wraps content

**Expected Outcome**:
- Layout wraps screen content
- Layout elements are present

#### SCN-066: Error Rendering

**Requirements**: REQ-RENDER-006

**Preconditions**:
- Invalid IUR exists

**Steps**:
1. Attempt to render invalid IUR
2. Verify error output

**Expected Outcome**:
- Error output is produced
- Error details are included
- Renderer doesn't crash

#### SCN-067: Desktop Rendering

**Requirements**: REQ-RENDER-003B

**Preconditions**:
- Canonical IUR exists

**Steps**:
1. Render the IUR with the desktop renderer
2. Inspect the returned instruction payload
3. Verify the desktop-specific shape

**Expected Outcome**:
- Renderer returns desktop instruction data
- Instructions preserve the screen structure
- Desktop rendering succeeds without external packages

#### SCN-068: Renderer Selection

**Requirements**: REQ-RENDER-001

**Preconditions**:
- Renderer registry is initialized

**Steps**:
1. Resolve a LiveView request
2. Resolve an HTTP request
3. Apply an explicit renderer override

**Expected Outcome**:
- LiveView requests select the live renderer
- HTML requests select the web renderer
- Explicit overrides take precedence

#### SCN-069: Renderer Fallback

**Requirements**: REQ-RENDER-006

**Preconditions**:
- Renderer selection is configured
- External renderer packages may be unavailable

**Steps**:
1. Select a renderer with adapter fallback enabled
2. Force an unavailable renderer path
3. Verify alternative renderer fallback and telemetry

**Expected Outcome**:
- Adapter fallback is surfaced explicitly
- Alternative renderer fallback succeeds when configured
- Fallback behavior is observable

#### SCN-070: Asset Management

**Requirements**: REQ-RENDER-008

**Preconditions**:
- Web renderer is configured to include assets

**Steps**:
1. Render a screen with CSS and JavaScript enabled
2. Inspect the generated HTML head
3. Verify asset URLs are present

**Expected Outcome**:
- CSS references are emitted
- JavaScript references are emitted
- Asset paths use the configured base URL

### Authorization Scenarios (SCN-081 to SCN-100)

#### SCN-081: Screen Mount Authorization

**Requirements**: REQ-AUTH-002

**Preconditions**:
- Screen with authorization policy exists

**Steps**:
1. Unauthorized user attempts to mount screen
2. Authorized user mounts screen

**Expected Outcome**:
- Unauthorized user is redirected
- Authorized user mounts successfully

#### SCN-082: Action Authorization

**Requirements**: REQ-AUTH-003

**Preconditions**:
- Action with authorization policy exists

**Steps**:
1. Unauthorized user attempts action
2. Authorized user executes action

**Expected Outcome**:
- Unauthorized action is forbidden
- Authorized action executes

#### SCN-083: Field-Level Authorization

**Requirements**: REQ-AUTH-004

**Preconditions**:
- Resource with field policies exists

**Steps**:
1. Query resource with restricted fields
2. Verify authorized fields are present
3. Verify unauthorized fields are absent

**Expected Outcome**:
- Authorized fields are included
- Unauthorized fields are excluded

#### SCN-084: Binding Authorization

**Requirements**: REQ-AUTH-005

**Preconditions**:
- Binding to authorized resource exists

**Steps**:
1. Evaluate binding for authorized user
2. Evaluate binding for unauthorized user

**Expected Outcome**:
- Authorized user sees bound data
- Unauthorized user sees empty/filtered data

#### SCN-085: Role-Based Access

**Requirements**: REQ-AUTH-007

**Preconditions**:
- User with multiple roles exists

**Steps**:
1. User performs action requiring one role
2. User performs action requiring another role

**Expected Outcome**:
- Both actions succeed
- Roles are combined correctly

#### SCN-086: Resource Ownership Enforcement

**Requirements**: REQ-AUTH-006

**Preconditions**:
- Resource metadata includes ownership information

**Steps**:
1. Perform an operation as the owner
2. Perform the same operation as a different user
3. Repeat as an admin

**Expected Outcome**:
- Owner actions succeed
- Non-owner actions are forbidden
- Admin access bypasses ownership restrictions when allowed

#### SCN-087: Authorization Context

**Requirements**: REQ-AUTH-008

**Preconditions**:
- Authorization checks receive actor-aware context

**Steps**:
1. Execute an authorization check with actor context
2. Execute a resource operation with the same actor
3. Compare the authorization outcomes

**Expected Outcome**:
- Actor context propagates consistently
- Authorization decisions reflect the supplied context
- Resource and runtime checks agree on the result

#### SCN-088: Authorization Error Handling

**Requirements**: REQ-AUTH-009

**Preconditions**:
- Authorization denial path is reachable

**Steps**:
1. Trigger an unauthorized read, mount, or action
2. Inspect the returned error data
3. Verify user-facing error helpers

**Expected Outcome**:
- Forbidden operations return structured errors
- Errors contain actionable metadata
- User-facing helpers preserve the denial reason

#### SCN-089: Authorization Caching

**Requirements**: REQ-AUTH-010

**Preconditions**:
- Authorization runtime cache is initialized

**Steps**:
1. Cache an authorization decision
2. Re-run the same check
3. Invalidate the relevant cache entry
4. Verify the cached result expires

**Expected Outcome**:
- Repeated checks can be served from cache
- Invalidation clears affected cache entries
- Expired cache entries are not reused

### Observability Scenarios (SCN-101 to SCN-120)

#### SCN-101: Event Emission

**Requirements**: REQ-OBS-001, REQ-OBS-002

**Preconditions**:
- Telemetry handler is attached

**Steps**:
1. Execute operation
2. Verify event is emitted
3. Verify event schema

**Expected Outcome**:
- Event with correct name is emitted
- Measurements are present
- Metadata is correct

#### SCN-102: Span Context

**Requirements**: REQ-OBS-003

**Preconditions**:
- Distributed tracing is enabled

**Steps**:
1. Start operation with span
2. Create child operation
3. Verify span relationship

**Expected Outcome**:
- Parent span ID is set
- Trace ID propagates
- Span context is complete

#### SCN-103: Error Tracking

**Requirements**: REQ-OBS-006

**Preconditions**:
- Error monitoring is enabled

**Steps**:
1. Trigger error condition
2. Verify error event is emitted
3. Verify error context

**Expected Outcome**:
- Error event is emitted
- Error details are included
- Stack trace is present (dev)

#### SCN-104: Performance Monitoring

**Requirements**: REQ-OBS-007

**Preconditions**:
- Metrics collection is enabled

**Steps**:
1. Execute operation
2. Measure duration
3. Verify metric is recorded

**Expected Outcome**:
- Duration metric is present
- Metric is aggregatable
- Units are correct

#### SCN-105: Session Observability

**Requirements**: REQ-OBS-008

**Preconditions**:
- LiveView session is active

**Steps**:
1. Mount session
2. Perform actions
3. Unmount session
4. Verify lifecycle events

**Expected Outcome**:
- Mount event is emitted
- Action events are emitted
- Unmount event is emitted

#### SCN-106: Data Privacy Redaction

**Requirements**: REQ-OBS-012

**Preconditions**:
- Telemetry handler is attached

**Steps**:
1. Emit a telemetry event with sensitive metadata fields
2. Observe the metadata received by the handler
3. Compare the emitted and received payloads

**Expected Outcome**:
- Sensitive values are removed before handlers receive metadata
- Non-sensitive metadata remains intact
- Redaction does not change event delivery

### Extension Scenarios (SCN-121 to SCN-140)

#### SCN-121: Extension Registration

**Requirements**: REQ-EXT-001, REQ-EXT-005

**Preconditions**:
- Extension registry is initialized

**Steps**:
1. Register a custom widget definition
2. Register a custom layout definition
3. Query the extension registry

**Expected Outcome**:
- Widget registration succeeds
- Layout registration succeeds
- Registry reports both extensions as available

#### SCN-122: Extension Compilation

**Requirements**: REQ-EXT-002, REQ-EXT-003

**Preconditions**:
- Custom widget or layout is registered

**Steps**:
1. Compile a custom widget
2. Compile a custom layout
3. Inspect the compiled output

**Expected Outcome**:
- Registered extensions compile successfully
- Compiled output matches the extension contract
- Extension lifecycle hooks execute without crashing compilation

### Canonical Navigation Scenarios (SCN-141 to SCN-160)

#### SCN-141: Canonical Package And Element Boundary

**Requirements**: REQ-NAV-001, REQ-NAV-002, REQ-NAV-003

**Preconditions**:
- Upgraded Unified packages are available in the dependency graph
- Ash UI has an internal screen IUR to convert

**Steps**:
1. Convert Ash UI internal IUR through `AshUI.Rendering.IURAdapter`
2. Normalize the output with the upgraded Unified IUR API
3. Validate the normalized `%UnifiedIUR.Element{}` root
4. Dispatch the canonical root through upgraded runtime adapters

**Expected Outcome**:
- The output is a `%UnifiedIUR.Element{}` root
- Canonical normalization and validation pass
- Runtime adapters consume the canonical root without requiring legacy maps

#### SCN-142: Resource-Authored Navigation Intent

**Requirements**: REQ-NAV-004, REQ-NAV-005

**Preconditions**:
- An element or screen resource declares `navigation` in an action block

**Steps**:
1. Normalize the navigation intent
2. Compile the action through canonical IUR conversion
3. Inspect the generated canonical interaction

**Expected Outcome**:
- Supported canonical actions normalize successfully
- Navigation-only actions are valid without Ash action sources
- Canonical interactions preserve symbolic targets, params, payload mappings, and binding refs

#### SCN-143: Forbidden Host Runtime Navigation Fields

**Requirements**: REQ-NAV-006, REQ-NAV-007

**Preconditions**:
- A resource-authored navigation declaration includes host route or stack internals

**Steps**:
1. Normalize navigation intent containing a route or path field
2. Normalize modal navigation intent containing a runtime stack identifier
3. Compile modal close navigation without a stack identifier

**Expected Outcome**:
- Host route and path fields are rejected
- Runtime modal stack identifiers are rejected
- Modal close compiles as symbolic topmost or named modal intent

#### SCN-144: Runtime Adapter Navigation Transport

**Requirements**: REQ-NAV-008, REQ-NAV-009

**Preconditions**:
- A canonical IUR tree contains a navigation interaction
- The LiveView socket has an Ash UI navigation graph

**Steps**:
1. Render the canonical root through Live, Elm, and desktop adapters
2. Execute the navigation interaction through `AshUI.Runtime.Navigation`
3. Handle a LiveView action event that falls through to canonical navigation

**Expected Outcome**:
- Renderer adapters accept `%UnifiedIUR.Element{}` roots
- Symbolic targets resolve through the Ash UI graph
- The socket records `:ash_ui_navigation` and `:ash_ui_navigation_history`

#### SCN-145: Canonical Navigation Guide Coverage

**Requirements**: REQ-NAV-010

**Preconditions**:
- User and developer guides are present

**Steps**:
1. Inspect user guide coverage for resource-authored navigation intent
2. Inspect developer guide coverage for package boundaries and canonical renderer contracts
3. Inspect style intent guidance for semantic classes, variants, and host-owned CSS

**Expected Outcome**:
- User guides explain supported navigation actions and forbidden host runtime fields
- Developer guides explain `%UnifiedIUR.Element{}` output, validation, and runtime adapter namespaces
- Style guidance remains explicit about semantic resource intent versus host-owned theme implementation

### Canonical Widget Component Scenarios (SCN-161 to SCN-170)

#### SCN-161: Canonical Widget Catalog Boundary

**Requirements**: REQ-WIDGET-001

**Preconditions**:
- The upgraded Unified UI widget-component catalog is available
- Ash UI exposes the local `AshUI.WidgetComponents` boundary

**Steps**:
1. Compare Ash UI supported component kinds with `UnifiedUi.WidgetComponents.kinds/0`
2. Compare Ash UI compatibility aliases with `UnifiedUi.WidgetComponents.aliases/0`
3. Inspect component families through the Ash UI boundary

**Expected Outcome**:
- Ash UI mirrors the upstream catalog and aliases unless explicit exclusions are declared
- Component families remain visible to tests, docs, and examples
- Unknown names return the upstream diagnostic shape

#### SCN-162: Canonical Widget Admission And Aliases

**Requirements**: REQ-WIDGET-002, REQ-WIDGET-003

**Preconditions**:
- Resource-local element authoring and persisted DSL validation are available

**Steps**:
1. Validate every canonical component kind through `ui_element` validation
2. Validate every canonical component kind through persisted DSL validation
3. Resolve each compatibility alias through Ash UI canonical kind normalization

**Expected Outcome**:
- Cataloged components are accepted at resource and persisted DSL boundaries
- `phoenix_form` normalizes to `runtime_form_shell`
- `repeat` and `ui_relationship_repeat` normalize to `list_repeat`
- Renderer-facing output uses canonical names

#### SCN-163: Canonical Widget Conversion And Runtime Adapters

**Requirements**: REQ-WIDGET-004, REQ-WIDGET-005, REQ-WIDGET-006, REQ-WIDGET-007

**Preconditions**:
- Ash UI can build internal IUR containing representative component families
- Live, Elm, and desktop adapters are available

**Steps**:
1. Convert representative component families through `AshUI.Rendering.IURAdapter`
2. Normalize and validate the canonical `%UnifiedIUR.Element{}` output
3. Render the canonical root through Live, Elm, and desktop adapters
4. Inspect fallback output for preserved component identity

**Expected Outcome**:
- Component attributes use the expected Unified IUR namespaces
- Canonical validation passes
- Runtime adapters preserve or render component identity
- Fallback renderers emit structured diagnostics and safe text output

#### SCN-164: List Repeat Relationship Hydration

**Requirements**: REQ-WIDGET-008

**Preconditions**:
- A resource relationship declares repeat metadata
- The destination repeat element owns a `binding_type :list` binding

**Steps**:
1. Build a resource-authority payload for the repeat screen
2. Compile the payload through `AshUI.Compiler`
3. Convert the compiled IUR through canonical IUR conversion
4. Hydrate runtime list rows into the repeated row template

**Expected Outcome**:
- Repeat metadata is encoded in relationship composition
- The compiled node remains `list_repeat`
- Row-scoped props project row values into concrete children

#### SCN-165: Canonical Widget Guide And Example Coverage

**Requirements**: REQ-WIDGET-009

**Preconditions**:
- User guides, developer guides, and canonical component examples are present

**Steps**:
1. Inspect user guide coverage for canonical kinds and aliases
2. Inspect developer guide coverage for catalog ownership, validation, and fallback behavior
3. Inspect example coverage for each component family and relationship-owned list repeat

**Expected Outcome**:
- User guides list supported component names and aliases
- Developer guides explain catalog ownership and fallback boundaries
- Examples use canonical names instead of `custom:*` for cataloged components

#### SCN-166: Phase 31 Conformance And Drift Detection

**Requirements**: REQ-WIDGET-010

**Preconditions**:
- Phase 31 package, admission, conversion, runtime, repeat, docs, and integration tests exist

**Steps**:
1. Run the targeted Phase 31 test files
2. Run specs governance
3. Run guide governance
4. Run example-suite validation

**Expected Outcome**:
- Catalog drift, admission drift, conversion drift, renderer drift, repeat drift, and docs drift are caught before release

#### SCN-171: Rail Catalog Boundary

**Requirements**: REQ-RAIL-001, REQ-RAIL-002

**Preconditions**:
- Unified UI and Ash UI package catalogs are available
- `right_rail` is expected to remain in the layer shell and callout family

**Steps**:
1. Inspect canonical package catalogs and family metadata
2. Verify `doc_right_rail` is not admitted as canonical package vocabulary
3. Verify application-specific document rails are treated as compositions over `right_rail`

**Expected Outcome**:
- `right_rail` is the reusable canonical rail kind
- The component remains in the layer shell and callout family
- Document-specific rail names stay outside canonical aliases

#### SCN-172: Rail Unified Authoring And IUR Validation

**Requirements**: REQ-RAIL-003, REQ-RAIL-004, REQ-RAIL-007, REQ-RAIL-008

**Preconditions**:
- Unified UI DSL and Unified IUR constructors are available
- Rail examples include slots, active panel state, collapse state, and semantic actions

**Steps**:
1. Author `right_rail` through Unified UI DSL
2. Lower the DSL into canonical `%UnifiedIUR.Element{}` output
3. Validate rail attributes, slots, children, and semantic interactions

**Expected Outcome**:
- Unified UI emits canonical `right_rail` elements
- Unified IUR rejects malformed rail attributes
- Slots and interactions remain structured and host independent

#### SCN-173: Rail Ash Admission And Conversion

**Requirements**: REQ-RAIL-004, REQ-RAIL-005, REQ-RAIL-006

**Preconditions**:
- Ash resource and persisted DSL authoring paths are available
- Ash IUR conversion can produce renderer-facing Unified IUR

**Steps**:
1. Admit `right_rail` through resource and persisted DSL validation
2. Reject `doc_right_rail` unless explicitly authored as `custom:*`
3. Convert Ash-authored rail props into canonical rail attributes

**Expected Outcome**:
- Ash authoring accepts `right_rail` and rejects accidental app-specific canonical names
- Ash-owned metadata cannot overwrite canonical component or rail metadata
- Converted rails validate as canonical Unified IUR

#### SCN-174: Rail Runtime Renderer Support

**Requirements**: REQ-RAIL-007, REQ-RAIL-008, REQ-RAIL-009, REQ-RAIL-010

**Preconditions**:
- Live, Elm, and desktop renderer adapters are available
- A canonical rail includes children, slots, and semantic interaction data

**Steps**:
1. Render the rail through the Live UI adapter
2. Render or preserve the rail through Elm and desktop adapters
3. Inspect renderer output for canonical kind, slot, interaction, and diagnostic data

**Expected Outcome**:
- Live UI renders the rail natively
- Elm and desktop adapters preserve or diagnose the canonical kind explicitly
- Concrete theme and layout choices remain outside canonical attributes

#### SCN-175: Rail Documentation And Examples

**Requirements**: REQ-RAIL-011

**Preconditions**:
- User guide, developer guide, and canonical widget examples are available
- Document rail examples compose over canonical `right_rail`

**Steps**:
1. Inspect user guide coverage for `right_rail`
2. Inspect developer guide coverage for the canonical rail namespace and renderer behavior
3. Inspect example coverage for document-oriented rail composition

**Expected Outcome**:
- Documentation names `right_rail` as reusable canonical vocabulary
- Guides explain why `doc_right_rail` is application composition
- Examples emit canonical `right_rail` rather than app-specific canonical kinds

#### SCN-176: Phase 32 Conformance And Drift Detection

**Requirements**: REQ-RAIL-012

**Preconditions**:
- Phase 32 package, admission, conversion, runtime, docs, and example tests exist
- Specs governance is available

**Steps**:
1. Run the targeted Phase 32 test files
2. Run specs governance
3. Inspect the Phase 32 plan and contract traceability

**Expected Outcome**:
- Rail catalog, admission, conversion, renderer, docs, and examples drift is caught before release
- The implementation remains scoped to reusable canonical rail adoption
- Contract requirements are traceable to conformance scenarios

#### SCN-181: Workflow Progress Catalog Boundary

**Requirements**: REQ-WFPS-001, REQ-WFPS-002

**Preconditions**:
- Unified UI, Unified IUR, Ash UI, and Live UI package catalogs are available
- `workflow_progress_status_card` is expected to remain in the canonical workflow progress and status family

**Steps**:
1. Inspect canonical package catalogs and family metadata
2. Inspect widget discovery metadata for the Live UI native component
3. Verify app-specific workflow names are not introduced as canonical component kinds

**Expected Outcome**:
- `workflow_progress_status_card` is the shared canonical kind across packages
- The component remains in the workflow progress and status family
- No parallel workflow or workflow-summary family is introduced

#### SCN-182: Workflow Progress Unified Authoring And IUR Validation

**Requirements**: REQ-WFPS-003, REQ-WFPS-004, REQ-WFPS-007, REQ-WFPS-008

**Preconditions**:
- Unified UI DSL and Unified IUR constructors are available
- Workflow progress subject examples include progress, dependencies, and semantic interactions

**Steps**:
1. Author `workflow_progress_status_card` through Unified UI DSL
2. Lower the DSL into canonical `%UnifiedIUR.Element{}` output
3. Validate identity, progress, dependency, action, and interaction payloads

**Expected Outcome**:
- Unified UI emits canonical `workflow_progress_status_card` elements
- Unified IUR rejects malformed subject, dependency, action, and interaction data
- Dependency and interaction semantics stay structured and host independent

#### SCN-183: Workflow Progress Ash Admission And Conversion

**Requirements**: REQ-WFPS-004, REQ-WFPS-005, REQ-WFPS-006

**Preconditions**:
- Ash resource and persisted DSL authoring paths are available
- Ash IUR conversion can produce renderer-facing Unified IUR

**Steps**:
1. Admit `workflow_progress_status_card` through resource and persisted DSL validation
2. Convert Ash-authored card props into canonical `attributes.subject`
3. Validate converted output through Unified IUR

**Expected Outcome**:
- Ash authoring accepts the canonical component kind
- Ash-owned metadata cannot overwrite canonical component or subject metadata
- Converted cards validate as canonical Unified IUR

#### SCN-184: Workflow Progress Runtime Renderer Support

**Requirements**: REQ-WFPS-007, REQ-WFPS-008, REQ-WFPS-009, REQ-WFPS-010

**Preconditions**:
- Live, Elm, and desktop renderer adapters are available
- A canonical workflow progress card includes dependency and interaction data

**Steps**:
1. Render the card through the Live UI adapter
2. Render or preserve the card through Elm and desktop adapters
3. Inspect renderer output for canonical kind, dependency, interaction, and diagnostic data

**Expected Outcome**:
- Live UI renders the card natively
- Elm and desktop adapters preserve or diagnose the canonical kind explicitly
- Concrete theme and layout choices remain outside canonical attributes

#### SCN-185: Workflow Progress Documentation And Examples

**Requirements**: REQ-WFPS-010, REQ-WFPS-012

**Preconditions**:
- User guide, developer guide, and canonical widget examples are available
- Workflow progress examples include semantic dependencies and actions

**Steps**:
1. Inspect user guide coverage for `workflow_progress_status_card`
2. Inspect developer guide coverage for canonical subject attributes and renderer diagnostics
3. Inspect example coverage for reusable workflow status composition

**Expected Outcome**:
- Documentation names `workflow_progress_status_card` as reusable canonical vocabulary
- Guides preserve the theme, layout, and host-runtime boundary
- Examples avoid app-specific canonical component names

#### SCN-186: Phase 33 Conformance And Scope Hygiene

**Requirements**: REQ-WFPS-011, REQ-WFPS-012

**Preconditions**:
- Phase 33 package, admission, conversion, runtime, docs, and integration tests exist
- Specs governance is available

**Steps**:
1. Run the targeted Phase 33 test files
2. Run specs governance
3. Inspect the Phase 33 plan and contract traceability

**Expected Outcome**:
- Phase 33 drift is caught before release
- The implementation remains scoped to canonical workflow progress status adoption
- Contract requirements are traceable to conformance scenarios

## Scenario Index

| SCN ID | Name | Requirements | Component |
|---|---|---|---|
| SCN-001 | Basic Element Resource Creation | REQ-RES-001, REQ-RES-002 | UI.Element |
| SCN-002 | Element Type Validation | REQ-RES-002 | UI.Element |
| SCN-003 | Element Relationship Definition | REQ-RES-003 | UI.Element |
| SCN-004 | Screen Resource Creation | REQ-RES-001, REQ-SCREEN-001 | UI.Screen |
| SCN-005 | Screen Element Composition | REQ-SCREEN-003 | UI.Screen |
| SCN-006 | Binding Resource Creation | REQ-BIND-001 | UI.Binding |
| SCN-007 | Binding Value Type | REQ-BIND-002 | UI.Binding |
| SCN-008 | Binding List Type | REQ-BIND-002 | UI.Binding |
| SCN-009 | Element Action Type | REQ-BIND-002, REQ-BIND-008 | UI.Binding |
| SCN-010 | Source Resolution | REQ-BIND-003 | UI.Binding |
| SCN-011 | Binding Transformation | REQ-BIND-005 | Runtime |
| SCN-021 | Screen Mount | REQ-SCREEN-002 | Runtime |
| SCN-022 | Screen Unmount | REQ-SCREEN-002 | Runtime |
| SCN-023 | Screen Update | REQ-SCREEN-002 | Runtime |
| SCN-024 | Session Isolation | REQ-SCREEN-006 | Runtime |
| SCN-025 | Concurrent Sessions | REQ-SCREEN-006 | Runtime |
| SCN-026 | Screen Data Binding | REQ-SCREEN-004, REQ-BIND-006, REQ-BIND-007 | Runtime |
| SCN-027 | Screen Event Handling | REQ-SCREEN-007, REQ-BIND-008 | Runtime |
| SCN-041 | Resource Compilation | REQ-COMP-001 | Compiler |
| SCN-042 | Schema Validation | REQ-COMP-002 | Validator |
| SCN-043 | IUR Generation | REQ-COMP-003 | IUR Generator |
| SCN-044 | Resource Resolution | REQ-COMP-004 | Resolver |
| SCN-045 | Normalization | REQ-COMP-005 | Normalizer |
| SCN-046 | Compiler Cache | REQ-COMP-007 | Cache |
| SCN-047 | Cache Invalidation | REQ-COMP-007 | Cache |
| SCN-048 | Compilation Error Reporting | REQ-COMP-008 | Compiler |
| SCN-049 | Incremental Compilation | REQ-COMP-009 | Incremental Compiler |
| SCN-050 | Persisted Screen Authority Graph | REQ-SCREEN-001, REQ-COMP-001 | Authoring Persistence |
| SCN-051 | Relational Compiler Delegation | REQ-COMP-001, REQ-COMP-007 | Compiler |
| SCN-052 | Example Suite Resource-Authority Flows | REQ-SCREEN-001, REQ-COMP-001 | Example Suite Runtime |
| SCN-053 | Relationship-Driven Composition Semantics | REQ-RES-003, REQ-SCREEN-003, REQ-COMP-004 | Composition Graph |
| SCN-054 | Shared Example Theme Shell and Review Surfaces | REQ-RENDER-002, REQ-RENDER-007, REQ-RENDER-008 | Example Shell |
| SCN-055 | Example Suite Governance Drift Detection | REQ-COMP-008, REQ-RENDER-008 | Example Governance |
| SCN-061 | LiveView Rendering | REQ-RENDER-002 | LiveView Renderer |
| SCN-062 | Elm-Backed Web Rendering | REQ-RENDER-003 | Web Renderer |
| SCN-063 | Component Rendering | REQ-RENDER-004 | Renderer |
| SCN-064 | Binding Rendering | REQ-RENDER-005 | Renderer |
| SCN-065 | Layout Rendering | REQ-RENDER-007 | Renderer |
| SCN-066 | Error Rendering | REQ-RENDER-006 | Renderer |
| SCN-067 | Desktop Rendering | REQ-RENDER-003B | Desktop Renderer |
| SCN-068 | Renderer Selection | REQ-RENDER-001 | Renderer Registry |
| SCN-069 | Renderer Fallback | REQ-RENDER-006 | Renderer Selector |
| SCN-070 | Asset Management | REQ-RENDER-008 | Web Renderer |
| SCN-081 | Screen Mount Authorization | REQ-AUTH-002 | Authorization |
| SCN-082 | Action Authorization | REQ-AUTH-003 | Authorization |
| SCN-083 | Field-Level Authorization | REQ-AUTH-004 | Authorization |
| SCN-084 | Binding Authorization | REQ-AUTH-005 | Authorization |
| SCN-085 | Role-Based Access | REQ-AUTH-007 | Authorization |
| SCN-086 | Resource Ownership Enforcement | REQ-AUTH-006 | Authorization |
| SCN-087 | Authorization Context | REQ-AUTH-008 | Authorization |
| SCN-088 | Authorization Error Handling | REQ-AUTH-009 | Authorization |
| SCN-089 | Authorization Caching | REQ-AUTH-010 | Authorization |
| SCN-101 | Event Emission | REQ-OBS-001, REQ-OBS-002 | Telemetry |
| SCN-102 | Span Context | REQ-OBS-003 | Telemetry |
| SCN-103 | Error Tracking | REQ-OBS-006 | Telemetry |
| SCN-104 | Performance Monitoring | REQ-OBS-007 | Telemetry |
| SCN-105 | Session Observability | REQ-OBS-008 | Telemetry |
| SCN-106 | Data Privacy Redaction | REQ-OBS-012 | Telemetry |
| SCN-121 | Extension Registration | REQ-EXT-001, REQ-EXT-005 | Extension Registry |
| SCN-122 | Extension Compilation | REQ-EXT-002, REQ-EXT-003 | Extension Runtime |
| SCN-141 | Canonical Package And Element Boundary | REQ-NAV-001, REQ-NAV-002, REQ-NAV-003 | Canonical Navigation |
| SCN-142 | Resource-Authored Navigation Intent | REQ-NAV-004, REQ-NAV-005 | Canonical Navigation |
| SCN-143 | Forbidden Host Runtime Navigation Fields | REQ-NAV-006, REQ-NAV-007 | Canonical Navigation |
| SCN-144 | Runtime Adapter Navigation Transport | REQ-NAV-008, REQ-NAV-009 | Canonical Navigation |
| SCN-145 | Canonical Navigation Guide Coverage | REQ-NAV-010 | Canonical Navigation |
| SCN-161 | Canonical Widget Catalog Boundary | REQ-WIDGET-001 | Canonical Widgets |
| SCN-162 | Canonical Widget Admission And Aliases | REQ-WIDGET-002, REQ-WIDGET-003 | Canonical Widgets |
| SCN-163 | Canonical Widget Conversion And Runtime Adapters | REQ-WIDGET-004, REQ-WIDGET-005, REQ-WIDGET-006, REQ-WIDGET-007 | Canonical Widgets |
| SCN-164 | List Repeat Relationship Hydration | REQ-WIDGET-008 | Canonical Widgets |
| SCN-165 | Canonical Widget Guide And Example Coverage | REQ-WIDGET-009 | Canonical Widgets |
| SCN-166 | Phase 31 Conformance And Drift Detection | REQ-WIDGET-010 | Canonical Widgets |
| SCN-171 | Rail Catalog Boundary | REQ-RAIL-001, REQ-RAIL-002 | Canonical Rail |
| SCN-172 | Rail Unified Authoring And IUR Validation | REQ-RAIL-003, REQ-RAIL-004, REQ-RAIL-007, REQ-RAIL-008 | Canonical Rail |
| SCN-173 | Rail Ash Admission And Conversion | REQ-RAIL-004, REQ-RAIL-005, REQ-RAIL-006 | Canonical Rail |
| SCN-174 | Rail Runtime Renderer Support | REQ-RAIL-007, REQ-RAIL-008, REQ-RAIL-009, REQ-RAIL-010 | Canonical Rail |
| SCN-175 | Rail Documentation And Examples | REQ-RAIL-011 | Canonical Rail |
| SCN-176 | Phase 32 Conformance And Drift Detection | REQ-RAIL-012 | Canonical Rail |
| SCN-181 | Workflow Progress Catalog Boundary | REQ-WFPS-001, REQ-WFPS-002 | Canonical Workflow Progress |
| SCN-182 | Workflow Progress Unified Authoring And IUR Validation | REQ-WFPS-003, REQ-WFPS-004, REQ-WFPS-007, REQ-WFPS-008 | Canonical Workflow Progress |
| SCN-183 | Workflow Progress Ash Admission And Conversion | REQ-WFPS-004, REQ-WFPS-005, REQ-WFPS-006 | Canonical Workflow Progress |
| SCN-184 | Workflow Progress Runtime Renderer Support | REQ-WFPS-007, REQ-WFPS-008, REQ-WFPS-009, REQ-WFPS-010 | Canonical Workflow Progress |
| SCN-185 | Workflow Progress Documentation And Examples | REQ-WFPS-010, REQ-WFPS-012 | Canonical Workflow Progress |
| SCN-186 | Phase 33 Conformance And Scope Hygiene | REQ-WFPS-011, REQ-WFPS-012 | Canonical Workflow Progress |

## Related Specifications

- [spec_conformance_matrix.md](spec_conformance_matrix.md)
- [scenario_test_matrix.md](scenario_test_matrix.md)
- All contract files (../contracts/*.md)
