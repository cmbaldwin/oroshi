import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

// Loading overlay HTML - defined locally to avoid module loading order issues
const LOADING_OVERLAY = `
<div class="loading_overlay rounded">
  <div class="spinner-border text-primary position-absolute top-50 start-50" role="status">
    <span class="visually-hidden">読み込み中...</span>
  </div>
</div>
`;

export default class extends Controller {
  static calendar;
  static targets = ['calendar', 'dateChangeForm',
    'startDate', 'endDate', 'supplyDates', 'modalBody',
    'selectedSupplyDates', 'modalChangeDateSubmitButton'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    this.calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      datesSet: function (info) { controllerInstance.onDatesSet(info) },
      events: 'supplies.json',
      eventClick: function (info) { controllerInstance.onEventClick(info) },
      selectable: true,
      dateClick: function (info) { controllerInstance.onDateClick(info) },
      select: function (info) { controllerInstance.onSelect(info) },
      unselect: function (info) { controllerInstance.onDeselect(info) },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    this.calendar.render();

    // Listen for modal close to refresh calendar
    this.boundOnModalClose = this.onModalClose.bind(this);
    document.addEventListener('modal:close', this.boundOnModalClose);

    // Listen for turbo frame load to open the dialog
    this.boundOnFrameLoad = this.onFrameLoad.bind(this);
    document.addEventListener('turbo:frame-load', this.boundOnFrameLoad);
  }

  onModalClose() {
    // Refresh calendar data when modal closes
    this.calendar.refetchEvents();
  }

  onFrameLoad(event) {
    // Open the dialog when the supply_modal_content frame finishes loading
    if (event.target.id === 'supply_modal_content') {
      const dialog = document.querySelector('dialog[data-oroshi--supplies--dialog-target="dialog"]');
      if (dialog && !dialog.open) {
        dialog.showModal();
      }
    }
  }

  disconnect() {
    this.calendar.destroy();
    this.calendarTarget.innerHTML = '';
    document.removeEventListener('modal:close', this.boundOnModalClose);
    document.removeEventListener('turbo:frame-load', this.boundOnFrameLoad);
  }

  settings(controllerInstance) {
    return {
      locale: 'ja',
      aspectRatio: 1.78, // 16:9
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear,reload shikiriList shikiriNew tankaEntry',
        center: '',
        right: 'title'
      },
      customButtons: this.customButtons(controllerInstance),
      progressiveEventRendering: true,
      dayMaxEventRows: true, // for all non-TimeGrid views
      moreLinkClassNames: 'text-center w-100',
      eventOrder: ['order', 'title'],
      moreLinkContent: function (args) {
        return `${args.num}供給件を表示`;
      }
    }
  }

  onDatesSet(info) {
    const startDate = moment(info.startStr).startOf('month').format('YYYY-MM-DD');
    const endDate = moment(info.endStr).endOf('month').format('YYYY-MM-DD');
    this.calendarTarget.dataset.startDate = startDate;
    this.calendarTarget.dataset.endDate = endDate;
  }

  customButtons(controllerInstance) {
    return {
      reload: {
        icon: 'arrow-clockwise',
        click: function () {
          controllerInstance.refreshCalendarPage();
        },
        hint: 'カレンダーを更新します。'
      },
      shikiriList: {
        text: '仕切り表',
        click: function () {
          Turbo.visit('/oroshi/invoices', { frame: 'app ', action: 'advance' })
        },
        hint: 'すべとの仕切りを表示します。'
      },
      shikiriNew: {
        text: '仕切り作成',
        click: function () {
          controllerInstance.requestAction(controllerInstance, 'supply_invoice_actions');
        },
        hint: '現在選択してある日付範囲で新しい仕切りを作成します。'
      },
      tankaEntry: {
        text: '単価入力',
        click: function () {
          controllerInstance.requestAction(controllerInstance, 'supply_price_actions');
        },
        hint: '現在選択してある日付範囲で各産地の生産者の単価を入力します。'
      },
      // analysis: {
      //   text: 'データ分析',
      //   click: function () {
      //     controllerInstance.requestAction(controllerInstance, 'supply_stats_partial');
      //   },
      //   hint: '現在選択してある日付範囲データを分析します。'
      // }
    }
  }

  requestAction = (_controllerInstance, path) => {
    const startDate = new Date(document.getElementById('supply_calendar').dataset.startDate);
    const endDate = new Date(document.getElementById('supply_calendar').dataset.endDate);

    // Create an array of dates
    const supplyDates = [];
    for (let date = startDate; date <= endDate; date.setDate(date.getDate() + 1)) {
      supplyDates.push(date.toISOString().split('T')[0]);
    }

    // Convert the array of dates to a query string
    const queryString = supplyDates.map(date => `supply_dates[]=${date}`).join('&');

    // Use Turbo to load content into the supply_modal_content frame
    // The dialog will open automatically via the onFrameLoad listener
    const url = `supply_dates/${path}?${queryString}`;
    Turbo.visit(url, { frame: "supply_modal_content" });
  }

  onEventClick(info) {
    //disable default
    info.jsEvent.preventDefault();
    switch (info.event.extendedProps.type) {
      case 'invoice':
        // Use Turbo to open the invoice edit modal
        Turbo.visit(`/oroshi/invoices/${info.event.id}/edit`, { frame: "modal" });
        break;
      default:
        this.onDateClick(info);
        break;
    }
  }

  onDateClick(info) {
    if (info?.event?.url) return Turbo.visit(info.event.url, { frame: 'app', action: 'advance' })

    const new_date = moment(info.date).format('YYYY-MM-DD');
    const url = `/oroshi/supply_dates/${encodeURI(new_date)}`;
    Turbo.visit(url, { frame: 'app', action: 'advance' })
  }

  onSelect(info) {
    const start_date = info.startStr;
    let end_date = moment(info.endStr).subtract(1, 'days').format('YYYY-MM-DD');
    const difference = moment(end_date).diff(moment(start_date), "hours");
    if (difference > 24) {
      this.calendarTarget.dataset.startDate = start_date;
      this.calendarTarget.dataset.endDate = end_date;
    }
  }

  onDeselect(info) {
    const button_list = ['shikiriList', 'fc-shikiriNew-button', 'fc-tankaEntry-button', 'fc-analysis-button'];
    const targetClass = info.jsEvent.target.classList;
    // if target class list includes any item from this list do nothing
    if (button_list.some((button) => targetClass.contains(button))) {
      return;
    } else {
      delete this.calendarTarget.dataset.startDate;
      delete this.calendarTarget.dataset.endDate;
    }
  }

  onLoading(loading) {
    if (loading) {
      document.getElementById('supply_calendar').insertAdjacentHTML('afterbegin', LOADING_OVERLAY);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

  refreshCalendarPage() {
    this.calendar.refetchEvents();
  }

  dateChangeFormTargetConnected() {
    this.startDateTarget.addEventListener("change", this.updateSupplyDates.bind(this));
    this.endDateTarget.addEventListener("change", this.updateSupplyDates.bind(this));
  }

  dateChangeFormTargetDisconnected() {
    this.startDateTarget.removeEventListener("change", this.updateSupplyDates.bind(this));
    this.endDateTarget.removeEventListener("change", this.updateSupplyDates.bind(this));
  }

  updateSupplyDates() {
    const startDate = moment(this.startDateTarget.value);
    const endDate = moment(this.endDateTarget.value);
    const initStartDate = moment(this.startDateTarget.dataset.initDate);
    const initEndDate = moment(this.endDateTarget.dataset.initDate);

    if (startDate.isValid() && endDate.isValid() && startDate.isBefore(endDate)) {
      let dates = [];
      let currentDate = startDate.clone();

      while (currentDate.isSameOrBefore(endDate)) {
        dates.push(currentDate.format("YYYY-MM-DD"));
        currentDate.add(1, "day");
      }

      this.supplyDatesTarget.value = dates.join(",");

      // Check if the dates are different from the initial dates
      if (!startDate.isSame(initStartDate) || !endDate.isSame(initEndDate)) {
        this.modalBodyTarget.classList.add('d-none');
        this.selectedSupplyDatesTarget.classList.add('d-none');
        this.modalChangeDateSubmitButtonTarget.disabled = false;
      } else {
        this.modalBodyTarget.classList.remove('d-none');
        this.selectedSupplyDatesTarget.classList.remove('d-none');
        this.modalChangeDateSubmitButtonTarget.disabled = true;
      }
    }
  }

  modalChangeDates(submitEvent) {
    this.modalBodyTarget.innerHTML = `
      <div class="w-100 text-center">
        <div class="spinner-border spinner-border-sm" role="status">
          <span class="visually-hidden">読み込み中...</span>
        </div>
      </div>`;

    const startDate = new Date(this.startDateTarget.value);
    const endDate = new Date(this.endDateTarget.value);

    // Create an array of dates
    const supplyDates = [];
    for (let date = startDate; date <= endDate; date.setDate(date.getDate() + 1)) {
      supplyDates.push(date.toISOString().split('T')[0]);
    }

    // Convert the array of dates to a query string
    const queryString = supplyDates.map(date => `supply_dates[]=${date}`).join('&');

    //find url from the form
    const url = submitEvent.target.action;

    fetch(`${url}?${queryString}`,
      {
        method: "GET",
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin",
      })
      .then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
      .then(() => {
        // update the initDate dataset on this.startDateTarget and this.endDateTarget
        this.startDateTarget.dataset.initDate = this.startDateTarget.value;
        this.endDateTarget.dataset.initDate = this.endDateTarget.value;
      })
  }

}
