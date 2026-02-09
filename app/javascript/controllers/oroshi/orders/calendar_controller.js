import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static calendar;
  static targets = ['calendar'];
  static values = { eventsUrl: String };

  // Get the engine mount path from the body data attribute
  get mountPath() {
    return document.body.dataset.oroshiMountPath || '';
  }

  // Helper to construct full paths with mount prefix
  enginePath(path) {
    const mount = this.mountPath;
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    return mount ? `${mount}${cleanPath}` : cleanPath;
  }

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    this.orderModal = document.getElementById('orderModal');
    const controllerInstance = this;
    this.calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      events: this.eventsUrlValue,
      eventClick: function (info) { controllerInstance.onEventClick(info) },
      selectable: false,
      dateClick: function (info) { controllerInstance.onDateClick(info) },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    this.calendar.render();

    // Listen for dialog show event
    const dialog = this.orderDialog();
    if (dialog) {
      dialog.addEventListener('toggle', () => {
        if (dialog.open) {
          this.calendar.updateSize();
        }
      });
    }
  }

  settings(_controllerInstance) {
    return {
      locale: 'ja',
      aspectRatio: 1.78, // 16:9
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear',
        center: '',
        right: 'title'
      },
      progressiveEventRendering: true,
      dayMaxEventRows: true, // for all non-TimeGrid views
      moreLinkClassNames: 'text-center w-100',
      eventOrder: ['order', 'title'],
      moreLinkContent: function (args) {
        return `${args.num}注文を表示`;
      }
    }
  }

  onEventClick(info) {
    this.closeModal();
    window.location.href = info.event.url;
  }

  onDateClick(info) {
    this.closeModal();
    let url = new URL(window.location.origin);
    url.pathname = this.enginePath(`/orders/${info.dateStr}`);
    window.location.href = url.href;
  }

  orderDialog() {
    return this.orderModal?.querySelector("dialog[data-oroshi--orders--order-dialog-target='dialog']") ||
      this.orderModal?.querySelector("dialog[data-dialog-target='dialog']");
  }

  closeModal() {
    const dialog = this.orderDialog();
    if (dialog && dialog.open) {
      dialog.close();
    }
  }

  onLoading(loading) {
    if (loading) {
      document.getElementById('order_calendar').insertAdjacentHTML('afterbegin', window.loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

  refreshCalendarPage() {
    this.calendar.refetchEvents();
    // No need to remove backdrop - native dialog elements don't use Bootstrap backdrop
  }

}
