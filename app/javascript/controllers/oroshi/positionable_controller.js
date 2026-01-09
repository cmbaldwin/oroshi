import { Controller } from "@hotwired/stimulus";
import "muuri";

export default class extends Controller {
  static targets = ['positionableItem'];

  connect() {
    this.positionableGridItems = this.element.querySelectorAll('.positionable-item')
    this.initMuuri()
    this.refresher()
  }

  disconnect() {
    if (this.grid) {
      this.grid.destroy()
    }
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  initMuuri() {
    if (this.positionableGridItems.length === 0 || this.grid) return

    this.grid = new Muuri(this.element, this.getMuuriConfig())
    this.setupGrid()
  }

  getMuuriConfig() {
    return {
      item: '.positionable-item',
      sortData: {
        position: (_item, element) => parseFloat(element.getAttribute('data-position'))
      },
      dragEnabled: true,
      dragSort: true
    }
  }

  setupGrid() {
    this.grid.refreshSortData()
    this.grid.sort('position')
    this.grid.on('dragEnd', () => this.handleDragEnd())
  }

  handleDragEnd() {
    const items = this.grid.getItems()
    items.forEach((item, index) => this.updateItemPosition(item, index))
    this.postPositionUpdate(items)
  }

  postPositionUpdate(items) {
    const new_positions = items.map((item, index) => ({
      id: item.getElement().getAttribute('data-id'),
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
  }

  updateItemPosition(item, index) {
    const element = item.getElement()
    const newPosition = index + 1

    element.setAttribute('data-position', newPosition)
    element.querySelector('.position-field').value = newPosition

    this.updateItemStyles(element, index)
  }

  updateItemStyles(element, index) {
    element.classList.remove('rounded-top', 'rounded-bottom')
    element.classList.add('rounded-bottom-0', 'rounded-top-0')

    if (index === 0) {
      element.classList.add('rounded-top')
      element.classList.remove('rounded-top-0')
    }
  }

  disconnect() {
    if (this.grid) {
      this.grid.destroy();
      this.grid = null;
    }
  }

  // when orderGridSubItem target is connected or disconnected, update masonry layout
  positionableItemConnected() {
    this.refreshGrid();
  }

  positionableItemDisconnected() {
    this.refreshGrid();
  }

  refresher() {
    this.observer = new MutationObserver(this.handleMutations.bind(this))
    this.observer.observe(this.element, this.getObserverConfig())
  }

  handleMutations(mutationsList) {
    try {
      const hasRelevantMutation = mutationsList.some(
        mutation => ['childList', 'attributes'].includes(mutation.type)
      )

      if (hasRelevantMutation) {
        this.refreshGrid()
      }
    } catch (error) {
      console.error('Error handling mutations:', error)
    }
  }

  getObserverConfig() {
    return {
      attributes: true,
      childList: true,
      subtree: true
    }
  }

  refreshGrid() {
    if (this.grid) {
      this.grid.refreshItems().layout();
    }
  }
}