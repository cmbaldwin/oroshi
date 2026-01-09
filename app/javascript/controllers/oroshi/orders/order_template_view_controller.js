import { Controller } from "@hotwired/stimulus";
import "muuri";

export default class extends Controller {
  static targets = ['orderGridSubItem'];

  connect() {
    this.orderGridItems = this.element.querySelectorAll('.order-grid-item');
    this.initMuuri();
    this.refresher();
  }

  initMuuri() {
    if (this.orderGridItems.length === 0) return;

    // Setup
    this.grid = new Muuri(this.element, {
      item: '.order-grid-item',
      sortData: {
        position: function (_item, element) {
          return parseFloat(element.getAttribute('data-position'));
        },
      },
      dragEnabled: true,
      dragHandle: '.handle',
      dragSort: true,
    });

    // Sort
    this.grid.refreshSortData();
    this.grid.sort('position');

    // On Drag
    this.grid.on('dragEnd', (_item, _event) => {
      // change the data-position to be in the new order, 
      // so each data - position should be it's index in the order array
      // update the text in .position-display for that element as well
      const items = this.grid.getItems();
      items.forEach((item, index) => {
        item.getElement().setAttribute('data-position', index);
        item.getElement().querySelector('.position-display').textContent = index + 1;
      });
      // each element also has a data-product-id. send an ajax request to update the order of the products
      const new_positions = items.map((item, index) => ({
        product_id: item.getElement().getAttribute('data-product-id'),
        position: index
      }));
      const url = this.element.getAttribute('data-position-update-url');
      fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        },
        body: JSON.stringify({ new_positions }),
      });
    });
  }

  disconnect() {
    if (this.grid) {
      this.grid.destroy();
    }
  }

  // when orderGridSubItem target is connected or disconnected, update masonry layout
  orderGridSubItemConnected() {
    this.refreshGrid();
  }

  orderGridSubItemDisconnected() {
    this.refreshGrid();
  }

  refresher() {
    // Create a MutationObserver to watch for changes in this.element
    this.observer = new MutationObserver((mutationsList) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'childList' || mutation.type === 'attributes') {
          this.refreshGrid();
        }
      }
    });

    // Start observing this.element for configured mutations
    this.observer.observe(this.element, {
      attributes: true,
      childList: true,
      subtree: true
    });

    // Initial refresh to ensure grid is correctly laid out
    this.refreshGrid();
  }

  refreshGrid() {
    if (this.grid) {
      this.grid.refreshItems().layout();
    }
  }
}
