# Bootstrap 5 Component Standards

This document defines standardized Bootstrap 5 components for consistent UI design across the Oroshi application.

## Design Principles

1. **Use Bootstrap 5 utility classes** - Leverage the framework's built-in classes
2. **NO custom gradients** - Keep styling simple and maintainable
3. **Follow Oroshi color scheme** - Use theme variables from funabiki.scss
4. **Accessibility first** - Ensure proper contrast and keyboard navigation

## Color Scheme

Defined in `app/assets/stylesheets/funabiki.scss`:

```scss
$primary: #4ecdc4;    // Greenish-cyan (brand color)
$secondary: #6ba3d4;  // Lynx-screen-blue
$success: #72dda5;    // Synthetic-spearmint
$warning: #ef8354;    // Ochre
$danger: #cc4b4b;     // Terra
$light: #f8f9fa;      // Bootstrap light
$dark: #343a40;       // Bootstrap dark
```

## Button Components

### Primary Actions

Use for main CTAs, form submissions, and primary workflow actions:

```erb
<%= button_tag "Submit", class: "btn btn-primary" %>
<%= link_to "Continue", next_path, class: "btn btn-primary" %>
```

### Secondary Actions

Use for alternative actions, "back" buttons, and secondary workflows:

```erb
<%= link_to "Back", previous_path, class: "btn btn-secondary" %>
<%= button_tag "Cancel", class: "btn btn-secondary" %>
```

### Outline Buttons

Use for less prominent actions within a button group:

```erb
<%= link_to "Skip", skip_path, class: "btn btn-outline-secondary" %>
<%= button_tag "Reset", class: "btn btn-outline-primary" %>
```

### Success/Danger Actions

Use for contextual actions with clear outcomes:

```erb
<%= button_tag "Save", class: "btn btn-success" %>
<%= button_tag "Delete", class: "btn btn-danger" %>
```

### Button Sizes

Bootstrap 5 provides size modifiers:

```erb
<%= button_tag "Large", class: "btn btn-primary btn-lg" %>
<%= button_tag "Normal", class: "btn btn-primary" %>
<%= button_tag "Small", class: "btn btn-primary btn-sm" %>
```

## Onboarding Wizard Buttons

### Navigation Buttons

```erb
<!-- Skip button (less prominent) -->
<%= link_to "Skip for now", 
    oroshi_onboarding_skip_path, 
    method: :post,
    class: "btn btn-outline-secondary" %>

<!-- Back button -->
<%= link_to "Back", 
    oroshi_onboarding_path(prev_step), 
    class: "btn btn-secondary" %>

<!-- Next/Continue button (primary action) -->
<%= button_tag "Continue", 
    type: "submit", 
    form: "onboarding-form", 
    class: "btn btn-primary" %>
```

### Button Groups

```erb
<div class="btn-group" role="group">
  <%= link_to "Back", prev_path, class: "btn btn-secondary" %>
  <%= button_tag "Continue", class: "btn btn-primary" %>
</div>
```

## Form Buttons

### Standard Form Actions

```erb
<div class="form-actions d-flex gap-2 justify-content-end">
  <%= link_to "Cancel", cancel_path, class: "btn btn-secondary" %>
  <%= button_tag "Save", type: "submit", class: "btn btn-primary" %>
</div>
```

### Destructive Actions

Always use `btn-danger` for delete/remove actions:

```erb
<%= button_tag "Delete", 
    data: { confirm: "Are you sure?" }, 
    class: "btn btn-danger" %>
```

## Modal Buttons

### Modal Footer Actions

```erb
<div class="modal-footer">
  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
    Close
  </button>
  <%= button_tag "Save changes", type: "submit", class: "btn btn-primary" %>
</div>
```

## Utility Classes

### Spacing

Use Bootstrap spacing utilities instead of custom CSS:

```erb
<!-- Horizontal gap between buttons -->
<div class="d-flex gap-2">
  <%= button_tag "Cancel", class: "btn btn-secondary" %>
  <%= button_tag "Save", class: "btn btn-primary" %>
</div>

<!-- Margin utilities -->
<%= button_tag "Action", class: "btn btn-primary mt-3 me-2" %>
```

### Width

```erb
<!-- Full width -->
<%= button_tag "Submit", class: "btn btn-primary w-100" %>

<!-- Auto width (default) -->
<%= button_tag "Submit", class: "btn btn-primary" %>
```

## Migration Guide

### Replacing Custom Button Classes

| Old Class | New Class | Notes |
|-----------|-----------|-------|
| `btn-onboarding-next` | `btn btn-primary` | Remove gradient background |
| `btn-onboarding-back` | `btn btn-secondary` | Simpler solid color |
| `btn-onboarding-skip` | `btn btn-outline-secondary` | Less prominent outline style |
| `btn-onboarding-modal-save` | `btn btn-primary` | Standard primary action |
| `btn-onboarding-modal-close` | `btn btn-secondary` | Standard secondary action |

### Custom Classes to Remove

These custom button classes should be removed from `onboarding.scss`:

- `.btn-onboarding-skip`
- `.btn-onboarding-back`
- `.btn-onboarding-next`
- `.btn-onboarding-modal-close`
- `.btn-onboarding-modal-save`

## Best Practices

1. **Consistency**: Use the same button style for the same action across the app
2. **Contrast**: Ensure sufficient color contrast (WCAG AA minimum)
3. **Hierarchy**: Primary action should be visually prominent (btn-primary)
4. **Spacing**: Use Bootstrap gap utilities (`gap-2`, `gap-3`) between buttons
5. **Loading States**: Use disabled state and spinners for async actions

```erb
<%= button_tag type: "submit", class: "btn btn-primary", 
    data: { disable_with: "Saving..." } do %>
  Save
<% end %>
```

## References

- [Bootstrap 5 Buttons](https://getbootstrap.com/docs/5.3/components/buttons/)
- [Bootstrap 5 Button Group](https://getbootstrap.com/docs/5.3/components/button-group/)
- [Bootstrap 5 Utilities](https://getbootstrap.com/docs/5.3/utilities/spacing/)
