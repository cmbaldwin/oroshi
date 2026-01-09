import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['paymentReceiptBuyerHeader', 'adjustments', 'adjustment', 'orderSelectDatePicker', 'buyerSelect', 'orderIdsSelect', 'total', 'adjustmentAmount', 'depositTotal'];

  connect() {
  }

  disconnect() {
  }

  adjustmentAmountTargetConnected(event) {
    this.formatValue(event.target);
  }

  totalTargetConnected(event) {
    this.formatValue(event.target);
  }

  depositTotalTargetConnected(event) {
    this.formatValue(event.target);
  }

  formatValue(target) {
    if (target && target.value) {
      target.value = parseFloat(target.value).toFixed(2);
    }
  }

  filterOrdersByEndDate(event) {
    const date = event.target.dataset.date;
    const orderIdsSelect = this.orderIdsSelectTarget;
    const selectOptions = orderIdsSelect.querySelectorAll('option');
    selectOptions.forEach((option) => {
      option.selected = false;
      const optionDate = option.text.match(/\d{4}-\d{2}-\d{2}/)[0];
      if (optionDate <= date) {
        option.selected = true;
      }
    });
  }

  toggleActiveLink(event) {
    // if event element has a dat-turbo-frame target, fill that frame with a loading spinner before proceeding
    const turboFrame = event.target.dataset.turboFrame;
    if (turboFrame) {
      const frame = document.querySelector(`turbo-frame#${turboFrame}`);
      frame.innerHTML = this.spinnerHtml();
    }
    // find closest .nav
    const nav = event.target.closest('.nav');
    // find all .nav-link
    const navLinks = nav.querySelectorAll('.nav-link');
    // remove active class from all .nav-link
    navLinks.forEach((link) => {
      link.classList.remove('active');
    });
    // add active class to clicked link
    event.target.closest('.nav-link').classList.add('active');
  }

  toggleActiveListItem(event) {
    // set event target to later add active class
    let target = event.target;
    // if the target isn't a list-group-item, find the closest list-group-item
    if (!target.classList.contains('list-group-item')) {
      target = target.closest('.list-group-item');
    }
    // find parent list-group for this even target list-group-item
    const listGroup = target.closest('.list-group');
    // remove all active classes from list-group-items within the list-group and data-active attributes
    listGroup.querySelectorAll('.list-group-item').forEach((element) => {
      element.classList.remove('active');
      element.dataset.active = "false";
    });
    // add active class to event target list-group-item and set data-active to true
    target.classList.add('active');
    target.dataset.active = "true";
  }

  spinnerHtml() {
    return `
      <div class="d-flex justify-content-center">
        <div class="spinner-border" role="status">
          <span class="visually-hidden">読み込み中...</span>
        </div>
      </div>
    `
  }

  addAdjustment(event) {
    event.preventDefault();
    const link = event.target;
    const id = new Date().getTime();
    const regexp = new RegExp(link.dataset.id, 'g');
    const newFields = link.dataset.fields.replace(regexp, id);
    const adjustmentsContainer = this.adjustmentsTarget.querySelector('.adjustments');
    if (adjustmentsContainer) {
      adjustmentsContainer.insertAdjacentHTML('beforeend', newFields);
    }
  }

  removeAdjustment(event) {
    event.preventDefault();
    if (this.adjustmentTargets.length > 0) {
      const lastAdjustment = this.adjustmentTargets[this.adjustmentTargets.length - 1];
      lastAdjustment.remove();
    }
  }

  depositChange(_event) {
    // take all :amount from adjustment tagets and subtract them from 'total' target to get the 'deposit_total', and put it at that target
    let deposit = this.totalTarget.value;
    this.adjustmentAmountTargets.forEach((adjustmentAmount) => {
      const amount = adjustmentAmount.value;
      deposit -= parseFloat(amount);
    });
    this.depositTotalTarget.value = deposit;
  }


  setBuyerOutstandingPaymentOrders(event) {
    // get buyer id from this.buyerSelectTarget selected option
    const buyerId = this.buyerSelectTarget.selectedOptions[0].value;
    if (!buyerId) { return }

    this.loading(true);
    // get the buyer outstanding payment orders from the endpoint
    fetch(`/oroshi/buyers/${buyerId}/outstanding_payment_orders`)
      .then(response => response.json())
      // for each order, create an option and reset and append it to this.orderIdsSelectTarget
      .then(data => {
        const optionsSelect = this.orderIdsSelectTarget;
        // remove any existing options
        optionsSelect.innerHTML = '';
        // from `render json: { orders: orders.map { |order| [order.id, order.to_s] } }`
        data.orders.forEach(order => {
          const option = document.createElement('option');
          option.value = order[0];
          option.text = order[1];
          optionsSelect.appendChild(option);
        });
        this.loading(false);
      })
      .catch(error => {
        console.error('Error:', error);
        this.loading(false);
      });
  }

  updateBuyerColor(event) {
    // find the dataset.color of the currently selected option
    const buyerColor = event.target.selectedOptions[0].dataset.color;
    const buyerName = event.target.selectedOptions[0].text;
    // if there is no color, reset to #808080
    const color = buyerColor ? buyerColor : '#808080';
    // within the container is a .color-circle, set its background color to the color
    this.paymentReceiptBuyerHeaderTarget
      .querySelector('.color-circle').style.backgroundColor = color;
    this.paymentReceiptBuyerHeaderTarget.querySelector('.buyer-name').textContent = buyerName;
    this.paymentReceiptBuyerHeaderTarget.classList.remove('d-none');
  }

  loading(loading) {
    if (loading) {
      this.element.insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      this.element.querySelector('.loading_overlay')?.remove();
    }
  }

}