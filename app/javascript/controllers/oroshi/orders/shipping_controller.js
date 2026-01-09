import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['shippingOrganizationCard'];

  connect() {
  }

  toggleNoOrders(event) {
    // event target is a select with a id, get that id and store it in a var
    const buyerCategoryId = event.target.value;
    // find the shippingOrganizationCard with the same data-shipping-organization-id as this event target element
    const shippingOrganizationCard = this.shippingOrganizationCardTargets.find((card) => card.dataset.shippingOrganization === event.target.dataset.shippingOrganization);
    // find all the .no-orders-buyer within that card and toggle d-none on them
    console.log(buyerCategoryId, shippingOrganizationCard);
    const noOrderBuyers = shippingOrganizationCard.querySelectorAll('.no-orders-buyer')

    if (buyerCategoryId === "") {
      // if the buyerCategoryId is empty, make sure all the noOrderBuyers are hidden
      noOrderBuyers.forEach((noOrdersBuyer) => {
        noOrdersBuyer.classList.add('d-none');
      });
    } else if (buyerCategoryId === "0") {
      // if the buyerCategoryId is 0, make sure all the noOrderBuyers are shown
      noOrderBuyers.forEach((noOrdersBuyer) => {
        noOrdersBuyer.classList.remove('d-none');
      });
    } else {
      // if the buyerCategoryId is not empty or 0, show noOrderBuyers with the same data-buyer-category-ids inclues the buyerCategoryId
      // ids are added like, data-buyer-category-ids="<%= buyer.buyer_category_ids.join(',') %>"
      noOrderBuyers.forEach((noOrdersBuyer) => {
        if (noOrdersBuyer.dataset.buyerCategoryIds.split(',').includes(buyerCategoryId)) {
          noOrdersBuyer.classList.remove('d-none');
        } else {
          noOrdersBuyer.classList.add('d-none');
        }
      });
    }
  }

}
