import Dialog from "@stimulus-components/dialog";

/**
 * Orders Dialog Controller
 *
 * Extends @stimulus-components/dialog to dispatch a custom close event
 * for Turbo/Stimulus consumers that need to react when the modal closes.
 */
export default class extends Dialog {
  connect() {
    super.connect();

    if (this.hasDialogTarget) {
      this.boundOnDialogClose = this.onDialogClose.bind(this);
      this.dialogTarget.addEventListener("close", this.boundOnDialogClose);
    }
  }

  disconnect() {
    if (this.hasDialogTarget && this.boundOnDialogClose) {
      this.dialogTarget.removeEventListener("close", this.boundOnDialogClose);
    }

    super.disconnect();
  }

  onDialogClose() {
    document.dispatchEvent(new CustomEvent("modal:close", {
      bubbles: true,
      detail: { source: "orders-dialog" }
    }));
  }

  close() {
    super.close();
  }
}
