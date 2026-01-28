// DEPRECATED: This controller is no longer used. 
// Notifications are now handled by the Stimulus Notification component (@stimulus-components/notification)
// See: docs/STIMULUS_COMPONENTS.md for implementation details

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    // fade out element after 4 seconds
    setTimeout(() => {
      this.element.classList.add("d-none");
    }, 3000);
  }

}
