import { Controller } from "@hotwired/stimulus";
import * as bootstrap from "bootstrap";

export default class extends Controller {
  static targets = [];

  connect() {
    this.initScrollspy();
  }

  initScrollspy() {
    const scrollspy = new bootstrap.ScrollSpy(document.body, {
      target: "#revenue_nav",
      offset: 200,
    });
  }

}
