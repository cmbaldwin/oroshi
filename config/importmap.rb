# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Application, hotwire, turbo, stimulus
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Stimulus controllers - need explicit pins for index and application
pin "controllers", to: "controllers/index.js", preload: true
pin "controllers/application", to: "controllers/application.js", preload: true
# Pin all controller files from engine's app/javascript/controllers directory
# Must use absolute path via Engine.root so it works when loaded by parent apps
if defined?(Oroshi::Engine)
  pin_all_from Oroshi::Engine.root.join("app/javascript/controllers"), under: "controllers", to: "controllers"
else
  # Fallback for test/dummy or when engine isn't fully loaded
  pin_all_from "app/javascript/controllers", under: "controllers", to: "controllers"
end

# Channels/ActionCable
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"

# ActiveStorage
pin "@rails/activestorage", to: "activestorage.esm.js"

# Bootstrap - using browser-ready ESM via jsdelivr +esm
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/+esm", preload: true
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/+esm", preload: true

# Shuffle
pin "shufflejs", to: "https://unpkg.com/shufflejs@6.1.0"
pin "draggable", to: "https://cdn.jsdelivr.net/npm/@shopify/draggable/build/esm/index.mjs"
pin "draggable-plugins", to: "https://cdn.jsdelivr.net/npm/@shopify/draggable/build/esm/Plugins/index.mjs"
pin "muuri", to: "https://cdn.jsdelivr.net/npm/muuri@0.9.5/dist/muuri.min.js"

# Tippy.js - browser-ready ESM via jsdelivr +esm
pin "tippy.js", to: "https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/+esm"

# Chartkick - use CDN (not currently used in app)
# pin "chartkick", to: "https://cdn.jsdelivr.net/npm/chartkick@5.0.1/dist/chartkick.esm.js"
# pin "Chart.bundle", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.js"

# FullCalendar
pin "fullcalendar" # @6.1.10 vendored (copy and paste with `export default FullCalendar;` at end, also copied and pasted Bootstrap5 module to end)
pin "moment" # @2.29.4 vendored (copy and paste)

# Flatpickr
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js"
pin "flatpickr/dist/l10n/ja", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/l10n/ja.js"
pin "ultimate_turbo_modal" # @2.2.1
pin "@stimulus-components/dialog", to: "@stimulus-components--dialog.js" # @1.0.1
pin "@stimulus-components/notification", to: "@stimulus-components--notification.js" # @3.0.0
pin "stimulus-use" # @0.52.3
