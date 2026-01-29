import { Controller } from "@hotwired/stimulus"
import { useClickOutside, useTransition } from "stimulus-use"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    useClickOutside(this)
    useTransition(this, {
      element: this.menuTarget,
      enterActive: "transition-all duration-200",
      enterFrom: "opacity-0 scale-95",
      enterTo: "opacity-100 scale-100",
      leaveActive: "transition-all duration-150",
      leaveFrom: "opacity-100 scale-100",
      leaveTo: "opacity-0 scale-95"
    })
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.menuTarget.classList.contains('show')) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add('show')
    this.buttonTarget.setAttribute('aria-expanded', 'true')
    this.enter()
  }

  close() {
    this.leave().then(() => {
      this.menuTarget.classList.remove('show')
      this.buttonTarget.setAttribute('aria-expanded', 'false')
    })
  }

  clickOutside(event) {
    if (this.menuTarget.classList.contains('show')) {
      this.close()
    }
  }
}
