# Stimulus Components Guide

This document provides a quick reference for all available Stimulus Components and their implementation patterns for agents and developers.

**Installation Status**: ✅ Installed and registered in `/app/javascript/controllers/index.js`

## Quick Installation Reference

To install a new component:

```bash
bin/importmap pin @stimulus-components/component-name
```

Then register it in `app/javascript/controllers/index.js`:

```javascript
import ComponentName from "@stimulus-components/component-name";
application.register("component-name", ComponentName);
```

---

## Available Components

### Interaction Components

#### 1. **Animated Number**

**Package**: `@stimulus-components/animated-number`  
**Purpose**: Animates numbers from one value to another  
**Quick Implementation**:

```html
<div data-controller="animated-number" data-animated-number-value="1000">0</div>
```

#### 2. **Auto Submit**

**Package**: `@stimulus-components/auto-submit`  
**Purpose**: Automatically submits forms when inputs change  
**Quick Implementation**:

```html
<form data-controller="auto-submit">
  <input type="text" data-action="change->auto-submit#submit" />
</form>
```

#### 3. **Carousel**

**Package**: `@stimulus-components/carousel`  
**Purpose**: Create responsive image carousels  
**Quick Implementation**:

```html
<div data-controller="carousel" class="carousel">
  <div class="carousel-item">Item 1</div>
  <div class="carousel-item">Item 2</div>
  <button data-action="carousel#previous">Previous</button>
  <button data-action="carousel#next">Next</button>
</div>
```

#### 4. **Character Counter**

**Package**: `@stimulus-components/character-counter`  
**Purpose**: Counts characters in text inputs  
**Quick Implementation**:

```html
<div data-controller="character-counter">
  <textarea data-character-counter-target="field"></textarea>
  <span data-character-counter-target="count">0</span>
</div>
```

#### 5. **Checkbox Select All**

**Package**: `@stimulus-components/checkbox-select-all`  
**Purpose**: Selects/deselects all checkboxes at once  
**Quick Implementation**:

```html
<div data-controller="checkbox-select-all">
  <input type="checkbox" data-action="checkbox-select-all#toggleAll" />
  <input type="checkbox" name="items" value="1" />
  <input type="checkbox" name="items" value="2" />
</div>
```

#### 6. **Clipboard**

**Package**: `@stimulus-components/clipboard`  
**Purpose**: Copies text to clipboard with visual feedback  
**Quick Implementation**:

```html
<div data-controller="clipboard">
  <input type="text" data-clipboard-target="source" value="Copy me!" />
  <button data-action="clipboard#copy">Copy</button>
</div>
```

#### 7. **Color Picker**

**Package**: `@stimulus-components/color-picker`  
**Purpose**: Interactive color selection  
**Quick Implementation**:

```html
<div data-controller="color-picker">
  <input type="text" data-color-picker-target="input" />
  <div data-color-picker-target="picker"></div>
</div>
```

#### 8. **Confirmation**

**Package**: `@stimulus-components/confirmation`  
**Purpose**: Confirms actions before execution  
**Quick Implementation**:

```html
<div data-controller="confirmation">
  <button
    data-action="confirmation#confirm"
    data-confirmation-message-value="Are you sure?"
  >
    Delete
  </button>
</div>
```

#### 9. **Content Loader** ⭐

**Package**: `@stimulus-components/content-loader`  
**Purpose**: Loading skeleton screens and placeholders  
**Quick Implementation**:

```html
<div data-controller="content-loader">
  <div data-content-loader-target="placeholder">
    <div class="skeleton-line"></div>
  </div>
  <div data-content-loader-target="content" class="d-none">
    <!-- Actual content -->
  </div>
</div>
```

#### 10. **Dialog** ⭐ (CURRENTLY USING)

**Package**: `@stimulus-components/dialog`  
**Purpose**: Native HTML `<dialog>` element controller for modals  
**Status**: Installed ✅  
**Quick Implementation**:

```html
<div data-controller="dialog">
  <dialog data-dialog-target="dialog">
    <p>Modal content</p>
    <button data-action="dialog#close">Close</button>
  </dialog>
  <button data-action="dialog#open">Open Modal</button>
</div>
```

**Key Features**:

- Native HTML5 `<dialog>` element
- Backdrop click to close: `data-action="click->dialog#backdropClose"`
- Configuration: `data-dialog-open-value="false"` (open by default)
- Supports animations via transitions

#### 11. **Dropdown**

**Package**: `@stimulus-components/dropdown`  
**Purpose**: Toggleable dropdown menus  
**Quick Implementation**:

```html
<div data-controller="dropdown">
  <button data-action="dropdown#toggle">Menu</button>
  <ul data-dropdown-target="menu" class="d-none">
    <li><a href="#">Option 1</a></li>
    <li><a href="#">Option 2</a></li>
  </ul>
</div>
```

#### 12. **Glow**

**Package**: `@stimulus-components/glow`  
**Purpose**: Adds glow effect on mouse movement  
**Quick Implementation**:

```html
<div data-controller="glow" data-glow-intensity-value="50">
  <!-- Content -->
</div>
```

#### 13. **Lightbox**

**Package**: `@stimulus-components/lightbox`  
**Purpose**: Image gallery with zoom functionality  
**Quick Implementation**:

```html
<div data-controller="lightbox">
  <a href="/image.jpg" data-lightbox-target="image">
    <img src="/thumb.jpg" alt="Thumbnail" />
  </a>
</div>
```

#### 14. **Notification** ⭐ (CURRENTLY USING)

**Package**: `@stimulus-components/notification`  
**Purpose**: Auto-dismissing notifications/alerts  
**Status**: Installed ✅  
**Quick Implementation**:

```html
<div
  data-controller="notification"
  data-notification-delay-value="3000"
  class="alert alert-success"
>
  <p>Success message</p>
  <button data-action="notification#hide">Dismiss</button>
</div>
```

**Key Features**:

- Auto-dismisses after delay (default: 3000ms)
- Optional `data-notification-hidden-value="true"` to hide initially
- Trigger programmatically: `document.dispatchEvent(new CustomEvent('eventName'))`
- Animation support via transitions

#### 15. **Password Visibility**

**Package**: `@stimulus-components/password-visibility`  
**Purpose**: Toggle password field visibility  
**Quick Implementation**:

```html
<div data-controller="password-visibility">
  <input type="password" data-password-visibility-target="input" />
  <button data-action="password-visibility#toggle">Show</button>
</div>
```

#### 16. **Places Autocomplete**

**Package**: `@stimulus-components/places-autocomplete`  
**Purpose**: Google Places autocomplete integration  
**Quick Implementation**:

```html
<div data-controller="places-autocomplete">
  <input
    type="text"
    data-places-autocomplete-target="input"
    placeholder="Enter location"
  />
  <ul data-places-autocomplete-target="results"></ul>
</div>
```

#### 17. **Popover**

**Package**: `@stimulus-components/popover`  
**Purpose**: Contextual popup overlays  
**Quick Implementation**:

```html
<div data-controller="popover">
  <button data-action="popover#toggle">Show Info</button>
  <div data-popover-target="popover" class="d-none">
    <p>Popover content</p>
  </div>
</div>
```

#### 18. **Prefetch**

**Package**: `@stimulus-components/prefetch`  
**Purpose**: Prefetch links on hover for faster navigation  
**Quick Implementation**:

```html
<div data-controller="prefetch">
  <a href="/page" data-prefetch-target="link">Link</a>
</div>
```

#### 19. **Rails Nested Form**

**Package**: `@stimulus-components/rails-nested-form`  
**Purpose**: Dynamically add/remove nested form fields  
**Quick Implementation**:

```html
<div data-controller="nested-form">
  <div data-nested-form-target="container">
    <input name="items[0][name]" />
  </div>
  <button data-action="nested-form#addItem">Add Item</button>
</div>
```

#### 20. **Read More**

**Package**: `@stimulus-components/read-more`  
**Purpose**: "Read more" / "Read less" toggle  
**Quick Implementation**:

```html
<div data-controller="read-more" data-read-more-height-value="100">
  <p>Long text content...</p>
  <button data-action="read-more#toggle">Read More</button>
</div>
```

#### 21. **Remote Rails**

**Package**: `@stimulus-components/remote-rails`  
**Purpose**: Handle Rails remote forms with better control  
**Quick Implementation**:

```html
<form data-controller="remote-rails" data-action="submit->remote-rails#submit">
  <input type="text" name="search" />
  <button type="submit">Search</button>
</form>
```

#### 22. **Reveal Controller**

**Package**: `@stimulus-components/reveal-controller`  
**Purpose**: Reveal hidden content on scroll  
**Quick Implementation**:

```html
<div data-controller="reveal-controller" class="hidden">
  <p>This appears on scroll</p>
</div>
```

#### 23. **Scroll Progress**

**Package**: `@stimulus-components/scroll-progress`  
**Purpose**: Display page scroll progress bar  
**Quick Implementation**:

```html
<div data-controller="scroll-progress">
  <div data-scroll-progress-target="bar" class="progress-bar"></div>
</div>
```

#### 24. **Scroll Reveal**

**Package**: `@stimulus-components/scroll-reveal`  
**Purpose**: Reveal elements with scroll animations  
**Quick Implementation**:

```html
<div data-controller="scroll-reveal" class="fade-in">
  <p>Reveals with fade animation</p>
</div>
```

#### 25. **Scroll To**

**Package**: `@stimulus-components/scroll-to`  
**Purpose**: Smooth scroll to elements  
**Quick Implementation**:

```html
<div data-controller="scroll-to">
  <button data-action="scroll-to#scroll" data-scroll-to-target-value="#section">
    Scroll to Section
  </button>
  <section id="section">Content</section>
</div>
```

#### 26. **Sortable**

**Package**: `@stimulus-components/sortable`  
**Purpose**: Drag-and-drop reorderable lists  
**Quick Implementation**:

```html
<div data-controller="sortable">
  <ul data-sortable-target="items">
    <li data-sortable-id="1">Item 1</li>
    <li data-sortable-id="2">Item 2</li>
  </ul>
</div>
```

#### 27. **Sound**

**Package**: `@stimulus-components/sound`  
**Purpose**: Play audio files  
**Quick Implementation**:

```html
<div data-controller="sound">
  <button data-action="sound#play" data-sound-url-value="/notify.mp3">
    Play Sound
  </button>
</div>
```

#### 28. **Textarea Autogrow**

**Package**: `@stimulus-components/textarea-autogrow`  
**Purpose**: Automatically expand textarea as user types  
**Quick Implementation**:

```html
<div data-controller="textarea-autogrow">
  <textarea data-textarea-autogrow-target="textarea"></textarea>
</div>
```

#### 29. **Timeago**

**Package**: `@stimulus-components/timeago`  
**Purpose**: Display "time ago" formatting (e.g., "2 hours ago")  
**Quick Implementation**:

```html
<div data-controller="timeago">
  <time data-timeago-target="element" datetime="2024-01-28T10:00:00Z">
    2024-01-28 10:00:00
  </time>
</div>
```

#### 30. **Chartjs**

**Package**: `@stimulus-components/chartjs`  
**Purpose**: Chart.js integration for data visualization  
**Quick Implementation**:

```html
<div data-controller="chartjs">
  <canvas
    data-chartjs-target="canvas"
    data-chartjs-type-value="line"
    data-chartjs-data-value='{"labels":["A","B"],"datasets":[...]}'
  ></canvas>
</div>
```

---

## Implementation Patterns

### Pattern 1: Quick Installation & Use

```bash
# 1. Install component
bin/importmap pin @stimulus-components/component-name

# 2. Register in controllers/index.js
import ComponentName from "@stimulus-components/component-name";
application.register("component-name", ComponentName);

# 3. Use in ERB
<div data-controller="component-name">
  <!-- Markup -->
</div>
```

### Pattern 2: Configuration Values

Most components accept `data-*-value` attributes:

```html
<div
  data-controller="notification"
  data-notification-delay-value="5000"
  data-notification-hidden-value="false"
>
  Content
</div>
```

### Pattern 3: Targets

Access DOM elements from the controller:

```html
<div data-controller="component">
  <input data-component-target="input" />
  <div data-component-target="output"></div>
</div>
```

### Pattern 4: Actions

Respond to user interactions:

```html
<button data-action="component#method">Click me</button>
<button data-action="click->component#method">Click me</button>
<form data-action="submit->component#submit"></form>
```

### Pattern 5: Events & Custom Triggers

Some components support custom events:

```javascript
// Trigger notification programmatically
const event = new CustomEvent("show-notification");
window.dispatchEvent(event);
```

### Pattern 6: CSS Animation Support

Many components work with transition classes:

```html
<div
  data-controller="notification"
  class="transition transform duration-1000 hidden"
  data-transition-enter-from="opacity-0 translate-x-6"
  data-transition-enter-to="opacity-100 translate-x-0"
  data-transition-leave-from="opacity-100 translate-x-0"
  data-transition-leave-to="opacity-0 translate-x-6"
>
  Content
</div>
```

---

## Migration Guide

### From Custom Notice Controller to Stimulus Notification

**Old**:

```html
<div data-controller="notice" class="alert">
  <p><%= notice %></p>
</div>
```

**New**:

```html
<div
  data-controller="notification"
  data-notification-delay-value="3000"
  class="alert alert-success"
>
  <p><%= notice %></p>
  <button data-action="notification#hide">Close</button>
</div>
```

### From Ultimate Turbo Modal to Stimulus Dialog

**Old**:

```html
<div data-controller="modal">
  <div class="modal-content">Content</div>
</div>
```

**New**:

```html
<div data-controller="dialog">
  <dialog data-dialog-target="dialog">
    <p>Content</p>
    <button data-action="dialog#close">Close</button>
  </dialog>
  <button data-action="dialog#open">Open</button>
</div>
```

---

## Best Practices for Agents

1. **Always check if component exists** before implementing custom logic
2. **Use `data-*-target` selectors** instead of class-based selectors for reliability
3. **Combine with Bootstrap classes** for consistent styling (e.g., `alert alert-success`)
4. **Test animations** in development to ensure smooth UX
5. **Use configuration values** instead of hardcoding behavior
6. **Leverage Turbo frames** with Stimulus Components for dynamic content
7. **Document custom implementations** that extend stimulus components

---

## Common Configuration Reference

| Component         | Key Config                                | Values             | Example           |
| ----------------- | ----------------------------------------- | ------------------ | ----------------- |
| Notification      | `data-notification-delay-value`           | ms (default: 3000) | `3000`, `5000`    |
| Notification      | `data-notification-hidden-value`          | boolean            | `true`, `false`   |
| Dialog            | `data-dialog-open-value`                  | boolean            | `true`, `false`   |
| Textarea Autogrow | `data-textarea-autogrow-max-height-value` | px                 | `400`             |
| Character Counter | -                                         | -                  | -                 |
| Confirmation      | `data-confirmation-message-value`         | string             | `"Are you sure?"` |

---

## Repository Links

- **Official Docs**: https://www.stimulus-components.com/docs/
- **GitHub**: https://github.com/stimulus-components/stimulus-components
- **NPM**: https://www.npmjs.com/org/stimulus-components

---

## Notes

- **UI Agnostic**: All components work with any CSS framework
- **Battle-tested**: Used in production by hundreds of developers
- **No dependencies**: Each component is independent
- **Open Source**: MIT licensed
- **Active Maintenance**: Regular updates and bug fixes
