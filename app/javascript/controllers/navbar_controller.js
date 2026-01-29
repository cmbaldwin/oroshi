import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["toggle", "collapse"]

  connect() {
    // Initialize Bootstrap collapse component
    if (this.hasCollapseTarget) {
      this.collapseInstance = new Collapse(this.collapseTarget, {
        toggle: false
      })
    }

    // Handle toggle button click
    if (this.hasToggleTarget) {
      this.toggleTarget.addEventListener('click', this.handleToggle.bind(this))
    }
  }

  disconnect() {
    if (this.collapseInstance) {
      this.collapseInstance.dispose()
    }
  }

  handleToggle(event) {
    event.preventDefault()
    if (this.collapseInstance) {
      this.collapseInstance.toggle()
    }
  }
}
