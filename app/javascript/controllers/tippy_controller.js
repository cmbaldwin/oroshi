import { Controller } from "@hotwired/stimulus";

// tippy.js is loaded via importmap as a UMD bundle that attaches to window.tippy
// We import it for side effects only, then access via window
import "tippy.js";

export default class extends Controller {
  tippyInstance;
  static targets = [];

  connect() {
    // Access tippy from window since it's a UMD bundle
    if (typeof window.tippy === 'function') {
      this.tippyInstance = this.initTippy(this.element);
    } else {
      console.warn('tippy.js not loaded');
    }
  }

  initTippy(element) {
    // Basic options for all tooltips
    const defaultOptions = {
      allowHTML: true,
      duration: [300, 0],
      touch: "hold",
      followCursor: true,
    };

    // Merge options: basicOptions <- dataOptions <- expCardOptions (if exp_card class is present)
    const options = {
      ...defaultOptions,
      ...(element.classList.contains("exp_card") && this.expCardOptions())
    };

    return window.tippy(element, options);
  }

  expCardOptions() {
    // Options specific to exp_card
    const expCardOptions = {
      animation: 'scale',
      theme: 'exp_card',
      placement: 'bottom'
    };
    return expCardOptions;
  }

  disconnect() {
    if (this.tippyInstance) {
      this.tippyInstance.destroy();
    }
  }

}
