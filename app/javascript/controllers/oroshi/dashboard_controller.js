import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['modal', 'supplier', 'supplyTypeVariation'];

  connect() {
    const dialog = this.modalTarget?.querySelector('dialog[data-dialog-target="dialog"]');
    if (dialog) {
      dialog.addEventListener('close', () => {
        const turboFrame = this.modalTarget.querySelector('turbo-frame#oroshi_modal_content');
        if (turboFrame) {
          turboFrame.innerHTML = window.loading_overlay;
        }
      });
    }
  }

  onTabClick(event) {
    const clickedLink = event.currentTarget;
    const nav = clickedLink.closest('.nav');

    // Remove active from all siblings
    nav.querySelectorAll('.nav-link').forEach(link => {
      link.classList.remove('active');
      link.setAttribute('aria-selected', 'false');
    });

    // Add active to clicked
    clickedLink.classList.add('active');
    clickedLink.setAttribute('aria-selected', 'true');
  }

  checkToggle(event) {
    const checkboxes = event.target.parentElement.querySelectorAll('.form-check-input');
    checkboxes.forEach((checkbox) => {
      checkbox.checked = !checkbox.checked;
    });
  }

  showModal(_event) {
    const dialog = this.modalTarget?.querySelector('dialog[data-dialog-target="dialog"]');
    if (dialog) {
      dialog.showModal();
    }
  }

  toggleActive(event) {
    // find the nearest parent turbo-frame
    const checkbox = event.target;
    const frame = checkbox.closest('turbo-frame');
    // if the event.target is checked then remove list-group-item-light opacity-50 else add it
    if (checkbox.checked) {
      frame.classList.remove('list-group-item-light', 'opacity-50');
    } else {
      frame.classList.add('list-group-item-light', 'opacity-50');
    }
    // check the dataset refresh_targets for any turbo-frames to reload (sepereated by spaces)
    const refreshTargets = checkbox.dataset.refreshTargets.split(' ');
    // reload each turbo-frame
    setTimeout(() => {
      refreshTargets.forEach((target) => {
        const frame = document.querySelector(`turbo-frame#${target}`);
        frame.reload();
      });
    }, 500);
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

  toggleShowInactive(event) {
    const targetFrame = event.target.dataset.target
    const frame = document.querySelector(`turbo-frame#${targetFrame}`);
    frame.insertAdjacentHTML('afterbegin', loading_overlay);
    // check if it has show_inactive param, if so remove it
    const url = new URL(frame.src);
    const params = new URLSearchParams(url.search);
    if (params.has('show_inactive')) {
      params.delete('show_inactive');
      url.search = params.toString();
      frame.src = url.toString();
      frame.reload();
    } else {
      // reload the turbo frame but add the param: show_inactive=true
      params.set('show_inactive', 'true');
      url.search = params.toString();
      frame.src = url.toString();
      frame.reload();
    }
  }

  modalFormSubmit(event) {
    // submit the form referenced by the event target, via fetch
    const form = event.target;
    const dialog = this.modalTarget?.querySelector('dialog[data-dialog-target="dialog"]');
    const url = form.action;
    const method = form.method;
    const refreshTarget = form.dataset.refreshTarget
    const formData = new FormData(form);
    fetch(url, {
      method: method,
      body: formData
    })
      .then(response => {
        if (response.ok) {
          if (dialog) {
            dialog.close();
          }
          const frame = document.querySelector(`turbo-frame#${refreshTarget}`);
          frame.reload();
        } else {
          return response.text();
        }
      })
      .then(html => {
        if (html) {
          this.modalTarget.querySelector('turbo-frame#oroshi_modal_content .modal-body').innerHTML = html;
        }
      });
  }

  onCompanySettingChange(event) {
    Turbo.navigator.submitForm(event.target.form);
  }

  updateImage(event) {
    // get the target turbo-frame from the event
    const select = event.target;
    const targetImageFrameId = select.dataset.target;
    // get the turbo-frame
    const turboFrame = document.querySelector(`turbo-frame#${targetImageFrameId}`);
    // replace the id in the url with the selected option id from the event
    if (turboFrame && turboFrame.src) {
      turboFrame.src = turboFrame.src.replace(/(\d+)(?!.*\d)/, select.value);
      turboFrame.reload();
    }
  }

  updateImages(event) {
    const input = event.target;
    const parentInputGroup = input.closest('.input-group');
    const targetImageFrameId = input.dataset.target;
    const prefix = targetImageFrameId.split('_')[0];
    const turboFrame = document.querySelector(`turbo-frame#${targetImageFrameId}`);
    // Select all checked checkboxes within the target
    const checkedCheckboxes = parentInputGroup.querySelectorAll(`input:checked`);
    // Map the values of the checked checkboxes to an array
    const selectedIds = Array.from(checkedCheckboxes).map(checkbox => checkbox.value);
    // Create the query string
    const queryString = selectedIds.map(id => `${prefix}_ids%5B%5D=${id}`).join('&');
    // Update the turbo frame src and reload
    turboFrame.src = `${turboFrame.src.split('?')[0]}?${queryString}`;
    turboFrame.reload();
  }

  updateSubregions(event) {
    const countryId = event.target.value
    //get parent closest .country-subregion-select
    const parentDiv = event.target.closest('.country-subregion-select')
    // find the '.subregion select' within the parentDiv
    const subregionSelect = parentDiv.querySelector('.subregion-select select')
    fetch(`oroshi/dashboard/subregions?country_id=${countryId}`)
      .then(response => response.json())
      .then(data => {
        subregionSelect.innerHTML = data.subregions.map(subregion =>
          `<option value="${subregion.code}">${subregion.name}</option>`
        ).join('')
      })
  }

  reloadTabContent(event) {
    const link = event.target;
    const frame_id = link.dataset.reloadTarget;
    const dashboardFrame = this.element.querySelector(`turbo-frame#${frame_id}`);
    dashboardFrame.reload();
  }
}
