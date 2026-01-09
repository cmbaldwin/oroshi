# Turbo: Complete Technical Reference Guide for Code Agents

**Version**: 8.0.20 (Released September 26, 2025)  
**Repository**: https://github.com/hotwired/turbo  
**Documentation**: https://turbo.hotwired.dev  
**Author**: 37signals LLC  
**License**: MIT

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Core Concepts](#core-concepts)
3. [Architecture](#architecture)
4. [API Reference](#api-reference)
5. [Configuration](#configuration)
6. [Events](#events)
7. [HTML Attributes](#html-attributes)
8. [Development & Testing](#development--testing)
9. [Contributing](#contributing)
10. [Best Practices](#best-practices)

---

## Project Overview

**Tagline**: "The speed of a single-page web application without having to write any JavaScript."

Turbo uses complementary techniques to dramatically reduce the amount of custom JavaScript that web applications need. It provides SPA-like speed while leveraging server-rendered HTML and minimal client-side code.

### What Turbo Does

- **Accelerates navigation** through page-level caching and history management
- **Decomposes complex pages** into independent, lazily-loadable segments
- **Delivers real-time updates** via WebSocket, SSE, or form responses
- **Enables hybrid apps** for iOS and Android with seamless web/native integration

### Core Philosophy

- **HTML-over-the-wire**: Send HTML, not JSON
- **Server-side rendering**: Keep business logic on the server
- **Progressive enhancement**: Works without JavaScript for baseline functionality
- **Minimal client code**: Focus on behavior, not state management

---

## Core Concepts

### 1. Turbo Drive

**Purpose**: Enhanced page navigation without full page reloads.

**How it works**:

- Intercepts clicks on `<a>` links to the same domain
- Intercepts form submissions (POST, PUT, PATCH, DELETE)
- Uses History API and fetch to update the page
- Replaces `<body>` contents and merges `<head>` elements
- Persists window and document objects across navigations

**Visit Types**:

- **Application Visit** (`action: "advance"` or `"replace"`): Initiated by clicking links or calling `Turbo.visit()`
- **Restoration Visit** (`action: "restore"`): Initiated by browser Back/Forward buttons

**Key Features**:

- Automatic progress bar for network requests (configurable, default 500ms delay)
- Cache management for faster restoration
- View Transition API support for CSS-based animations
- Prefetching links on hover for perceived speed boost
- Preloading frequently-visited pages

---

### 2. Turbo Frames

**Purpose**: Decompose pages into independent, scoped navigation contexts.

**How it works**:

- Wrap segments in `<turbo-frame id="unique-id">` tags
- All links and forms within the frame scope to that frame only
- Server responds with matching frame ID; only that frame content updates
- Rest of the page remains unchanged

**Frame Types**:

| Type             | Attributes                                   | Behavior                                     |
| ---------------- | -------------------------------------------- | -------------------------------------------- |
| Basic Frame      | `<turbo-frame id="name">`                    | Scoped navigation within frame               |
| Eager-loaded     | `src="/path"`                                | Loads immediately on page load               |
| Lazy-loaded      | `src="/path" loading="lazy"`                 | Loads only when visible in viewport          |
| Target Override  | `target="_top"` or `target="other-frame-id"` | Direct page or other frame navigation        |
| Promote to Visit | `data-turbo-action="advance"`                | Frame navigation updates browser history     |
| Refresh on Morph | `refresh="morph" src="/path"`                | Reloads frame on page refresh using morphing |

**Key Properties**:

- `FrameElement.src`: Get/set the URL to load
- `FrameElement.loaded`: Promise that resolves when navigation completes
- `FrameElement.isActive`: Boolean indicating if frame is ready
- `FrameElement.autoscroll`: Control scroll behavior on load

---

### 3. Turbo Streams

**Purpose**: Deliver targeted DOM updates via HTML fragments over WebSocket, SSE, or form responses.

**8 Core Actions**:

| Action    | Purpose                                     | Example                       |
| --------- | ------------------------------------------- | ----------------------------- |
| `append`  | Add content at end of target                | Append new message to list    |
| `prepend` | Add content at start of target              | Add notification to top       |
| `replace` | Replace entire target element               | Swap old element with new one |
| `update`  | Replace target's contents, preserve element | Update count badge            |
| `remove`  | Delete target element                       | Remove expired item           |
| `before`  | Insert before target                        | Add separator line            |
| `after`   | Insert after target                         | Add button below item         |
| `morph`   | DOM morph update (with method="morph")      | Smooth element transition     |
| `refresh` | Trigger full page refresh                   | Notify all clients to update  |

**Usage Format**:

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_123">New message content</div>
  </template>
</turbo-stream>
```

**Delivery Methods**:

- Form submission with `Content-Type: text/vnd.turbo-stream.html`
- WebSocket connection via `<turbo-stream-source src="ws://...">` or `wss://`
- Server-Sent Events (SSE) via `<turbo-stream-source src="http://...">`
- Mercure protocol for distributed broadcasting

---

### 4. Turbo Native

**Purpose**: Build hybrid iOS and Android apps using server-rendered web pages.

**Key Points**:

- Leverage existing server-rendered HTML in native wrappers
- Use native UI only for screens that truly benefit
- Instant updates (no App Store delays) for web-rendered screens
- Seamless transitions between web and native sections

---

## Architecture

### Source Structure

```
src/
├── core/              # Core navigation and session management
├── elements/          # Custom elements (turbo-frame, turbo-stream)
├── http/              # HTTP request/response handling
├── observers/         # DOM observers for prefetch and link/form interception
├── polyfills/         # Browser compatibility polyfills
└── tests/             # Test fixtures and test suite
    ├── fixtures/      # HTML test files
    └── functional/    # Browser-based functional tests
```

### Build System

- **Bundler**: Rollup with ES2017 output
- **Testing**: Playwright (browser automation) + Web Test Runner (unit tests)
- **Linting**: ESLint for code quality
- **Formatting**: Prettier for code style
- **Dev Server**: Express.js (runs on port 9000 for manual testing)

### Package Metadata

```json
{
  "name": "@hotwired/turbo",
  "version": "8.0.20",
  "main": "dist/turbo.es2017-umd.js",
  "module": "dist/turbo.es2017-esm.js",
  "files": ["dist/*.js", "dist/*.js.map"],
  "engines": { "node": ">= 18" }
}
```

---

## API Reference

### Turbo.visit(location, options)

Programmatically navigate to a new location.

```javascript
// Basic visit with default "advance" action
Turbo.visit("/messages/1");

// Use "replace" to modify history instead of pushing
Turbo.visit("/edit", { action: "replace" });

// Navigate a specific frame
Turbo.visit("/frame-content", { frame: "message_1" });
```

**Options**:

- `action`: "advance" | "replace" | "restore" (for internal use only)
- `frame`: Target frame element ID

---

### Turbo.session

Access to the global session object controlling Drive behavior.

```javascript
// Opt-in to Turbo Drive (requires data-turbo="true" on elements)
Turbo.session.drive = false;

// Check if currently displaying preview
const isPreview = document.documentElement.hasAttribute("data-turbo-preview");
```

---

### Turbo.config

Global configuration object.

```javascript
// Control progress bar delay (milliseconds)
Turbo.config.drive.progressBarDelay = 500;

// Custom confirmation method for data-turbo-confirm
Turbo.config.forms.confirm = (message) => {
  return new Promise((resolve) => {
    // Custom dialog logic
    resolve(true || false);
  });
};
```

---

### Turbo.cache

Cache management API.

```javascript
// Clear all cached pages
Turbo.cache.clear();

// Mark current page as not cacheable
Turbo.cache.exemptPageFromCache();

// Mark current page as not preview-able
Turbo.cache.exemptPageFromPreview();

// Reset cache control meta tags
Turbo.cache.resetCacheControl();
```

---

### FetchRequest Object

Properties available in `turbo:before-fetch-request` events:

```javascript
{
  url: URL,                           // Request URL
  method: "get" | "post" | "put" | "patch" | "delete",
  enctype: string,                    // Form encoding type
  body: FormData | URLSearchParams,   // Request payload
  headers: Headers,                   // HTTP headers
  fetchOptions: RequestInit,          // Fetch API options
  target: HTMLElement,                // Element initiating request
  params: URLSearchParams              // URL parameters
}
```

---

### FetchResponse Object

Properties available in `turbo:before-fetch-response` and `turbo:frame-render` events:

```javascript
{
  response: Response,                 // Fetch API Response
  statusCode: number,                 // HTTP status
  location: URL,                      // Final URL (after redirects)
  contentType: string | null,         // Content-Type header
  isHTML: boolean,                    // Is response HTML?
  succeeded: boolean,                 // Is status 200-299?
  failed: boolean,                    // Is response error?
  clientError: boolean,               // Is status 400-499?
  serverError: boolean,               // Is status 500-599?
  redirected: boolean,                // Was redirected?
  responseHTML: Promise<string>,      // Cloned response text
  responseText: Promise<string>       // Response body as text
}
```

---

### FormSubmission Object

Available in form submission events:

```javascript
{
  formElement: HTMLFormElement,
  isSafe: boolean,                    // Is method GET?
  submitter: HTMLButtonElement | HTMLInputElement | undefined,
  action: string,                     // Form action URL
  method: string,                     // Form method
  enctype: string,                    // Encoding type
  location: URL,                      // Action as URL
  body: FormData | URLSearchParams,   // Payload
  fetchRequest: FetchRequest
}
```

---

## Configuration

### Meta Tags (Page Head)

| Meta Tag               | Content         | Purpose                                    |
| ---------------------- | --------------- | ------------------------------------------ | ---------------------- |
| `turbo-root`           | `/app`          | Restrict Turbo to a path prefix            |
| `turbo-visit-control`  | `reload`        | Force full page reload for this page       |
| `turbo-cache-control`  | `no-cache` \\   | `no-preview`                               | Cache behavior control |
| `turbo-prefetch`       | `false`         | Disable link prefetching globally          |
| `turbo-refresh-method` | `morph`         | Use morphing instead of replace on refresh |
| `turbo-refresh-scroll` | `preserve`      | Preserve scroll position on refresh        |
| `view-transition`      | `same-origin`   | Enable View Transition API                 |
| `csrf-token`           | `[token-value]` | CSRF protection token                      |

**Example**:

```html
<head>
  <meta name="turbo-root" content="/app" />
  <meta name="turbo-cache-control" content="no-cache" />
  <meta name="turbo-refresh-method" content="morph" />
  <meta name="view-transition" content="same-origin" />
  <meta name="csrf-token" content="abc123..." />
</head>
```

---

### Data Attributes

| Attribute                     | Applied To                       | Effect                                |
| ----------------------------- | -------------------------------- | ------------------------------------- |
| `data-turbo="false"`          | `<a>`, `<form>`, container       | Disable Turbo Drive for element       |
| `data-turbo="true"`           | Any                              | Enable Turbo Drive (when drive=false) |
| `data-turbo-method="delete"`  | `<a>`                            | Use DELETE instead of GET             |
| `data-turbo-confirm="..."`    | `<a>`, `<form>`                  | Show confirmation dialog              |
| `data-turbo-action="replace"` | `<a>`, `<form>`, `<turbo-frame>` | Use replace instead of advance        |
| `data-turbo-frame="_top"`     | `<a>`, `<form>`                  | Navigate whole page, not frame        |
| `data-turbo-frame="frame-id"` | `<a>`, `<form>`                  | Target specific frame                 |
| `data-turbo-prefetch="false"` | `<a>`, container                 | Skip prefetch for link                |
| `data-turbo-preload`          | `<a>`                            | Preload link into cache               |
| `data-turbo-track="reload"`   | `<script>`, `<link>`             | Full reload if asset changes          |
| `data-turbo-track="dynamic"`  | `<link>`, `<style>`              | Dynamically remove element if missing |
| `data-turbo-eval="false"`     | `<script>`                       | Don't evaluate script on navigation   |
| `data-turbo-temporary`        | Any                              | Remove from cache before saving       |
| `data-turbo-permanent`        | Any                              | Persist element across page loads     |
| `data-turbo-stream`           | `<form>`                         | Request Turbo Streams response        |

---

## Events

### Document-Level Events

Events fire on `document.documentElement` unless noted.

#### Navigation Lifecycle

```javascript
// Before navigation starts (can cancel)
document.addEventListener("turbo:click", (e) => {
  console.log("Clicked:", e.detail.url);
  if (shouldPreventNavigation) e.preventDefault();
});

// Before visit (can cancel, except restoration visits)
document.addEventListener("turbo:before-visit", (e) => {
  console.log("About to visit:", e.detail.url);
});

// Visit started
document.addEventListener("turbo:visit", (e) => {
  console.log("Visit to:", e.detail.url, "Action:", e.detail.action);
});

// Before rendering response
document.addEventListener("turbo:before-render", async (e) => {
  e.preventDefault(); // Pause rendering
  await animateOut();
  e.detail.resume(); // Resume rendering
});

// After page renders
document.addEventListener("turbo:render", (e) => {
  console.log("Rendered with method:", e.detail.renderMethod);
});

// Page load complete (fires on initial load + after every visit)
document.addEventListener("turbo:load", (e) => {
  console.log("Page loaded:", e.detail.url);
  console.log("Timing:", e.detail.timing);
});

// Before caching page
document.addEventListener("turbo:before-cache", () => {
  // Cleanup temporary state
});
```

#### Morphing Events (Page Refresh)

```javascript
// Before morphing page
document.addEventListener("turbo:before-morph-element", (e) => {
  if (shouldSkipMorph(e.target)) {
    e.preventDefault(); // Preserve original element
  }
});

// Before morphing attributes
document.addEventListener("turbo:before-morph-attribute", (e) => {
  if (e.detail.attributeName === "disabled") {
    e.preventDefault(); // Skip this attribute morph
  }
});

// After morph completes
document.addEventListener("turbo:morph", (e) => {
  console.log("Morphed:", e.detail.currentElement);
});

// After element morph
document.addEventListener("turbo:morph-element", (e) => {
  console.log("Element morphed:", e.target);
});
```

---

### Form Events

Events fire on the `<form>` element.

```javascript
form.addEventListener("turbo:submit-start", (e) => {
  console.log("Form submitting:", e.detail.formSubmission);
});

form.addEventListener("turbo:submit-end", (e) => {
  if (e.detail.success) {
    console.log("Form submitted successfully");
  } else {
    console.log("Submission error:", e.detail.error);
  }
});
```

---

### Frame Events

Events fire on the `<turbo-frame>` element.

```javascript
frame.addEventListener("turbo:before-frame-render", async (e) => {
  e.preventDefault(); // Pause rendering
  await setupFrame();
  e.detail.resume(); // Resume
});

frame.addEventListener("turbo:frame-render", (e) => {
  console.log("Frame rendered:", e.detail.fetchResponse);
});

frame.addEventListener("turbo:frame-load", (e) => {
  console.log("Frame load complete");
});

frame.addEventListener("turbo:frame-missing", (e) => {
  e.preventDefault(); // Prevent error
  e.detail.visit("/fallback-page"); // Navigate elsewhere
});
```

---

### Stream Events

Events fire on the `<turbo-stream>` element.

```javascript
document.addEventListener("turbo:before-stream-render", (e) => {
  // Customize stream rendering
  e.detail.render = function (streamElement) {
    if (streamElement.action === "custom") {
      // Custom action handler
    } else {
      // Fall back to default
      fallbackToDefaultActions(streamElement);
    }
  };
});
```

---

### HTTP Events

Events fire on the element initiating the request.

```javascript
element.addEventListener("turbo:before-fetch-request", async (e) => {
  e.preventDefault(); // Pause request
  const token = await getAuthToken();
  e.detail.fetchOptions.headers["Authorization"] = `Bearer ${token}`;
  e.detail.resume(); // Resume request
});

element.addEventListener("turbo:before-fetch-response", (e) => {
  console.log("Response received:", e.detail.fetchResponse);
});

element.addEventListener("turbo:before-prefetch", (e) => {
  if (hasSlowInternet()) {
    e.preventDefault(); // Skip prefetch
  }
});

element.addEventListener("turbo:fetch-request-error", (e) => {
  console.log("Fetch failed:", e.detail.error);
});
```

---

## HTML Attributes

### Turbo Frame Attributes

```html
<!-- Basic frame -->
<turbo-frame id="messages">
  <a href="/messages/1">Show message</a>
</turbo-frame>

<!-- Eager-loaded frame -->
<turbo-frame id="comments" src="/messages/comments" autoscroll>
  Loading...
</turbo-frame>

<!-- Lazy-loaded frame -->
<turbo-frame id="sidebar" src="/sidebar" loading="lazy">
  Content will load when visible
</turbo-frame>

<!-- Navigation targeting -->
<turbo-frame id="main" target="_top">
  <!-- Links navigate whole page -->
</turbo-frame>

<turbo-frame id="list">
  <a href="/detail" data-turbo-frame="_top">Navigate page</a>
  <a href="/other-list" data-turbo-frame="list">Navigate frame</a>
</turbo-frame>

<!-- Promote to visit (updates history) -->
<turbo-frame id="articles" data-turbo-action="advance">
  <a href="/articles?page=2">Next</a>
</turbo-frame>

<!-- Morph on page refresh -->
<turbo-frame id="stats" refresh="morph" src="/stats"></turbo-frame>

<!-- Recurse into nested frames -->
<turbo-frame id="main" recurse="details" src="/main"></turbo-frame>

<!-- Scroll behavior -->
<turbo-frame
  id="content"
  autoscroll
  data-autoscroll-block="center"
  data-autoscroll-behavior="smooth"
>
</turbo-frame>
```

### FrameElement Properties (JavaScript)

```javascript
const frame = document.querySelector("turbo-frame#messages");

// Get/set source URL
frame.src = "/new/path";

// Check if fully loaded
frame.loaded.then(() => console.log("Done"));

// Check if currently loading
console.log(frame.busy); // boolean

// Check if disabled
console.log(frame.disabled); // boolean

// Get loading style
console.log(frame.loading); // "eager" or "lazy"

// Check completion
console.log(frame.complete); // boolean

// Check if active
console.log(frame.isActive); // boolean

// Check if preview
console.log(frame.isPreview); // boolean

// Control auto-scroll
frame.autoscroll = true;

// Reload frame
frame.reload();
```

---

## Development & Testing

### Setup

```bash
# Clone and install dependencies
git clone https://github.com/hotwired/turbo.git
cd turbo
yarn install

# Install browser drivers for testing
yarn playwright install --with-deps

# Create a feature branch
git checkout -b fix/my-feature
```

### Building

```bash
# Build once
yarn build

# Watch for changes during development
yarn watch

# Build for production (includes rollup optimization)
yarn clean && yarn build
```

### Testing

```bash
# Run all tests (unit + browser)
yarn test

# Run only unit tests
yarn test:unit

# Run only browser tests
yarn test:browser

# Run specific browser
yarn test:browser --project=firefox
yarn test:browser --project=chrome

# Run in headed mode (see browser window)
yarn test:browser --headed

# Run specific test file
yarn test:browser src/tests/functional/drive_tests.js

# Run specific test line
yarn test:browser src/tests/functional/drive_tests.js:42

# Run test server for manual testing
yarn build && yarn start
# Visit http://localhost:9000/src/tests/fixtures/rendering.html
```

### Code Quality

```bash
# Lint JavaScript
yarn lint

# Format with Prettier (configured in .prettierrc.json)
# ESLint configured in .eslintrc.js
```

---

## Contributing

### Requirements

- Node.js >= 18
- Yarn package manager
- Understanding of browser APIs (History, Fetch, DOM)

### PR Guidelines

1. **Fork** the repository
2. **Branch** from `main` (e.g., `fix/issue-123`)
3. **Test** your changes with `yarn test`
4. **Lint** with `yarn lint`
5. **Commit** with clear messages
6. **Push** and open a PR with detailed description

### Code Style

- Follows ESLint configuration (`.eslintrc.js`)
- Formatted with Prettier (`.prettierrc.json`)
- Test coverage expected for new features
- Browser support: Modern browsers (ES2017+)

### Important Files

- `README.md`: Project overview
- `CONTRIBUTING.md`: Detailed contributing guide
- `CODE_OF_CONDUCT.md`: Community standards
- `MIT-LICENSE`: MIT License
- `package.json`: Dependencies and scripts
- `web-test-runner.config.mjs`: Test configuration
- `playwright.config.js`: Browser automation config
- `rollup.config.js`: Build configuration

---

## Best Practices

### 1. Organizing Behavior with Stimulus

Don't use `turbo:load` for complex initialization. Use Stimulus:

```html
<!-- HTML with Stimulus controller -->
<div data-controller="dashboard">
  <button data-action="click->dashboard#refresh">Refresh</button>
  <div data-dashboard-target="status"></div>
</div>
```

```javascript
// dashboard_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status"];

  connect() {
    console.log("Dashboard initialized");
  }

  refresh() {
    fetch("/dashboard/status")
      .then((r) => r.text())
      .then((html) => {
        this.statusTarget.innerHTML = html;
      });
  }
}
```

Stimulus automatically connects/disconnects with Turbo navigations.

---

### 2. Handling Caching

```html
<head>
  <!-- Default: cache enabled, shows preview -->

  <!-- Disable cache for dynamic pages -->
  <meta name="turbo-cache-control" content="no-cache" />

  <!-- Cache exists but never show preview -->
  <meta name="turbo-cache-control" content="no-preview" />
</head>
```

```javascript
// Or from JavaScript
if (isUserSpecific) {
  Turbo.cache.exemptPageFromCache();
}

// Listen before cache
document.addEventListener("turbo:before-cache", () => {
  // Reset temporary UI state
  closeAllModals();
  clearFormErrors();
});
```

---

### 3. Form Patterns

**Standard form with redirect**:

```html
<form action="/users" method="post">
  <input type="text" name="user[name]" />
  <button type="submit">Create</button>
</form>
```

Server should respond with 303 redirect on success.

**Form with Turbo Streams**:

```html
<form action="/messages" method="post" data-turbo-stream>
  <input type="text" name="content" />
  <button>Post</button>
</form>
```

Server responds with `Content-Type: text/vnd.turbo-stream.html` containing `<turbo-stream>` elements.

**Form targeting specific frame**:

```html
<form action="/comments" method="post" data-turbo-frame="comment-list">
  <textarea name="content"></textarea>
  <button>Comment</button>
</form>
```

---

### 4. Frame Patterns

**Independent segments**:

```html
<turbo-frame id="messages">
  <div class="messages"><!-- messages --></div>
  <form action="/messages"><!-- form --></form>
</turbo-frame>

<turbo-frame id="sidebar" src="/sidebar"> Loading sidebar... </turbo-frame>
```

**Lazy-loaded below fold**:

```html
<turbo-frame id="related-articles" src="/articles/related" loading="lazy">
  <!-- Loads only when scrolled into view -->
</turbo-frame>
```

**Breaking out of frame**:

```html
<!-- When user logs out, break out and reload -->
<head>
  <meta name="turbo-visit-control" content="reload" />
</head>
```

---

### 5. Morphing Strategy

```html
<head>
  <!-- Enable morphing for page refreshes -->
  <meta name="turbo-refresh-method" content="morph" />
  <meta name="turbo-refresh-scroll" content="preserve" />
</head>

<body>
  <!-- Mark elements that should never morph -->
  <div id="modals" data-turbo-permanent>
    <!-- Modals stay open across refreshes -->
  </div>

  <!-- Mark frame to refresh with morph -->
  <turbo-frame id="feed" refresh="morph" src="/feed">
    <!-- Loads new content, morphs into place -->
  </turbo-frame>
</body>
```

---

### 6. Stream Broadcasting

**Rails example** (automatic via turbo-rails):

```ruby
class Calendar < ApplicationRecord
  broadcasts_refreshes
end

# In view: <%= turbo_stream_from @calendar %>
# On update: @calendar.update(name: "New name")  # Broadcasts refresh to all clients
```

**Generic SSE/WebSocket**:

```html
<!-- Connect to SSE -->
<turbo-stream-source src="/events"></turbo-stream-source>

<!-- Or WebSocket -->
<turbo-stream-source src="wss://api.example.com/events"></turbo-stream-source>
```

---

### 7. Idempotent Transformations

Don't do this (breaks on cache restoration):

```javascript
// ❌ BAD: Not idempotent
document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-date]").forEach((el) => {
    insertDateHeader(el); // Inserts twice on back!
  });
});
```

Do this instead:

```javascript
// ✅ GOOD: Idempotent with marker
document.addEventListener("turbo:load", () => {
  document
    .querySelectorAll("[data-date]:not([data-date-processed])")
    .forEach((el) => {
      insertDateHeader(el);
      el.setAttribute("data-date-processed", "true");
    });
});

// ✅ Or detect the transformation itself
document.addEventListener("turbo:load", () => {
  const container = document.querySelector(".messages");
  const dateHeaders = container.querySelectorAll(".date-header");
  const lastDate = dateHeaders.length
    ? new Date(dateHeaders[dateHeaders.length - 1].textContent)
    : null;

  // Only insert if needed
});
```

---

### 8. Persisting Elements

```html
<!-- Shopping cart that persists across navigations -->
<div id="cart-counter" data-turbo-permanent>
  <strong>3 items</strong> | <a href="/cart">View Cart</a>
</div>

<script>
  document.addEventListener("turbo:load", () => {
    // Update cart when items change
    updateCart();
  });
</script>
```

---

### 9. Custom Rendering

Replace DOM instead of append:

```javascript
import { Idiomorph } from "idiomorph";

document.addEventListener("turbo:before-render", (event) => {
  event.detail.render = (currentElement, newElement) => {
    Idiomorph.morph(currentElement, newElement);
  };
});
```

Or for frames:

```javascript
document.addEventListener("turbo:before-frame-render", (event) => {
  event.detail.render = (currentFrame, newFrame) => {
    morphdom(currentFrame, newFrame, { childrenOnly: true });
  };
});
```

---

### 10. Prefetching Strategy

```html
<!-- Prefetch is enabled by default, with 100ms delay -->
<!-- Disable globally for slow connections -->
<meta name="turbo-prefetch" content="false" />

<!-- Or disable per-link -->
<a href="/expensive" data-turbo-prefetch="false">Don't Prefetch</a>

<!-- Preload important pages into cache -->
<a href="/frequently-visited" data-turbo-preload>Preload</a>
```

```javascript
// Smart prefetching based on network
document.addEventListener("turbo:before-prefetch", (event) => {
  const connection = navigator.connection;
  if (
    connection &&
    (connection.saveData || connection.effectiveType === "slow-2g")
  ) {
    event.preventDefault();
  }
});
```

---

## Repository Structure Quick Reference

```
hotwired/turbo/
├── src/
│   ├── core/              # Session, drive navigation, cache
│   │   ├── session.ts
│   │   ├── drive.ts
│   │   └── cache.ts
│   ├── elements/          # Custom element definitions
│   │   ├── frame_element.ts
│   │   └── stream_element.ts
│   ├── http/              # HTTP/Fetch abstraction
│   │   ├── fetch_request.ts
│   │   └── fetch_response.ts
│   ├── observers/         # DOM observers
│   │   ├── link_observer.ts
│   │   ├── form_observer.ts
│   │   └── prefetch_observer.ts
│   └── index.js           # Main entry point
├── dist/                  # Compiled output (ES2017 ESM + UMD)
├── tests/
│   ├── fixtures/          # HTML test pages
│   ├── functional/        # Playwright tests
│   └── unit/              # Unit tests
├── rollup.config.js       # Build configuration
├── web-test-runner.config.mjs
├── playwright.config.js
├── package.json
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── MIT-LICENSE
```

---

## Key Statistics

- **Version**: 8.0.20
- **Contributors**: 114+
- **Stars**: 7.2k+ on GitHub
- **Forks**: 475+
- **Releases**: 49+
- **Active Maintenance**: Ongoing (37signals)
- **Node Requirements**: >= 18

---

## Related Projects

- **Stimulus**: Modest JavaScript framework for behavior (complementary to Turbo)
- **turbo-rails**: Reference Rails integration for Turbo
- **turbo-android**: Native Android adapter
- **turbo-ios**: Native iOS adapter
- **Hotwire**: Complete documentation site
- **Mercure**: Protocol for server-sent updates

---

## Quick Start for Developers

1. **Basic installation**: `yarn add @hotwired/turbo`
2. **Import**: `import * as Turbo from "@hotwired/turbo"`
3. **Enable**: Turbo Drive automatically works with standard HTML links/forms
4. **Enhance**: Add `<turbo-frame>` and `<turbo-stream>` as needed
5. **Handle events**: Listen to `turbo:*` events for custom behavior
6. **Test**: Use `yarn test` before submitting changes

---

This document provides a complete reference for understanding and working with Turbo. For the latest updates, visit https://turbo.hotwired.dev or check the GitHub repository.
