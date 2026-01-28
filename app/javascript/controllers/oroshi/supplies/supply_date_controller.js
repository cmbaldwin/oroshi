import { Controller } from "@hotwired/stimulus";
import { useIdle, useVisibility } from "stimulus-use";

export default class extends Controller {
  static targets = ['input', 'supplierColumn', 'entryLink', 'supplyEntryFrame'];

  connect() {
    // 3 minute (180000ms) inactivity refresh using stimulus-use
    useIdle(this, { ms: 180000, initialState: false });
    useVisibility(this);

    this.keyBindings();
    this.boundHistoryStateChanged = this.historyStateChanged.bind(this);
    window.addEventListener('popstate', this.boundHistoryStateChanged);
  }

  disconnect() {
    if (this.boundHistoryStateChanged) {
      window.removeEventListener('popstate', this.boundHistoryStateChanged);
    }
  }

  /**
   * Called by useIdle when user becomes idle (3 minutes of inactivity)
   */
  away() {
    window.location.reload();
  }

  /**
   * Called by useVisibility when page becomes hidden
   * Note: useIdle handles this automatically, but we can add extra logic here if needed
   */
  invisible() {
    // The idle timer continues to run when the page is hidden
  }

  /**
   * Called by useVisibility when page becomes visible again
   */
  visible() {
    // User returned to the page - idle timer will reset on next activity
  }

  historyStateChanged(_event) {
    // Links to this page come from Turbo.visit on the calendar page for supplies,
    // so we need to manually perform visit if the back button is pressed
    // because the page is not properly loaded from the Turbo cache
    Turbo.visit(window.location.href, { action: "advance" });
    window.removeEventListener('popstate', this.boundHistoryStateChanged);
  }

  selectEntry(event) {
    // add the loading overlay to the entry card
    const entryCard = this.element.querySelector('#list-entry-tab .card')
    entryCard.insertAdjacentHTML('afterbegin', window.loading_overlay);
    // Remove all 'show active' classes from entryLinks parents form, and add to the clicked entryLink parent form
    this.entryLinkTargets.forEach(entryLink => {
      let entryLinkForm = entryLink.closest('form');
      entryLinkForm.classList.remove('show', 'active');
      // if the button within the form has text-light, change it to text-dark
      let button = entryLinkForm.querySelector('.btn');
      button.classList.remove('text-light');
      button.classList.add('text-dark');
    });
    const thisForm = event.target.closest('form');
    thisForm.classList.add('show', 'active');
    // if the button within the form has text-dark, change it to text-light
    let button = thisForm.querySelector('.btn');
    button.classList.remove('text-dark');
    button.classList.add('text-light');
  }

  keyBindings() {
    document.addEventListener('keydown', (event) => {
      const currentInput = document.activeElement;
      if (!currentInput.classList.contains('form-control') && this.hasInputTarget) {
        return this.inputTargets[0].focus();
      }

      switch (event.key) {
        case 'ArrowLeft':
          this.changeColumn(event, currentInput, 'left');
          break;
        case 'ArrowRight':
          this.changeColumn(event, currentInput, 'right');
          break;
        case 'ArrowUp':
          this.changeRow(event, currentInput, 'up');
          break;
        case 'ArrowDown':
          this.changeRow(event, currentInput, 'down');
          break;
        case 'Enter':
          this.changeColumn(event, currentInput, 'right');
        default:
          // code for other keys
          break;
      }
    });
  }

  changeColumn(event, currentInput, direction) {
    event.preventDefault();

    // find index of current input's parent supplierColumn within visible supplierColumns and focus on previous supplierColumn's first input
    const supplierColumns = this.supplierColumnTargets.filter(column => column.offsetParent !== null);
    const currentSupplierColumn = currentInput.closest('.supplier-column');
    const currentSupplierIndex = supplierColumns.indexOf(currentSupplierColumn);
    const currentInputIndex = Array.from(currentSupplierColumn.querySelectorAll('.quantity.form-control')).indexOf(currentInput);
    let targetIndex = direction === 'left' ? currentSupplierIndex - 1 : currentSupplierIndex + 1;
    targetIndex = ((targetIndex % supplierColumns.length) + supplierColumns.length) % supplierColumns.length;

    const targetInput = supplierColumns[targetIndex].querySelectorAll('.quantity.form-control')[currentInputIndex];
    // if target input is disabled try the next supplier column until we find an enabled input
    console.log(targetInput);
    if (targetInput && targetInput.disabled) {
      this.changeColumn(event, targetInput, direction);
    } else if (targetInput) {
      targetInput.select();
    }
  }

  changeRow(event, currentInput, direction) {
    event.preventDefault();

    // find index of current input within its parent supplierColumn and focus on previous/next input in the same column
    const inputs = Array.from(currentInput.closest('.supplier-column').querySelectorAll('.quantity.form-control:not([disabled])'));
    const currentIndex = inputs.indexOf(currentInput);
    const targetIndex = direction === 'up' ? currentIndex - 1 : currentIndex + 1;

    const targetInput = inputs[targetIndex];
    if (targetInput) {
      targetInput.select();
    }
  }

  onChange(event) {
    // Find nearest .handle, run an animation
    this.colorHandles(event);
    Turbo.navigator.submitForm(event.target.form);
  }

  colorHandles(event) {
    const nearestHandle = (element) => element.closest('.input-group').querySelector('.handle');
    const supplierColumn = event.target.closest('.supplier-column');
    // Input Handle
    const inputHandle = nearestHandle(event.target);
    // Line Subtotal Handle
    const colummnIndex = Array.from(supplierColumn.querySelectorAll('form')).indexOf(event.target.form);
    const lineSubtotalHandle = nearestHandle(this.element.querySelector('.subtotal-column').querySelectorAll('.supply-type-variation-line-subtotal')[colummnIndex]);
    // Supplier Supply Type Variation Handle
    const supplyTypeVariation = event.target.form.dataset.supplyTypeVariation;
    const supplierSupplyTypeVariationSelector = `span.supplier-supply-type-variation-subtotal[data-supply-type-variation="${supplyTypeVariation}"]`;
    const supplierTypeVariationHandle = nearestHandle(supplierColumn.querySelector(supplierSupplyTypeVariationSelector));
    // Supply Type Variation Handle
    const supplyTypeVariationSelector = `span.supply-type-variation-subtotal[data-supply-type-variation="${supplyTypeVariation}"]`;
    const supplyTypeVariationHandle = nearestHandle(this.element.querySelector(supplyTypeVariationSelector));
    // Supply Type Handle
    const supplyType = event.target.form.dataset.supplyType;
    const supplyTypeSelector = `span.supply-type-subtotal[data-supply-type="${supplyType}"]`;
    const supplyTypeHandle = nearestHandle(this.element.querySelector(supplyTypeSelector));
    // Toggle handle bg class
    [inputHandle, lineSubtotalHandle, supplierTypeVariationHandle, supplyTypeHandle, supplyTypeVariationHandle].forEach((element) => {
      element.classList.add('bg-success');
    });
  }

  selectText(event) {
    event.target.select();
  }

  priceTargetConnected(element) {
    this.priceInputs ??= [];
    this.priceInputs.push(element);
  }

  priceTargetDisconnected(element) {
    this.priceInputs = this.priceInputs.filter(priceInput => priceInput !== element);
  }

  priceToggle() {
    this.priceInputs.forEach(priceInput => {
      priceInput.classList.toggle('d-none');
    });
  }
}