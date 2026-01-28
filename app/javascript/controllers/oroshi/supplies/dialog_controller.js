import Dialog from "@stimulus-components/dialog";

/**
 * Supplies Dialog Controller
 *
 * Extends the base @stimulus-components/dialog controller to:
 * 1. Dispatch a custom 'modal:close' event when the dialog closes
 * 2. Ensure proper cleanup and event handling for Turbo compatibility
 *
 * Usage:
 *   <div data-controller="oroshi--supplies--dialog" data-action="click->oroshi--supplies--dialog#backdropClose">
 *     <dialog data-oroshi--supplies--dialog-target="dialog">
 *       ...
 *       <button data-action="oroshi--supplies--dialog#close">Close</button>
 *     </dialog>
 *   </div>
 */
export default class extends Dialog {
  connect() {
    super.connect();

    // Listen for the native dialog close event to dispatch our custom event
    if (this.hasDialogTarget) {
      this.boundOnDialogClose = this.onDialogClose.bind(this);
      this.dialogTarget.addEventListener('close', this.boundOnDialogClose);
    }
  }

  disconnect() {
    if (this.hasDialogTarget && this.boundOnDialogClose) {
      this.dialogTarget.removeEventListener('close', this.boundOnDialogClose);
    }
    super.disconnect();
  }

  /**
   * Handle the native dialog close event
   */
  onDialogClose() {
    // Dispatch the custom modal:close event that the calendar controller expects
    document.dispatchEvent(new CustomEvent('modal:close', {
      bubbles: true,
      detail: { source: 'supplies-dialog' }
    }));
  }

  /**
   * Override close to ensure proper event dispatch
   */
  close() {
    super.close();
  }
}
