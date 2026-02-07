import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import { useWindowResize } from "stimulus-use";

export default class extends Controller {
  static targets = ["orderModal", "navbar", "menuButton", "orderFilterForm"];

  connect() {
    useWindowResize(this);
    this.adjustNavbarForScreenSize();

    const dialog = this.orderDialog();
    if (dialog) {
      this.boundOnDialogClose = this.onDialogClose.bind(this);
      dialog.addEventListener("close", this.boundOnDialogClose);
    }
  }

  disconnect() {
    const dialog = this.orderDialog();
    if (dialog && this.boundOnDialogClose) {
      dialog.removeEventListener("close", this.boundOnDialogClose);
    }
  }

  orderDialog() {
    if (!this.hasOrderModalTarget) {
      return null;
    }

    return this.orderModalTarget.querySelector("dialog[data-oroshi--orders--order-dialog-target='dialog']") ||
      this.orderModalTarget.querySelector("dialog[data-dialog-target='dialog']");
  }

  windowResize(_event) {
    this.adjustNavbarForScreenSize();
  }

  onDialogClose() {
    const turboFrame = this.orderModalTarget.querySelector("turbo-frame#orders_modal_content");
    const form = this.orderModalTarget.querySelector("form");

    if (turboFrame) {
      turboFrame.innerHTML = this.spinnerHtml();
    }

    if ((form && form.dataset.model_altered === "true") && turboFrame?.dataset.refresh) {
      window.location.reload();
    }
  }

  spinnerHtml() {
    return `
      <div class="d-flex justify-content-center">
        <div class="spinner-border" role="status">
          <span class="visually-hidden">読み込み中...</span>
        </div>
      </div>
    `;
  }

  adjustNavbarForScreenSize() {
    const mediumBreakpoint = 768;
    const screenWidth = window.innerWidth;

    if (screenWidth <= mediumBreakpoint) {
      this.navbarTarget.classList.remove("show");
      this.menuButtonTarget.classList.remove("d-none");
    } else {
      this.navbarTarget.classList.add("show");
      this.menuButtonTarget.classList.add("d-none");
    }
  }

  toggleActiveLink(event) {
    const turboFrame = event.target.dataset.turboFrame;
    if (turboFrame) {
      const frame = document.querySelector(`turbo-frame#${turboFrame}`);
      if (frame) {
        frame.innerHTML = this.spinnerHtml();
      }
    }

    const nav = event.target.closest(".nav");
    const navLinks = nav.querySelectorAll(".nav-link");
    navLinks.forEach((link) => {
      link.classList.remove("active");
    });

    event.target.closest(".nav-link").classList.add("active");
  }

  showModal() {
    const dialog = this.orderDialog();
    if (dialog) {
      dialog.showModal();
    }
  }

  orderModalFormSubmit(event) {
    const form = event.target;
    const dialog = this.orderDialog();
    const url = form.action;
    const method = form.method;
    const refreshTarget = form.dataset.refreshTarget;
    const formData = new FormData(form);

    fetch(url, {
      method: method,
      body: formData
    })
      .then((response) => {
        if (response.ok) {
          dialog?.close();
          const frame = document.querySelector(`turbo-frame#${refreshTarget}`);
          frame?.reload();
        } else {
          return response.text();
        }
      })
      .then((html) => {
        if (html) {
          const frame = this.orderModalTarget.querySelector("turbo-frame#orders_modal_content");
          if (frame) {
            frame.innerHTML = html;
          }
        }
      });
  }

  onDestroyOrderFromModal(_event) {
    const dialog = this.orderDialog();
    dialog?.close();

    const turboFrame = this.orderModalTarget.querySelector("turbo-frame#orders_modal_content");
    if (turboFrame) {
      turboFrame.innerHTML = this.spinnerHtml();
    }
  }

  inventoryUpdate(event) {
    const form = event.target;
    const submitButton = form.querySelector(".btn");
    submitButton.classList.remove("btn-primary");
    submitButton.classList.add("btn-yellow");
    submitButton.value = "更新中...";

    const refreshTarget = form.dataset.refreshTarget;
    if (refreshTarget) {
      document.querySelector(`turbo-frame#${refreshTarget}`)?.reload();
    }
  }

  resetOrderFilters(event) {
    event.preventDefault();

    const resetPath = event.currentTarget?.dataset?.resetPath;
    if (resetPath) {
      Turbo.visit(resetPath, { frame: event.currentTarget.dataset.turboFrame || "orders_dashboard" });
      return;
    }

    const form = event.currentTarget.form || this.orderFilterFormTarget.querySelector("form");
    if (!form) {
      return;
    }

    form.querySelectorAll("select").forEach((select) => {
      Array.from(select.options).forEach((option) => {
        option.selected = false;
      });
    });

    form.requestSubmit();
  }
}
