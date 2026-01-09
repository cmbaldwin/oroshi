# Stimulus: Complete Technical Reference Guide for Code Agents

**Tagline**: "A modest JavaScript framework for the HTML you already have."

**Version**: 3.2.2 (Released August 7, 2023)  
**Repository**: https://github.com/hotwired/stimulus  
**Documentation**: https://stimulus.hotwired.dev  
**Author**: Basecamp, LLC  
**License**: MIT

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Core Concepts & Architecture](#core-concepts--architecture)
3. [Controllers](#controllers)
4. [Actions](#actions)
5. [Targets](#targets)
6. [Outlets](#outlets)
7. [Values](#values)
8. [CSS Classes](#css-classes)
9. [Lifecycle Callbacks](#lifecycle-callbacks)
10. [Application & Configuration](#application--configuration)
11. [Development & Testing](#development--testing)
12. [Best Practices](#best-practices)

---

## Project Overview

### Philosophy

Stimulus is a JavaScript framework with **modest ambitions**. Unlike other front-end frameworks, Stimulus:

- Does NOT attempt to take over your entire front-end
- Is NOT concerned with rendering HTML
- IS designed to augment your HTML with behavior
- IS focused on the HTML you already have

**Key Concept**: Think of Stimulus as similar to how CSS connects to HTML via the `class` attribute. Stimulus connects JavaScript to HTML via `data-controller`, `data-action`, and `data-target` attributes.

### Why Stimulus?

- **Minimal JavaScript**: Only add interactivity where needed
- **Server-Friendly**: Works perfectly with server-rendered HTML
- **DOM-Centric**: State lives in the DOM as attributes, not in JS
- **HTML First**: Write HTML first, JavaScript second
- **Turbo Compatible**: Pairs beautifully with Turbo for fast applications

### Key Characteristics

- No virtual DOM reconciliation
- No client-side routing
- No client-side templates
- No build system required (but works with any)
- Works with any backend framework
- Lightweight: ~15KB gzipped
- TypeScript support with full type definitions

---

## Core Concepts & Architecture

### The Four Pillars of Stimulus

1. **Controllers**: JavaScript classes that manage behavior
2. **Actions**: Methods connected to DOM events
3. **Targets**: Named references to important elements
4. **Values**: Typed state stored as DOM attributes

### Basic Example

```html
<!-- HTML with Stimulus annotations -->
<div data-controller="hello">
  <input data-hello-target="name" type="text" placeholder="Enter your name" />
  <button data-action="click->hello#greet">Greet</button>
  <span data-hello-target="output"></span>
</div>
```

```javascript
// hello_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["name", "output"];

  greet(event) {
    event.preventDefault();
    this.outputTarget.textContent = `Hello, ${this.nameTarget.value}!`;
  }
}
```

Stimulus automatically:

- Detects the controller attribute
- Creates a controller instance
- Connects targets
- Wires up actions
- Manages the entire lifecycle

---

## Controllers

Controllers are JavaScript classes that extend the Stimulus `Controller` base class.

### Basic Structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Properties
  static targets = ["..."]
  static outlets = ["..."]
  static values = { ... }
  static classes = ["..."]

  // Lifecycle
  initialize() { }
  connect() { }
  disconnect() { }

  // Methods
  myAction(event) { }
}
```

### Controller Properties

Every controller instance has access to:

```javascript
this.element; // The HTML element with data-controller
this.identifier; // The controller's identifier (string)
this.application; // The Stimulus Application instance
```

### Identifiers & Naming

**Identifier**: The name used in HTML `data-controller` attributes.

**Mapping Rules**:

- File `clipboard_controller.js` → identifier `clipboard`
- File `date_picker_controller.js` → identifier `date-picker`
- File `users/list_item_controller.js` → identifier `users--list-item`
- File `local-time-controller.js` → identifier `local-time`

**Naming Conventions**:

- Use camelCase in JavaScript
- Use kebab-case in HTML
- Use underscores or dashes in filenames (both work)
- Namespace with subfolders (forward slashes become double dashes)

### Scopes

A controller's **scope** includes:

- The controller's element
- All children of that element
- BUT NOT any nested controllers' scopes

```html
<!-- Parent controller's scope -->
<div data-controller="list">
  <div data-list-target="item">Item 1</div>
  <div data-list-target="item">Item 2</div>

  <!-- Nested scope - parent can't see these items -->
  <ul data-controller="list">
    <li data-list-target="item">Nested 1</li>
    <li data-list-target="item">Nested 2</li>
  </ul>
</div>
```

### Multiple Controllers

An element can have multiple controllers:

```html
<div data-controller="clipboard list-item modal-trigger">
  <!-- All three controllers connect to this element -->
</div>
```

Multiple instances of the same controller:

```html
<ul>
  <li data-controller="list-item">Item 1</li>
  <li data-controller="list-item">Item 2</li>
  <li data-controller="list-item">Item 3</li>
</ul>
```

Each `<li>` gets its own instance of `list-item` controller.

### Registration

#### Auto-Loading (Rails with Import Map)

```javascript
// Stimulus for Rails automatically finds controllers in:
// app/javascript/controllers/[identifier]_controller.js
```

#### Webpack with Helpers

```javascript
import { Application } from "@hotwired/stimulus";
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers";

window.Stimulus = Application.start();
const context = require.context("./controllers", true, /\\.js$/);
Stimulus.load(definitionsFromContext(context));
```

#### Manual Registration

```javascript
import { Application } from "@hotwired/stimulus";
import HelloController from "./controllers/hello_controller";

const application = Application.start();
application.register("hello", HelloController);
```

### Advanced Controller Features

#### Conditional Loading

```javascript
export default class extends Controller {
  static shouldLoad() {
    return navigator.userAgent.includes("Chrome");
  }
}
```

#### Post-Registration Hook

```javascript
export default class extends Controller {
  static afterLoad(identifier, application) {
    // Called immediately after registration
    // Can update DOM, migrate legacy elements, etc.
    document.querySelectorAll(".legacy-button").forEach((btn) => {
      btn.setAttribute("data-controller", identifier);
    });
  }
}
```

#### Cross-Controller Communication

Use events instead of direct coupling:

```javascript
// Dispatch custom event
class ClipboardController extends Controller {
  copy() {
    const event = this.dispatch("copy", {
      detail: { content: "text to copy" },
      cancelable: true,
    });

    if (!event.defaultPrevented) {
      navigator.clipboard.writeText("text to copy");
    }
  }
}

// Listen on another controller
class EffectsController extends Controller {
  connect() {
    this.element.addEventListener("clipboard:copy", this.flash.bind(this));
  }

  flash(event) {
    console.log(event.detail.content);
  }
}
```

Listen globally with `@window`:

```html
<div data-action="clipboard:copy@window->effects#flash"></div>
```

#### Direct Controller Access

Only use if events won't work:

```javascript
export default class extends Controller {
  static targets = ["other"];

  doSomething() {
    const otherController =
      this.application.getControllerForElementAndIdentifier(
        this.otherTarget,
        "other"
      );
    otherController.someMethod();
  }
}
```

---

## Actions

Actions connect controller methods to DOM events.

### Action Descriptor Format

```
[event]->[identifier]#[method]:[options]
```

**Parts**:

- **event**: DOM event name (e.g., `click`, `submit`, `input`)
- **identifier**: Controller identifier
- **method**: Method name on controller
- **options**: Optional modifiers (`:prevent`, `:stop`, `:capture`, etc.)

### Basic Examples

```html
<!-- Full form -->
<button data-action="click->search#query">Search</button>

<!-- Shorthand (element/event combo has default) -->
<button data-action="search#query">Search</button>

<!-- Form submission -->
<form data-action="submit->search#update"></form>

<!-- Multiple actions -->
<input data-action="input->search#update focus->search#highlight" />

<!-- With options -->
<div data-action="scroll->gallery#layout:!passive"></div>
```

### Event Shorthand

These element/event pairs have defaults:

| Element                 | Default Event | Shorthand |
| ----------------------- | ------------- | --------- |
| `<a>`                   | click         | ✓         |
| `<button>`              | click         | ✓         |
| `<details>`             | toggle        | ✓         |
| `<form>`                | submit        | ✓         |
| `<input>`               | input         | ✓         |
| `<input type="submit">` | click         | ✓         |
| `<select>`              | change        | ✓         |
| `<textarea>`            | input         | ✓         |

### Keyboard Events with Filters

```html
<!-- Specific keys -->
<div data-action="keydown.enter->form#submit"></div>
<div data-action="keydown.esc->modal#close"></div>

<!-- Modifier combinations -->
<div data-action="keydown.ctrl+a->listbox#selectAll"></div>
```

**Available Filters**:

- `enter` → Enter
- `tab` → Tab
- `esc` → Escape
- `space` → Space
- `up` → ArrowUp
- `down` → ArrowDown
- `left` → ArrowLeft
- `right` → ArrowRight
- `home` → Home
- `end` → End
- `page_up` → PageUp
- `page_down` → PageDown
- `[a-z]` → Single letter (e.g., `a`, `b`, `c`)
- `[0-9]` → Single digit

**Modifier Keys**:

- `ctrl` (Command on Mac)
- `alt` (Option on Mac)
- `shift`

### Global Events

Listen on `window` or `document`:

```html
<div data-action="resize@window->gallery#layout"></div>
<div data-action="scroll@document->sidebar#update"></div>
```

### Action Options

```html
<!-- Prevent default behavior -->
<a href="/page" data-action="click->form#navigate:prevent"></a>

<!-- Stop propagation -->
<div data-action="click->menu#toggle:stop"></div>

<!-- Capture phase -->
<div data-action="click->logger#log:capture"></div>

<!-- One-time listener -->
<button data-action="click->wizard#start:once"></button>

<!-- Passive listener (can't preventDefault) -->
<div data-action="scroll->page#layout:passive"></div>

<!-- Non-passive (can preventDefault) -->
<div data-action="scroll->page#layout:!passive"></div>

<!-- Self (only if event.target === element) -->
<div data-action="click->menu#toggle:self"></div>
```

**Available Options**:

- `:prevent` → calls `event.preventDefault()`
- `:stop` → calls `event.stopPropagation()`
- `:capture` → uses capture phase
- `:once` → listener fires once
- `:passive` → sets `{ passive: true }`
- `:!passive` → sets `{ passive: false }`
- `:self` → only if event.target === currentTarget

### Action Methods

An action method receives the DOM event:

```javascript
export default class extends Controller {
  submit(event) {
    // event.type - Event name (e.g., "submit")
    // event.target - Element that dispatched the event
    // event.currentTarget - Element with the action
    // event.params - Action parameters from data-*-param attributes

    event.preventDefault();
    console.log(event.detail);
  }
}
```

### Action Parameters

Pass data from the action element to the action method:

```html
<div data-controller="item">
  <button
    data-action="item#upvote"
    data-item-id-param="123"
    data-item-url-param="/votes"
    data-item-active-param="true"
    data-item-payload-param='{"key":"value"}'
  >
    Upvote
  </button>
</div>
```

Access in the action:

```javascript
export default class extends Controller {
  upvote(event) {
    console.log(event.params);
    // { id: 123, url: "/votes", active: true, payload: {...} }
  }

  // Or destructure
  upvote({ params: { id, url } }) {
    console.log(id, url);
  }
}
```

**Type Casting**:

- `"123"` → `123` (Number)
- `"/votes"` → `"/votes"` (String)
- `"true"/"false"` → `true`/`false` (Boolean)
- `'{"key":"val"}'` → `{key: "val"}` (Object, parsed as JSON)

### Custom Action Options

```javascript
const app = Application.start();

app.registerActionOption("open", ({ event, value }) => {
  if (event.type === "toggle") {
    return event.target.open === value;
  }
  return true;
});

// Now use in HTML:
// <details data-action="toggle.open->editor#updateHeight"></details>
// <details data-action="toggle.!open->editor#hideHeight"></details>
```

---

## Targets

Targets let you reference important elements by name.

### Basic Usage

```html
<form data-controller="search">
  <input type="text" data-search-target="query" />
  <div data-search-target="errorMessage"></div>
  <div data-search-target="results"></div>
</form>
```

```javascript
export default class extends Controller {
  static targets = ["query", "errorMessage", "results"];

  performSearch() {
    const query = this.queryTarget.value; // First matching element
    this.resultsTarget.innerHTML = "...";
  }
}
```

### Generated Properties

For each target name, Stimulus creates three properties:

```javascript
// Singular - first matching target (throws if missing)
this.queryTarget; // Element
this.queryTarget.value = "new value";

// Plural - all matching targets (returns array)
this.queryTargets; // Element[]
this.queryTargets.forEach((el) => console.log(el));

// Existential - check if present
if (this.hasQueryTarget) {
  // Only access if it exists
  this.queryTarget.focus();
}
```

### Shared Targets

Multiple controllers can target the same element:

```html
<form data-controller="search checkbox">
  <input
    type="checkbox"
    data-search-target="projects"
    data-checkbox-target="input"
  />
</form>
```

```javascript
// In search controller
this.projectsTarget; // The checkbox

// In checkbox controller
this.inputTargets; // Array with the checkbox
```

### Target Callbacks

Respond when targets are added or removed:

```javascript
export default class extends Controller {
  static targets = ["item"];

  itemTargetConnected(element) {
    // Called when item target is added
    console.log("Item connected:", element);
    this.sortItems();
  }

  itemTargetDisconnected(element) {
    // Called when item target is removed
    console.log("Item removed:", element);
    this.sortItems();
  }

  sortItems() {
    // Re-sort whenever items change
  }
}
```

**Note**: During callback execution, MutationObserver is paused, so adding/removing matching targets won't trigger the callback again.

### Naming Conventions

Use camelCase in JavaScript, matches in HTML:

```html
<div data-search-target="camelCase"></div>
```

```javascript
static targets = ["camelCase"]
this.camelCaseTarget  // ✓
this.camelCaseTargets // ✓
this.hasCAMELCASETarget // ✗
```

---

## Outlets

Outlets let controllers reference other controller instances anywhere on the page.

### Concept

While **targets** reference elements within a controller's scope, **outlets** reference controller instances anywhere on the page via CSS selectors.

### Basic Usage

```html
<!-- Multiple user-status controllers -->
<div class="user-list">
  <div class="user" data-controller="user-status" data-user-status-id-value="1">
    Jane Smith <span data-user-status-target="status">Online</span>
  </div>
  <div class="user" data-controller="user-status" data-user-status-id-value="2">
    Bob Jones <span data-user-status-target="status">Offline</span>
  </div>
</div>

<!-- Chat controller references user-status controllers -->
<div data-controller="chat" data-chat-user-status-outlet=".user">
  <!-- Chat content -->
</div>
```

```javascript
// user_status_controller.js
export default class extends Controller {
  static values = { id: Number }
  static targets = ["status"]

  setStatus(status) {
    this.statusTarget.textContent = status
  }
}

// chat_controller.js
export default class extends Controller {
  static outlets = ["user-status"]

  connect() {
    // Access all user-status controllers
    this.userStatusOutlets.forEach(outlet => {
      outlet.setStatus("Active in chat")
    })
  }

  disconnect() {
    // Reset when chat closes
    this.userStatusOutlets.forEach(outlet => {
      outlet.setStatus("Offline")
    })
  }
}
```

### Generated Properties

For each outlet identifier, Stimulus creates five properties:

```javascript
// Existential - check if outlet exists
if (this.hasUserStatusOutlet) {
}

// Singular outlet controller (throws if missing)
this.userStatusOutlet; // Controller instance
this.userStatusOutlet.idValue; // Access values
this.userStatusOutlet.statusTarget; // Access targets

// Plural outlet controllers
this.userStatusOutlets; // Controller[]
this.userStatusOutlets.forEach((outlet) => {});

// Singular outlet element
this.userStatusOutletElement; // Element

// Plural outlet elements
this.userStatusOutletElements; // Element[]
```

### Calling Outlet Methods

```javascript
// From chat controller
this.userStatusOutlets.forEach((outlet) => {
  outlet.markAsSelected(); // Call controller method
});

// Work with outlet elements
this.userStatusOutletElements.forEach((el) => {
  el.classList.add("selected");
});
```

### Outlet Callbacks

```javascript
export default class extends Controller {
  static outlets = ["user-status"];

  userStatusOutletConnected(outlet, element) {
    // Called when outlet element appears/is added to DOM
    console.log("User status outlet connected:", outlet.idValue);
  }

  userStatusOutletDisconnected(outlet, element) {
    // Called when outlet element removed from DOM
    console.log("User status outlet disconnected:", outlet.idValue);
  }
}
```

### Optional Outlets

```javascript
export default class extends Controller {
  static outlets = ["sidebar"];

  toggle() {
    if (this.hasSidebarOutlet) {
      this.sidebarOutlet.toggle();
    }
  }
}
```

### Requirements

- Outlet element must have `data-controller="[identifier]"`
- Outlet selector must reference controller elements
- Missing outlets without checks throw an error

---

## Values

Values let you read, write, and observe typed data attributes.

### Basic Usage

```html
<div data-controller="loader" data-loader-url-value="/api/data"></div>
```

```javascript
export default class extends Controller {
  static values = {
    url: String,
    timeout: Number,
    options: Object,
    enabled: Boolean,
    items: Array,
  };

  connect() {
    fetch(this.urlValue)
      .then((r) => r.json())
      .then((data) => {
        this.itemsValue = data;
      });
  }
}
```

### Type System

All values are **strongly typed**:

| Type      | Stored As                      | Retrieved As  |
| --------- | ------------------------------ | ------------- |
| `String`  | Text                           | String        |
| `Number`  | Text with underscores `1_000`  | `Number`      |
| `Boolean` | `"true"` or `"false"` or empty | `Boolean`     |
| `Object`  | JSON string                    | Parsed object |
| `Array`   | JSON string                    | Parsed array  |

### Generated Properties

For each value, Stimulus creates three properties:

```javascript
// Getter - reads and type-casts
const url = this.urlValue; // Reads data-loader-url-value

// Setter - writes and updates attribute
this.urlValue = "http://new.url"; // Sets data-loader-url-value

// Existential - check if attribute exists
if (this.hasUrlValue) {
  console.log(this.urlValue);
}
```

### Default Values

```javascript
static values = {
  // Explicit default
  url: { type: String, default: "/api/default" },

  // Mix and match
  interval: { type: Number, default: 5000 },
  enabled: Boolean,  // No default
  data: { type: Object, default: {} }
}

// If no attribute, these are returned:
// String: ""
// Number: 0
// Boolean: false
// Object: {}
// Array: []
```

### Value Change Callbacks

Respond when values change:

```javascript
export default class extends Controller {
  static values = {
    url: String,
    count: Number,
  };

  // Called on initialization and whenever value changes
  urlValueChanged(value, previousValue) {
    console.log(`URL changed from ${previousValue} to ${value}`);
    this.fetch(value);
  }

  // Can omit previous value parameter
  countValueChanged(newCount) {
    console.log("Count:", newCount);
  }
}
```

### Typing Data Attributes

```html
<!-- String (no quotes in value) -->
<div data-controller="app" data-app-name-value="MyApp"></div>

<!-- Number (with underscores ok) -->
<div data-controller="timer" data-timer-duration-value="1000"></div>
<div data-controller="timer" data-timer-duration-value="1_000"></div>

<!-- Boolean (exact: "true" or "false" or empty) -->
<div data-controller="toggle" data-toggle-active-value="true"></div>
<div data-controller="toggle" data-toggle-active-value="false"></div>
<div data-controller="toggle" data-toggle-active-value=""></div>

<!-- Object (JSON) -->
<div
  data-controller="config"
  data-config-settings-value='{"theme":"dark","lang":"en"}'
></div>

<!-- Array (JSON) -->
<div data-controller="list" data-list-items-value="[1,2,3,4,5]"></div>
```

### Naming Conventions

In JavaScript: camelCase  
In HTML attributes: kebab-case

```javascript
static values = { contentType: String, refreshInterval: Number }
```

```html
<!-- Maps to contentType -->
data-app-content-type-value="text/html"

<!-- Maps to refreshInterval -->
data-app-refresh-interval-value="5000"
```

---

## CSS Classes

Manage CSS classes via controller without hardcoding class names.

### Basic Usage

```html
<form data-controller="search" data-search-loading-class="is-loading spinner">
  <input data-action="search#query" />
  <div data-search-results-class="has-results empty-state">Results</div>
</form>
```

```javascript
export default class extends Controller {
  static classes = ["loading", "results"];

  async query(event) {
    // Add loading class
    this.element.classList.add(this.loadingClass);

    const data = await fetch("/search");

    // Remove loading class
    this.element.classList.remove(this.loadingClass);

    // Show results
    this.element.classList.add(...this.resultsClasses);
  }
}
```

### Generated Properties

For each class name:

```javascript
// Singular - first class from data attribute
this.loadingClass; // "is-loading" (String)
this.loadingClass; // Throws if no data-search-loading-class

// Plural - array of all classes
this.loadingClasses; // ["is-loading", "spinner"] (Array)

// Existential - check if attribute exists
if (this.hasLoadingClass) {
  this.element.classList.toggle(this.loadingClass);
}
```

### Usage Pattern

```javascript
// Single class
this.element.classList.add(this.loadingClass);

// Multiple classes
this.element.classList.add(...this.loadingClasses);

// Remove
this.element.classList.remove(this.loadingClass);

// Toggle
this.element.classList.toggle(this.loadingClass);

// Check
if (this.element.classList.contains(this.loadingClass)) {
}
```

### Naming

In JavaScript: camelCase  
In HTML: kebab-case

```javascript
static classes = ["loading", "noResults"]
```

```html
data-search-loading-class="is-loading"
data-search-no-results-class="empty-state"
```

---

## Lifecycle Callbacks

Controllers have lifecycle methods called at specific times.

### The Lifecycle

```javascript
export default class extends Controller {
  // 1. Called once when controller is first instantiated
  initialize() {
    this.data = {};
  }

  // 2. Called when controller element is inserted into DOM
  //    Can be called multiple times if element is removed/re-added
  connect() {
    console.log("Connected:", this.element);
  }

  // 3. Called when controller element is removed from DOM
  //    Clean up external resources here
  disconnect() {
    clearInterval(this.timer);
  }
}
```

### Common Patterns

#### Initialize

Set up controller properties, don't access DOM:

```javascript
initialize() {
  this.items = []
  this.selectedIndex = 0
}
```

#### Connect

Access DOM, start timers, set up listeners:

```javascript
connect() {
  if (this.hasRefreshIntervalValue) {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.refreshIntervalValue)
  }
}
```

#### Disconnect

Clean up resources to prevent memory leaks:

```javascript
disconnect() {
  if (this.refreshTimer) {
    clearInterval(this.refreshTimer)
  }

  document.removeEventListener("keydown", this.handleKeydown)
}
```

### Target Callbacks

Called when targets appear/disappear:

```javascript
itemTargetConnected(element) {
  // New item added
  this.updateCount()
}

itemTargetDisconnected(element) {
  // Item removed
  this.updateCount()
}
```

### Value Callbacks

Called when values change:

```javascript
queryValueChanged(newValue, oldValue) {
  this.search(newValue)
}
```

### Outlet Callbacks

Called when outlets appear/disappear:

```javascript
userStatusOutletConnected(outlet, element) {
  this.notifyUserConnected(outlet.idValue)
}

userStatusOutletDisconnected(outlet, element) {
  this.notifyUserDisconnected(outlet.idValue)
}
```

---

## Application & Configuration

### Creating an Application

#### With Auto-Loading (Rails)

```javascript
// Stimulus for Rails auto-loads controllers from:
// app/javascript/controllers/*_controller.js
```

#### Manual Registration

```javascript
import { Application } from "@hotwired/stimulus";
import HelloController from "./controllers/hello_controller";
import SearchController from "./controllers/search_controller";

const application = Application.start();
application.register("hello", HelloController);
application.register("search", SearchController);

// Make global for debugging
window.Stimulus = application;
```

### Configuration

#### Custom Schema (Data Attributes)

```javascript
import { Application, defaultSchema } from "@hotwired/stimulus";

const customSchema = {
  ...defaultSchema,
  controllerAttribute: "data-controller",
  actionAttribute: "data-action",
  targetAttribute: "data-target",
  // Can override any attribute names
};

const application = Application.start(document.documentElement, customSchema);
```

#### Error Handling

```javascript
application.handleError = (error, message, detail) => {
  // Custom error handling
  console.error(message, detail);

  // Send to error tracking
  if (window.Sentry) {
    window.Sentry.captureException(error);
  }
};
```

#### Debugging

```javascript
// From console
Stimulus.debug = true;

// Or in code
application.debug = true;
```

### Application Methods

```javascript
// Register a controller
application.register("identifier", ControllerClass);

// Handle errors
application.handleError = (error, message, detail) => {};

// Get controller instance
const controller = application.getControllerForElementAndIdentifier(
  element,
  "id"
);

// Register action option
application.registerActionOption("myOption", ({ event, value }) => {
  return event.type === "custom";
});
```

---

## Development & Testing

### File Structure

```
project/
├── src/
│   ├── controllers/
│   │   ├── hello_controller.js
│   │   ├── search_controller.js
│   │   └── admin/
│   │       └── dashboard_controller.js
│   ├── index.js
│   └── application.js
├── tests/
│   └── controllers/
│       └── hello_controller.test.js
├── package.json
└── rollup.config.js
```

### NPM Scripts

```bash
# Development
yarn install           # Install dependencies
yarn start            # Watch + examples
yarn watch            # Watch for changes

# Testing
yarn test             # Run tests once
yarn test:watch       # Watch tests

# Code Quality
yarn lint             # Run linter
yarn format           # Fix formatting

# Building
yarn build            # Build distribution
yarn build:test       # Build test code
```

### Build Configuration

**rollup.config.js**: Handles TypeScript compilation, tree-shaking, minification.

**TypeScript**: Stimulus is written in TypeScript, targets ES2017.

**Type Definitions**: Full type definitions included in `dist/types/`.

### Testing Setup

- **Test Framework**: QUnit
- **Browser Runner**: Karma
- **Browsers**: Chrome and Firefox

```bash
# Run in specific browser
yarn test:browser --project=chrome

# Watch mode
yarn test:watch

# Headed mode (see browser)
yarn test:browser --headed
```

---

## Best Practices

### 1. Use Progressive Enhancement

Always ensure basic functionality works without JavaScript:

```html
<!-- ✓ Good: Form works without JS -->
<form action="/search" method="get" data-controller="search">
  <input name="q" type="text" />
  <button type="submit">Search</button>
</form>

<!-- ✗ Bad: Requires JavaScript -->
<div data-controller="search">
  <input data-search-target="query" />
  <div data-action="click->search#query">Search</div>
</div>
```

Feature-detect capabilities and show UI only when supported:

```javascript
export default class extends Controller {
  static classes = ["supported"];

  connect() {
    if ("clipboard" in navigator) {
      this.element.classList.add(this.supportedClass);
    }
  }
}
```

### 2. Store State in the DOM

Use values, not controller properties:

```javascript
// ✓ Good: State persists in DOM
export default class extends Controller {
  static values = { count: Number }

  increment() {
    this.countValue++
  }
}

// ✗ Bad: State lost on reconnect
export default class extends Controller {
  connect() {
    this.count = 0  // Lost!
  }
}
```

### 3. Use Events for Cross-Controller Communication

```javascript
// ✓ Good: Loose coupling via events
class ClipboardController extends Controller {
  copy() {
    this.dispatch("success");
  }
}

document.addEventListener("clipboard:success", (e) => {
  // Handle elsewhere
});

// ✗ Bad: Tight coupling
class ClipboardController extends Controller {
  copy() {
    effects.showFlash(); // Hard dependency
  }
}
```

### 4. Clean Up Resources

```javascript
export default class extends Controller {
  static values = { refreshInterval: Number };

  connect() {
    if (this.hasRefreshIntervalValue) {
      this.timer = setInterval(() => this.refresh(), this.refreshIntervalValue);
    }
  }

  disconnect() {
    // ALWAYS clean up
    if (this.timer) {
      clearInterval(this.timer);
    }
  }
}
```

### 5. Make Controllers Reusable

```html
<!-- ✓ Good: Works multiple times on same page -->
<div data-controller="clipboard">
  <input value="PIN: 1234" readonly />
  <button data-action="clipboard#copy">Copy</button>
</div>

<div data-controller="clipboard">
  <input value="PIN: 5678" readonly />
  <button data-action="clipboard#copy">Copy</button>
</div>
```

### 6. Use Outlets for References Between Controllers

```javascript
// ✓ Good: Controllers know about each other
export default class extends Controller {
  static outlets = ["user-status"];

  selectUser(event) {
    const userId = event.params.id;
    this.userStatusOutlet.selectUser(userId);
  }
}
```

### 7. Name Actions Descriptively

```html
<!-- ✓ Good: Describes what happens -->
<button data-action="form#submit">Save</button>
<button data-action="modal#close">Cancel</button>
<button data-action="gallery#next">Next Slide</button>

<!-- ✗ Bad: Repeats event name -->
<button data-action="form#onClick">Save</button>
<button data-action="modal#handleClose">Cancel</button>
```

### 8. Use Lifecycle Callbacks Correctly

```javascript
// ✓ Good
export default class extends Controller {
  initialize() {
    // Setup properties, once per instance
    this.items = []
  }

  connect() {
    // Access DOM, every time connected
    this.render()
  }

  disconnect() {
    // Cleanup, every time disconnected
    this.stopTimer()
  }
}

// ✗ Bad: Using connect like initialize
export default class extends Controller {
  connect() {
    // Only runs when first connected, not on reuse
    this.items = []
  }
}
```

### 9. Leverage TypeScript

```typescript
// Define types for values, targets, outlets
import { Controller } from "@hotwired/stimulus";

interface SearchValues {
  query: string;
  resultsCount: number;
}

export default class extends Controller<SearchValues> {
  static targets = ["query", "results"] as const;

  declare queryTarget: HTMLInputElement;
  declare resultsTargets: HTMLElement[];

  query(event: Event) {
    this.queryTarget.value; // Fully typed
  }
}
```

### 10. Test Controllers

```javascript
// Using QUnit
QUnit.module("hello_controller", () => {
  QUnit.test("greet", (assert) => {
    const html = `
      <div data-controller="hello">
        <input data-hello-target="name" value="World">
        <div data-hello-target="output"></div>
      </div>
    `;
    const element = document.createElement("div");
    element.innerHTML = html;

    const app = Application.start(element);
    const controller = app.getControllerForElementAndIdentifier(
      element.querySelector("[data-controller]"),
      "hello"
    );

    controller.greet();

    assert.equal(
      element.querySelector("[data-hello-target='output']").textContent,
      "Hello, World!"
    );
  });
});
```

---

## Common Patterns

### Debouncing Search Input

```javascript
export default class extends Controller {
  static targets = ["query"];

  initialize() {
    this.debouncedSearch = this.debounce(this.search.bind(this), 300);
  }

  search(event) {
    fetch(`/search?q=${this.queryTarget.value}`)
      .then((r) => r.json())
      .then((results) => this.displayResults(results));
  }

  debounce(func, delay) {
    let timeoutId;
    return function (...args) {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func.apply(this, args), delay);
    };
  }
}
```

HTML:

```html
<div data-controller="search">
  <input
    type="search"
    data-search-target="query"
    data-action="input->search#search"
  />
  <div id="results"></div>
</div>
```

### Modal with Escape Key

```javascript
export default class extends Controller {
  connect() {
    this.element.focus();
  }

  closeWithEscape(event) {
    this.close();
  }

  close() {
    this.element.remove();
  }
}
```

HTML:

```html
<div
  data-controller="modal"
  data-action="keydown.esc->modal#closeWithEscape"
  tabindex="0"
  role="dialog"
>
  <h1>Modal Title</h1>
  <button data-action="modal#close">Close</button>
</div>
```

### Form with Loading State

```javascript
export default class extends Controller {
  static targets = ["form", "button"]
  static classes = ["loading"]

  submit(event) {
    event.preventDefault()

    this.buttonTarget.disabled = true
    this.element.classList.add(this.loadingClass)

    fetch(this.formTarget.action, {
      method: this.formTarget.method,
      body: new FormData(this.formTarget)
    })
      .then(r => r.json())
      .then(data => this.handleSuccess(data))
      .catch(error => this.handleError(error))
      .finally(() => {
        this.buttonTarget.disabled = false
        this.element.classList.remove(this.loa
```
