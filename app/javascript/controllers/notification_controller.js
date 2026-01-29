import { Controller } from "@hotwired/stimulus"
import { useTransition } from "stimulus-use"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 3000 }
  }

  connect() {
    useTransition(this, {
      element: this.element,
      enterActive: "transition-opacity duration-300",
      enterFrom: "opacity-0",
      enterTo: "opacity-100",
      leaveActive: "transition-opacity duration-300",
      leaveFrom: "opacity-100",
      leaveTo: "opacity-0"
    })

    // Enter animation
    this.enter()

    // Auto-dismiss after delay
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.delayValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  hide() {
    this.leave().then(() => {
      this.element.remove()
    })
  }
}
